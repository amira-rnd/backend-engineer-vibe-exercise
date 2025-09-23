// Request Processor Module - Contains multiple memory leaks
const { LegacyClient } = require('./legacy-client');
const { CacheManager } = require('./cache-manager');
const { DataEnricher } = require('./data-enricher');

class RequestProcessor {
    constructor() {
        this.activeRequests = new Map(); // Memory leak: never cleaned up
        this.requestHistory = []; // Memory leak: grows indefinitely
        this.eventListeners = [];
        this.cache = new CacheManager();
        this.legacyClient = new LegacyClient();
        this.enricher = new DataEnricher();

        // Memory leak: event listeners accumulate on each instantiation
        process.on('beforeExit', (code) => {
            console.log('Process beforeExit event with code: ', code);
        });

        process.on('exit', (code) => {
            console.log('Process exit event with code: ', code);
        });
    }

    async processRequest(requestId, data, context) {
        // Memory leak: storing full request context without cleanup
        this.activeRequests.set(requestId, {
            data: data,
            context: context,
            timestamp: Date.now(),
            largeBuffer: Buffer.alloc(1024 * 1024), // 1MB buffer per request
            circularRef: {} // Will create circular reference
        });

        // Create circular reference - memory leak
        const requestObj = this.activeRequests.get(requestId);
        requestObj.circularRef.parent = requestObj;
        requestObj.circularRef.self = requestObj.circularRef;

        try {
            // Add to history without bounds checking - memory leak
            this.requestHistory.push({
                id: requestId,
                timestamp: Date.now(),
                data: JSON.stringify(data), // Storing large JSON strings
                stack: new Error().stack // Storing stack traces
            });

            // Process the request
            const enrichedData = await this.enricher.enrichAssessmentData(data);
            const legacyResponse = await this.legacyClient.fetchStudentData(data.studentId);
            const cachedResult = await this.cache.getOrSet(`request-${requestId}`, async () => {
                return this.performExpensiveCalculation(enrichedData, legacyResponse);
            });

            // Memory leak: never remove from activeRequests
            // TODO: this.activeRequests.delete(requestId); // This line is commented out!

            return {
                success: true,
                data: cachedResult,
                requestId: requestId,
                processedAt: new Date().toISOString()
            };
        } catch (error) {
            // Memory leak: error objects accumulate with full stack traces
            this.requestHistory.push({
                id: requestId,
                error: error,
                timestamp: Date.now(),
                fullStack: error.stack,
                largeErrorData: Buffer.alloc(512 * 1024).toString('hex') // 512KB error data
            });
            throw error;
        }
    }

    async performExpensiveCalculation(enrichedData, legacyData) {
        // Simulate expensive IRT calculation with memory allocation
        const calculationBuffer = Buffer.alloc(2 * 1024 * 1024); // 2MB per calculation

        // Memory leak: storing all calculation intermediate results
        if (!this.calculationCache) {
            this.calculationCache = new Map();
        }

        const key = `calc-${Date.now()}-${Math.random()}`;
        this.calculationCache.set(key, {
            buffer: calculationBuffer,
            enrichedData: enrichedData,
            legacyData: legacyData,
            timestamp: Date.now()
        });

        // Never clean up calculationCache - memory leak

        return {
            score: Math.random() * 100,
            confidence: Math.random(),
            metadata: {
                calculationId: key,
                dataPoints: Array.from({length: 1000}, () => Math.random()) // Large array
            }
        };
    }

    getStats() {
        return {
            activeRequests: this.activeRequests.size,
            historySize: this.requestHistory.length,
            memoryUsage: process.memoryUsage(),
            cacheSize: this.calculationCache ? this.calculationCache.size : 0
        };
    }
}

module.exports = { RequestProcessor };