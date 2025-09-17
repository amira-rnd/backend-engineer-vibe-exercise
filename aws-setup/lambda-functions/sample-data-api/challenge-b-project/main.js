// Lambda Handler (main.js)
const { RequestProcessor } = require('./lib/request-processor');
const { MetricsCollector } = require('./lib/metrics-collector');
const { ValidationMiddleware } = require('./lib/validation-middleware');

// Singleton instances for performance
let processor = new RequestProcessor();
let metrics = new MetricsCollector();
let validator = new ValidationMiddleware();

exports.handler = async (event) => {
    const requestId = `req-${Date.now()}-${Math.random()}`;

    try {
        metrics.startRequest(requestId, event);
        const validatedData = await validator.validateRequest(event.arguments);
        const result = await processor.processRequest(requestId, validatedData, event.requestContext);
        metrics.recordSuccess(requestId, result);
        return result;
    } catch (error) {
        metrics.recordError(requestId, error);
        console.error('Request failed:', error);
        throw error;
    }
};