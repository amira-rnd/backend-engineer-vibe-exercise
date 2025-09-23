// Lambda Entry Point (index.js)
// This file connects the Lambda runtime to our main application code

const { handler } = require('./main');

// Re-export the handler for Lambda runtime
exports.handler = handler;