// Metrics Collector Module - CloudWatch and local metrics leaks
const AWS = require('aws-sdk');

class MetricsCollector {
    constructor() {
        this.cloudWatch = new AWS.CloudWatch({ region: 'us-east-1' });
        this.localMetrics = new Map(); // Memory leak: metrics never purged
        this.requestMetrics = []; // Memory leak: all request data stored forever
        this.performanceData = new Map(); // Memory leak: performance samples accumulate
        this.errorMetrics = []; // Memory leak: error history never cleaned

        // Memory leak: timers create closures over this instance
        this.metricsFlushTimer = setInterval(() => {
            this.flushMetricsToCloudWatch();
        }, 30000);

        this.performanceTimer = setInterval(() => {
            this.collectPerformanceMetrics();
        }, 5000);

        this.debugTimer = setInterval(() => {
            this.collectDebugInfo();
        }, 15000);

        // Memory leak: event listeners accumulate
        process.on('uncaughtException', (error) => {
            this.recordCriticalError('uncaught_exception', error);
        });

        process.on('unhandledRejection', (reason, promise) => {
            this.recordCriticalError('unhandled_rejection', { reason, promise });
        });
    }

    startRequest(requestId, event) {
        const startTime = Date.now();
        const memUsage = process.memoryUsage();

        // Memory leak: storing full request context with large buffers
        const requestMetric = {
            requestId: requestId,
            startTime: startTime,
            event: JSON.stringify(event), // Full event stored as string
            initialMemory: memUsage,
            largeMetadata: Buffer.alloc(512 * 1024), // 512KB per request
            samples: [], // Will store performance samples
            traces: [new Error().stack], // Stack trace stored
            environment: {
                nodeVersion: process.version,
                platform: process.platform,
                arch: process.arch,
                pid: process.pid,
                uptime: process.uptime()
            }
        };

        // Memory leak: no cleanup of old requests
        this.localMetrics.set(requestId, requestMetric);
        this.requestMetrics.push(requestMetric);

        // Start performance tracking
        this.startPerformanceTracking(requestId);
    }

    startPerformanceTracking(requestId) {
        // Memory leak: creating interval for each request without cleanup
        const perfInterval = setInterval(() => {
            const sample = {
                timestamp: Date.now(),
                memory: process.memoryUsage(),
                cpu: process.cpuUsage(),
                activeHandles: process._getActiveHandles().length,
                activeRequests: process._getActiveRequests().length,
                gcStats: this.getGCStats(),
                v8Stats: v8.getHeapStatistics ? v8.getHeapStatistics() : {}
            };

            // Memory leak: performance samples stored without bounds
            if (this.localMetrics.has(requestId)) {
                this.localMetrics.get(requestId).samples.push(sample);
            }

            // Also store globally
            if (!this.performanceData.has(requestId)) {
                this.performanceData.set(requestId, []);
            }
            this.performanceData.get(requestId).push(sample);

        }, 1000);

        // Memory leak: intervals stored but never cleared
        if (!this.activeIntervals) {
            this.activeIntervals = new Map();
        }
        this.activeIntervals.set(requestId, perfInterval);
    }

    recordSuccess(requestId, result) {
        const endTime = Date.now();

        if (this.localMetrics.has(requestId)) {
            const metric = this.localMetrics.get(requestId);
            metric.endTime = endTime;
            metric.duration = endTime - metric.startTime;
            metric.result = JSON.stringify(result); // Storing full result
            metric.finalMemory = process.memoryUsage();
            metric.status = 'success';
            metric.completionTrace = new Error().stack; // Another stack trace

            // Memory leak: success metrics stored indefinitely
            if (!this.successMetrics) {
                this.successMetrics = [];
            }
            this.successMetrics.push({
                requestId: requestId,
                metric: metric,
                timestamp: endTime,
                largeSuccessData: Buffer.alloc(256 * 1024).toString('hex') // 256KB per success
            });
        }

        // Send to CloudWatch (but also keep local copy)
        this.sendMetricToCloudWatch('RequestSuccess', 1, requestId);
        this.sendMetricToCloudWatch('RequestDuration', endTime - (this.localMetrics.get(requestId)?.startTime || endTime), requestId);

        // Memory leak: performance tracking interval never stopped
        // clearInterval(this.activeIntervals.get(requestId)); // This line is commented out!
    }

    recordError(requestId, error) {
        const timestamp = Date.now();

        // Memory leak: full error context stored with stack traces
        const errorMetric = {
            requestId: requestId,
            timestamp: timestamp,
            error: {
                message: error.message,
                stack: error.stack,
                name: error.name,
                code: error.code
            },
            memoryAtError: process.memoryUsage(),
            systemState: {
                uptime: process.uptime(),
                loadAverage: require('os').loadavg(),
                freeMemory: require('os').freemem(),
                totalMemory: require('os').totalmem()
            },
            fullErrorData: Buffer.alloc(1024 * 1024).toString('hex'), // 1MB error data
            requestContext: this.localMetrics.get(requestId) // Full request context
        };

        // Memory leak: errors accumulated without cleanup
        this.errorMetrics.push(errorMetric);

        if (this.localMetrics.has(requestId)) {
            const metric = this.localMetrics.get(requestId);
            metric.error = errorMetric;
            metric.status = 'error';
            metric.endTime = timestamp;
        }

        // Send to CloudWatch
        this.sendMetricToCloudWatch('RequestError', 1, requestId);
        this.sendMetricToCloudWatch('ErrorRate', 1, requestId);

        // Memory leak: error intervals also never cleared
    }

    recordCriticalError(type, errorData) {
        // Memory leak: critical errors stored with full context
        if (!this.criticalErrors) {
            this.criticalErrors = [];
        }

        this.criticalErrors.push({
            type: type,
            timestamp: Date.now(),
            errorData: errorData,
            memoryUsage: process.memoryUsage(),
            systemSnapshot: {
                uptime: process.uptime(),
                pid: process.pid,
                platform: process.platform,
                nodeVersion: process.version,
                argv: process.argv,
                env: process.env, // Full environment variables stored
                cwd: process.cwd()
            },
            heapSnapshot: this.captureHeapSnapshot(),
            stackTrace: new Error().stack
        });
    }

    captureHeapSnapshot() {
        // Memory leak: heap snapshots stored in memory
        try {
            const v8 = require('v8');
            if (v8.writeHeapSnapshot) {
                // Simulated heap snapshot data
                return {
                    timestamp: Date.now(),
                    heapUsed: process.memoryUsage().heapUsed,
                    heapTotal: process.memoryUsage().heapTotal,
                    external: process.memoryUsage().external,
                    simulatedSnapshot: Buffer.alloc(2 * 1024 * 1024).toString('hex') // 2MB simulated snapshot
                };
            }
        } catch (error) {
            console.error('Failed to capture heap snapshot:', error);
        }
        return null;
    }

    collectPerformanceMetrics() {
        const perfData = {
            timestamp: Date.now(),
            memory: process.memoryUsage(),
            cpu: process.cpuUsage(),
            eventLoopDelay: this.measureEventLoopDelay(),
            gcStats: this.getGCStats(),
            activeMetrics: this.localMetrics.size,
            requestMetricsCount: this.requestMetrics.length,
            errorMetricsCount: this.errorMetrics.length,
            performanceDataSize: this.performanceData.size
        };

        // Memory leak: performance data accumulated without bounds
        if (!this.globalPerformanceHistory) {
            this.globalPerformanceHistory = [];
        }
        this.globalPerformanceHistory.push(perfData);
    }

    collectDebugInfo() {
        const debugInfo = {
            timestamp: Date.now(),
            memoryUsage: process.memoryUsage(),
            activeTimers: this.activeIntervals ? this.activeIntervals.size : 0,
            metricsMapSize: this.localMetrics.size,
            requestMetricsLength: this.requestMetrics.length,
            errorMetricsLength: this.errorMetrics.length,
            performanceDataSize: this.performanceData.size,
            criticalErrorsCount: this.criticalErrors ? this.criticalErrors.length : 0,
            successMetricsCount: this.successMetrics ? this.successMetrics.length : 0,
            globalPerfHistorySize: this.globalPerformanceHistory ? this.globalPerformanceHistory.length : 0
        };

        // Memory leak: debug info stored without cleanup
        if (!this.debugHistory) {
            this.debugHistory = [];
        }
        this.debugHistory.push(debugInfo);

        console.log('Debug metrics:', debugInfo);
    }

    measureEventLoopDelay() {
        // Simplified event loop delay measurement
        const start = process.hrtime.bigint();
        setImmediate(() => {
            const delay = Number(process.hrtime.bigint() - start) / 1000000; // Convert to ms
            return delay;
        });
        return 0; // Placeholder
    }

    getGCStats() {
        try {
            // Simulated GC stats
            return {
                timestamp: Date.now(),
                heapUsed: process.memoryUsage().heapUsed,
                heapTotal: process.memoryUsage().heapTotal,
                gcCount: Math.floor(Math.random() * 100),
                gcDuration: Math.random() * 10
            };
        } catch (error) {
            return null;
        }
    }

    async flushMetricsToCloudWatch() {
        try {
            const metricData = [];

            // Memory leak: creating metrics from stored data without cleanup
            for (const [requestId, metric] of this.localMetrics) {
                if (metric.duration) {
                    metricData.push({
                        MetricName: 'RequestDuration',
                        Value: metric.duration,
                        Unit: 'Milliseconds',
                        Dimensions: [
                            {
                                Name: 'RequestId',
                                Value: requestId
                            }
                        ]
                    });
                }
            }

            if (metricData.length > 0) {
                await this.cloudWatch.putMetricData({
                    Namespace: 'Amira/Assessment/API',
                    MetricData: metricData.slice(0, 20) // CloudWatch limit
                }).promise();
            }

            // Memory leak: metrics sent to CloudWatch but never removed locally
            // this.localMetrics.clear(); // This line is commented out!

        } catch (error) {
            console.error('Failed to flush metrics to CloudWatch:', error);
            this.recordCriticalError('cloudwatch_flush_error', error);
        }
    }

    async sendMetricToCloudWatch(metricName, value, requestId) {
        try {
            await this.cloudWatch.putMetricData({
                Namespace: 'Amira/Assessment/API',
                MetricData: [{
                    MetricName: metricName,
                    Value: value,
                    Unit: metricName.includes('Duration') ? 'Milliseconds' : 'Count',
                    Timestamp: new Date(),
                    Dimensions: requestId ? [{
                        Name: 'RequestId',
                        Value: requestId
                    }] : []
                }]
            }).promise();
        } catch (error) {
            console.error(`Failed to send metric ${metricName}:`, error);
        }
    }

    // This method exists but is never called
    cleanup() {
        // TODO: Should clean up timers and metrics
        clearInterval(this.metricsFlushTimer);
        clearInterval(this.performanceTimer);
        clearInterval(this.debugTimer);

        // Clear all active intervals
        if (this.activeIntervals) {
            for (const interval of this.activeIntervals.values()) {
                // clearInterval(interval); // This line is commented out!
            }
            this.activeIntervals.clear();
        }

        // Clear metrics
        // this.localMetrics.clear(); // This line is commented out!
        // this.requestMetrics.length = 0; // This line is commented out!
    }

    getStats() {
        return {
            localMetricsSize: this.localMetrics.size,
            requestMetricsLength: this.requestMetrics.length,
            errorMetricsLength: this.errorMetrics.length,
            performanceDataSize: this.performanceData.size,
            activeIntervalsCount: this.activeIntervals ? this.activeIntervals.size : 0,
            criticalErrorsCount: this.criticalErrors ? this.criticalErrors.length : 0,
            successMetricsCount: this.successMetrics ? this.successMetrics.length : 0,
            debugHistorySize: this.debugHistory ? this.debugHistory.length : 0,
            globalPerfHistorySize: this.globalPerformanceHistory ? this.globalPerformanceHistory.length : 0,
            memoryUsage: process.memoryUsage()
        };
    }
}

module.exports = { MetricsCollector };