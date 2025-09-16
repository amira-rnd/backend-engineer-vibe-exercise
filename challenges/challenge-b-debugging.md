# Challenge B: GraphQL API Memory Leak
## ⭐ PRIORITY CHALLENGE
## Time: 15 minutes (60-minute format) | 20 minutes (90-minute format)

### Background

Our GraphQL API (AppSync) is experiencing memory leaks and crashes under load. The resolver calls a Lambda function that interfaces with both Node.js services and legacy .NET/C++ components.

### The Problem

```javascript
// Current Lambda Handler (simplified)
const { LegacyApiClient } = require('./legacy-client');
const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient();

let legacyClient = new LegacyApiClient(); // Singleton pattern

exports.handler = async (event) => {
    const { studentId, assessmentType, dateRange } = event.arguments;
    
    try {
        // Step 1: Get student data from DynamoDB
        const studentData = await ddb.get({
            TableName: 'Students',
            Key: { PK: `STUDENT#${studentId}`, SK: 'PROFILE' }
        }).promise();
        
        // Step 2: Get assessments from legacy system
        const assessments = await legacyClient.getAssessments(
            studentId, 
            assessmentType,
            dateRange
        );
        
        // Step 3: Process and enrich data
        const enrichedData = assessments.map(assessment => {
            return {
                ...assessment,
                studentGrade: studentData.Item.grade,
                readingLevel: studentData.Item.readingLevel,
                processedAt: new Date().toISOString()
            };
        });
        
        return enrichedData;
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
};
```

### Legacy Client Code (Partial)

```javascript
// legacy-client.js
const edge = require('edge-js');

class LegacyApiClient {
    constructor() {
        this.dotNetFunction = edge.func({
            assemblyFile: './bin/LegacyApi.dll',
            typeName: 'Amira.Legacy.ApiWrapper',
            methodName: 'GetAssessments'
        });
        this.connections = [];
    }
    
    async getAssessments(studentId, type, dateRange) {
        return new Promise((resolve, reject) => {
            const connection = this.createConnection();
            this.connections.push(connection);
            
            this.dotNetFunction({
                studentId,
                type,
                dateRange,
                connection
            }, (error, result) => {
                if (error) reject(error);
                else resolve(result);
            });
        });
    }
    
    createConnection() {
        // Creates connection to legacy SQL Server
        return { id: Date.now(), active: true };
    }
}
```

### Error Logs

```
ERROR: Exit Code 139
ERROR: Segmentation fault (SIGSEGV)
ERROR: "double free or corruption"
CloudWatch: Memory usage increases linearly with requests
CloudWatch: Lambda function timeout after ~100 requests
```

### Your Task

1. **Identify the memory leak source(s)**
2. **Fix the implementation**
3. **Add proper cleanup and error handling**
4. **Optimize for concurrent requests**

### Additional Context

- The .NET assembly uses unmanaged C++ code internally
- P/Invoke marshalling is involved
- The Lambda has 3GB memory allocated
- Cold starts are not the issue
- The problem only occurs under sustained load

### Evaluation Criteria

**Excellent (5/5):**
- Identifies connection array never being cleaned
- Fixes singleton pattern issues
- Implements proper dispose pattern
- Adds connection pooling/limits
- Uses AI to research SIGSEGV causes

**Good (4/5):**
- Identifies memory leak
- Implements basic cleanup
- Improves error handling
- Shows debugging methodology

**Acceptable (3/5):**
- Recognizes memory issue
- Attempts fixes
- Basic understanding shown

### Hints (if stuck)

- "Look at the lifecycle of the connections array"
- "Consider what happens to the singleton between Lambda invocations"
- "Think about .NET/C++ resource management"

### Discussion Questions

1. How would you monitor this in production?
2. What's the trade-off between singleton and creating new instances?
3. How would you load test this fix?
4. What other architectural patterns could prevent this?
