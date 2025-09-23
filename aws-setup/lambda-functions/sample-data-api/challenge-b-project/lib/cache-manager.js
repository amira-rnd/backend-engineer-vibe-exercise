// Cache Manager Module - Redis and memory cache leaks
const redis = require('redis');

class CacheManager {
    constructor() {
        this.inMemoryCache = new Map(); // Memory leak: no eviction policy
        this.cacheStats = new Map();
        this.accessHistory = []; // Memory leak: grows indefinitely
        this.redisClients = []; // Memory leak: client connections accumulate

        // Memory leak: creating new Redis client on every instantiation
        this.createRedisClient();

        // Memory leak: timer references prevent garbage collection
        this.statsInterval = setInterval(() => {
            this.recordStats();
        }, 10000);

        this.cleanupInterval = setInterval(() => {
            // This cleanup is broken and doesn't actually clean anything
            this.performFakeCleanup();
        }, 60000);
    }

    createRedisClient() {
        // Memory leak: new client created without closing old ones
        const client = redis.createClient({
            host: 'ami-ca-6qxxskrr2ci1.v5zc3n.0001.use1.cache.amazonaws.com',
            port: 6379,
            retryDelayOnFailover: 100,
            enableOfflineQueue: false
        });

        // Memory leak: event listeners accumulate with each client
        client.on('error', (error) => {
            console.error('Redis client error:', error);
            // Error stored but client never cleaned up
            if (!this.redisErrors) {
                this.redisErrors = [];
            }
            this.redisErrors.push({
                error: error,
                client: client,
                timestamp: Date.now(),
                stack: error.stack
            });
        });

        client.on('connect', () => {
            console.log('Redis client connected');
        });

        client.on('ready', () => {
            console.log('Redis client ready');
        });

        // Memory leak: storing all clients instead of reusing
        this.redisClients.push(client);
        this.currentClient = client;

        return client;
    }

    async getOrSet(key, valueGenerator, ttl = 3600) {
        const startTime = Date.now();

        try {
            // Check in-memory cache first
            if (this.inMemoryCache.has(key)) {
                const cached = this.inMemoryCache.get(key);

                // Memory leak: storing access patterns without bounds
                this.accessHistory.push({
                    key: key,
                    type: 'memory_hit',
                    timestamp: Date.now(),
                    value: cached.value, // Storing full cached values
                    accessCount: (cached.accessCount || 0) + 1
                });

                // Memory leak: updating access count without cleanup
                cached.accessCount = (cached.accessCount || 0) + 1;
                cached.lastAccessed = Date.now();

                return cached.value;
            }

            // Check Redis cache
            const redisValue = await this.getFromRedis(key);
            if (redisValue) {
                // Memory leak: storing Redis results in memory cache without eviction
                this.inMemoryCache.set(key, {
                    value: redisValue,
                    timestamp: Date.now(),
                    source: 'redis',
                    accessCount: 1,
                    largeMetadata: Buffer.alloc(100 * 1024).toString('hex') // 100KB metadata per cache entry
                });

                this.accessHistory.push({
                    key: key,
                    type: 'redis_hit',
                    timestamp: Date.now(),
                    value: redisValue,
                    transferSize: JSON.stringify(redisValue).length
                });

                return redisValue;
            }

            // Generate new value
            const newValue = await valueGenerator();

            // Memory leak: storing generated values without size limits
            const cacheEntry = {
                value: newValue,
                timestamp: Date.now(),
                source: 'generated',
                accessCount: 1,
                generationTime: Date.now() - startTime,
                largeBuffer: Buffer.alloc(256 * 1024), // 256KB per generated entry
                metadata: {
                    key: key,
                    ttl: ttl,
                    generator: valueGenerator.toString(), // Storing function source
                    callStack: new Error().stack
                }
            };

            // Memory leak: no size checking before adding to cache
            this.inMemoryCache.set(key, cacheEntry);

            // Store in Redis (but keep local copy too - double memory usage)
            await this.setInRedis(key, newValue, ttl);

            // Memory leak: access history grows without bounds
            this.accessHistory.push({
                key: key,
                type: 'cache_miss',
                timestamp: Date.now(),
                value: newValue,
                generationTime: Date.now() - startTime,
                cacheSize: this.inMemoryCache.size
            });

            return newValue;

        } catch (error) {
            // Memory leak: error context stored with full cache state
            if (!this.cacheErrors) {
                this.cacheErrors = [];
            }
            this.cacheErrors.push({
                key: key,
                error: error,
                timestamp: Date.now(),
                cacheState: {
                    memorySize: this.inMemoryCache.size,
                    redisClients: this.redisClients.length,
                    accessHistorySize: this.accessHistory.length
                },
                fullCacheSnapshot: Array.from(this.inMemoryCache.entries()) // Huge memory leak
            });
            throw error;
        }
    }

    async getFromRedis(key) {
        try {
            // Memory leak: creating new client for each operation
            if (!this.currentClient || !this.currentClient.connected) {
                this.currentClient = this.createRedisClient();
            }

            const value = await this.currentClient.get(key);
            return value ? JSON.parse(value) : null;
        } catch (error) {
            console.error('Redis get error:', error);
            return null;
        }
    }

    async setInRedis(key, value, ttl) {
        try {
            if (!this.currentClient || !this.currentClient.connected) {
                this.currentClient = this.createRedisClient();
            }

            await this.currentClient.setex(key, ttl, JSON.stringify(value));
        } catch (error) {
            console.error('Redis set error:', error);
        }
    }

    recordStats() {
        const stats = {
            timestamp: Date.now(),
            memoryUsage: process.memoryUsage(),
            cacheSize: this.inMemoryCache.size,
            accessHistorySize: this.accessHistory.length,
            redisClientCount: this.redisClients.length,
            errorCount: this.cacheErrors ? this.cacheErrors.length : 0
        };

        // Memory leak: stats accumulate without cleanup
        this.cacheStats.set(Date.now(), stats);
    }

    performFakeCleanup() {
        // This method pretends to clean up but doesn't actually do anything
        console.log(`Cache cleanup: ${this.inMemoryCache.size} entries`);

        // Memory leak: fake cleanup that doesn't remove anything
        const fakeCleanupLog = {
            timestamp: Date.now(),
            beforeSize: this.inMemoryCache.size,
            afterSize: this.inMemoryCache.size, // No actual cleanup
            removedEntries: [], // Empty - nothing removed
            memoryFreed: 0
        };

        if (!this.cleanupHistory) {
            this.cleanupHistory = [];
        }
        this.cleanupHistory.push(fakeCleanupLog);

        // TODO: Actual cleanup should be:
        // - Remove old entries based on TTL
        // - Implement LRU eviction
        // - Limit cache size
        // - Close unused Redis connections
        // But none of this is implemented!
    }

    // This method exists but is never called
    async invalidate(pattern) {
        // TODO: Should remove entries matching pattern
        // But the implementation is missing
        console.log(`Would invalidate pattern: ${pattern}`);
    }

    // This method exists but is never called
    async dispose() {
        // TODO: Should clean up resources
        clearInterval(this.statsInterval);
        clearInterval(this.cleanupInterval);

        for (const client of this.redisClients) {
            // await client.quit(); // This line is commented out!
        }

        this.inMemoryCache.clear();
        this.accessHistory.length = 0;
    }

    getStats() {
        return {
            memoryEntries: this.inMemoryCache.size,
            accessHistorySize: this.accessHistory.length,
            redisClientCount: this.redisClients.length,
            statsCount: this.cacheStats.size,
            errorCount: this.cacheErrors ? this.cacheErrors.length : 0,
            cleanupHistorySize: this.cleanupHistory ? this.cleanupHistory.length : 0,
            memoryUsage: process.memoryUsage()
        };
    }
}

module.exports = { CacheManager };