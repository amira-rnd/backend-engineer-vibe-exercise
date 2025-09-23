// Lambda Handler (main.js)
const { RequestProcessor } = require('./lib/request-processor');
const { MetricsCollector } = require('./lib/metrics-collector');
const { LegacyClient } = require('./lib/legacy-client');
const { CacheManager } = require('./lib/cache-manager');
const { DataEnricher } = require('./lib/data-enricher');

// Memory leak: Singleton instances created but never disposed
let processor = new RequestProcessor();
let metrics = new MetricsCollector();
let legacyClient = new LegacyClient();
let cacheManager = new CacheManager();
let dataEnricher = new DataEnricher();

exports.handler = async (event) => {
    const requestId = `req-${Date.now()}-${Math.random()}`;

    try {
        // Memory leak: all modules used but never cleaned up
        metrics.startRequest(requestId, event);

        // Simple validation without middleware
        const requestData = event.arguments || event.body || {};
        if (!requestData.studentId) {
            throw new Error('studentId is required');
        }

        const result = await processor.processRequest(requestId, requestData, event.requestContext);
        metrics.recordSuccess(requestId, result);

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify(result)
        };
    } catch (error) {
        metrics.recordError(requestId, error);
        console.error('Request failed:', error);

        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: error.message,
                requestId: requestId,
                timestamp: new Date().toISOString()
            })
        };
    }

    // Memory leak: handler never calls cleanup methods
    // Missing: processor.dispose(), metrics.cleanup(), etc.
};