// Validation Middleware (validation-middleware.js)
// Memory Leak: Stores all validation results in memory indefinitely

const validationCache = new Map(); // MEMORY LEAK: never cleaned up
const schemaCache = {}; // MEMORY LEAK: grows over time

class ValidationMiddleware {
    constructor() {
        // Memory leak: Creates new validation instances but never disposes them
        this.validators = [];
        this.requestHistory = []; // MEMORY LEAK: keeps all requests forever
    }

    // Memory leak: Adds to cache without cleanup
    validateRequest(requestId, data) {
        const timestamp = Date.now();

        // Store validation result permanently (MEMORY LEAK)
        const validationResult = {
            requestId,
            data,
            timestamp,
            isValid: this.performValidation(data),
            validatorInstance: this.createValidator() // MEMORY LEAK: new instance per request
        };

        validationCache.set(requestId, validationResult);
        this.requestHistory.push(validationResult); // MEMORY LEAK: unbounded array

        console.log(`Validation cache size: ${validationCache.size}`);
        console.log(`Request history length: ${this.requestHistory.length}`);

        return validationResult.isValid;
    }

    performValidation(data) {
        // Basic validation logic
        if (!data || typeof data !== 'object') {
            return false;
        }

        // Required fields for student requests
        if (!data.studentId) {
            return false;
        }

        // Cache schema for reuse (MEMORY LEAK: schema cache grows)
        const schemaKey = `schema_${Object.keys(data).join('_')}`;
        if (!schemaCache[schemaKey]) {
            schemaCache[schemaKey] = {
                fields: Object.keys(data),
                created: Date.now(),
                validationRules: this.generateRules(data) // MEMORY LEAK: complex objects stored
            };
        }

        return true;
    }

    createValidator() {
        // Memory leak: Creates new validator but adds to array without cleanup
        const validator = {
            id: Date.now() + Math.random(),
            created: new Date(),
            rules: [],
            cache: new Map() // MEMORY LEAK: nested cache
        };

        this.validators.push(validator); // MEMORY LEAK: unbounded array
        return validator;
    }

    generateRules(data) {
        // Memory leak: Creates complex rule objects
        return {
            studentId: { required: true, type: 'string' },
            metadata: new Array(1000).fill(`rule_${Date.now()}`), // MEMORY LEAK: large arrays
            complexValidation: {
                patterns: [],
                cache: new Map(), // MEMORY LEAK: nested maps
                history: []
            }
        };
    }

    // Missing cleanup methods - these should exist but don't (INTENTIONAL BUG)
    // clearCache() { ... }
    // disposeValidators() { ... }
    // cleanupHistory() { ... }

    getStats() {
        return {
            cacheSize: validationCache.size,
            historyLength: this.requestHistory.length,
            validatorsCount: this.validators.length,
            schemaCacheSize: Object.keys(schemaCache).length
        };
    }
}

module.exports = { ValidationMiddleware };