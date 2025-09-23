# Challenge B Alternative: Node.js Service Memory Leak
## ⭐ PRIORITY CHALLENGE
## Time: 15 minutes
## (Use this if candidate lacks C++/.NET experience)

### Background

Our student assessment processing service is experiencing memory leaks and crashes under load. The Node.js service processes assessment data through multiple async operations and integrates with DynamoDB and external APIs.

### The Problem

```javascript
// Current Implementation (simplified)
const AWS = require('aws-sdk');
const axios = require('axios');
const EventEmitter = require('events');

class AssessmentProcessor extends EventEmitter {
    constructor() {
        super();
        this.ddb = new AWS.DynamoDB.DocumentClient();
        this.processingQueue = [];
        this.activeConnections = new Map();
        this.cache = {};
        
        // Listen for processing events
        this.on('assessment-received', this.processAssessment.bind(this));
        this.on('batch-complete', this.handleBatchComplete.bind(this));
    }
    
    async processAssessment(assessment) {
        const connectionId = `conn-${Date.now()}-${Math.random()}`;
        
        try {
            // Step 1: Create connection for external API
            const connection = await this.createApiConnection(assessment.studentId);
            this.activeConnections.set(connectionId, connection);
            
            // Step 2: Fetch student history (recursive)
            const history = await this.fetchStudentHistory(
                assessment.studentId, 
                assessment.type
            );
```
            
            // Step 3: Cache the processed data
            const cacheKey = `${assessment.studentId}-${assessment.type}`;
            this.cache[cacheKey] = {
                assessment,
                history,
                connection,
                timestamp: Date.now()
            };
            
            // Step 4: Process through external scoring API
            const scoringResult = await this.callScoringApi(
                connection,
                assessment,
                history
            );
            
            // Step 5: Write to DynamoDB
            await this.writeResults(assessment.studentId, scoringResult);
            
            return scoringResult;
            
        } catch (error) {
            console.error('Processing failed:', error);
            this.processingQueue.push(assessment); // Retry later
            throw error;
        }
    }
    
    async fetchStudentHistory(studentId, type, depth = 0) {
        if (depth > 10) return [];
        
        const history = await this.ddb.query({
            TableName: 'Assessments',
            KeyConditionExpression: 'studentId = :sid',
            ExpressionAttributeValues: { ':sid': studentId }
        }).promise();
        
        // Recursive call for related assessments
        const related = [];
        for (const item of history.Items) {
            if (item.relatedId) {
                const subHistory = await this.fetchStudentHistory(
                    item.relatedId, 
                    type, 
                    depth + 1
                );
                related.push(...subHistory);
            }
        }
        
        return [...history.Items, ...related];
    }
    
    async createApiConnection(studentId) {
        const connection = axios.create({
            baseURL: 'https://scoring-api.amira.com',
            timeout: 30000,
            headers: { 'X-Student-Id': studentId }
        });
        
        // Add interceptors
        connection.interceptors.response.use(
            response => response,
            error => {
                console.error('API Error:', error);
                return Promise.reject(error);
            }
        );
        
        return connection;
    }
    
    async callScoringApi(connection, assessment, history) {
        const response = await connection.post('/score', {
            assessment,
            history,
            timestamp: Date.now()
        });
        return response.data;
    }
    
    handleBatchComplete(batchId) {
        console.log(`Batch ${batchId} complete`);
        // Note: connections not being cleaned up
    }
}

// Lambda handler
let processor = new AssessmentProcessor(); // Reused across invocations

exports.handler = async (event) => {
    const assessments = event.Records.map(r => JSON.parse(r.body));
    
    const results = await Promise.all(
        assessments.map(a => {
            processor.emit('assessment-received', a);
            return processor.processAssessment(a);
        })
    );
    
    return { processed: results.length };
};
```

### Error Symptoms

```
CloudWatch Logs:
- Memory usage grows linearly: 128MB → 512MB → 1GB → 3GB → CRASH
- Error: "JavaScript heap out of memory"
- Lambda timeouts after ~50-100 assessments
- Occasional "Maximum call stack size exceeded"
- DynamoDB throttling errors increase over time

Metrics:
- P99 latency: 30+ seconds
- Memory: Continuous growth, no garbage collection
- Connections: Hundreds of active connections to scoring API
- Cache size: Unbounded growth
```

### Your Task

1. **Identify ALL memory leak sources** (there are at least 4)
2. **Fix the implementation**
3. **Add proper cleanup and resource management**
4. **Optimize for concurrent processing**
5. **Prevent future issues**

### Additional Context

- Lambda has 3GB memory allocated
- Processes batches of 10-100 assessments
- The service worked fine with small batches initially
- Problems only appear under sustained load
- External scoring API has rate limits (100 req/sec)

