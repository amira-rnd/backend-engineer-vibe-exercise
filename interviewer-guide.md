# Interviewer Guide - Vibe Coding Exercise (60-Minute Version)
## Amira Learning Senior Backend Engineer

### 🎯 Session Objectives

Evaluate the candidate's ability to:
1. Use AI coding tools effectively in real-world scenarios
2. Debug and optimize production-like code
3. Work with ambiguous requirements
4. Balance speed with quality
5. Demonstrate Amira-relevant domain knowledge

### ⏰ CRITICAL: 60-Minute Time Management

**Strict timebox enforcement required!** This session is now 60 minutes.

### 📋 Pre-Session Checklist

- [ ] Run `make deploy CANDIDATE=their-name` to create AWS environment (includes challenge file upload)
- [ ] Run `make verify CANDIDATE=their-name` to test all resources
- [ ] Run `make credentials CANDIDATE=their-name` to generate AWS credentials
- [ ] **⭐ COPY the challenge URLs displayed at the end of `make credentials` - you'll need these during interview**
- [ ] Candidate received prep materials 24 hours ago (via `make prep-email`)
- [ ] Challenge files uploaded and accessible via Sample Data API
- [ ] **Choose 2 main challenges based on candidate background**
- [ ] Screen recording software ready (with consent)
- [ ] **CRITICAL: Review comprehensive-scoring-rubric.md for AI usage evaluation**
- [ ] Scoring rubric printed/open
- [ ] **Set timers for each section**
- [ ] **Verify infrastructure readiness (see Data Verification Checklist below)**

### 🔗 Getting Challenge URLs

**✅ URLs are displayed when you run `make credentials CANDIDATE=name`**

The command outputs ready-to-copy challenge URLs that look like this:
```bash
🔗 CHALLENGE URLs FOR INTERVIEWER (save these for interview):

Base API: https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod

📋 Copy/paste these during interview:
Challenge A: curl "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod?file=challenge-a-migration.md"
Challenge B (C++/.NET): curl "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod?file=challenge-b-debugging.md"
...
```

**📋 During Interview - Just copy/paste the exact curl commands returned from `make credentials ...`**

### ⏱️ Detailed Session Flow - 60 MINUTES

## Part 1: Setup & Introduction (5 minutes MAX)

### Minutes 0-3: Technical Setup
```
"Welcome! Let's quickly get you set up. Please share your screen and open your development environment."

Key observations:
- What AI tool did they choose?
- Is their workspace ready?
- Quick environment test
```

### Minutes 3-5: Brief Tool Overview
```
"Briefly walk me through how you typically use [their AI tool]. 
Show me a quick example if possible."

Keep this SHORT - you can observe more during challenges.
```

## Part 2: Main Challenges (40-45 minutes)

### ⭐ PRIORITY: Choose 2 of these 3 challenges

### Challenge A: Data Migration Script (15 minutes if selected)

**Present Challenge via:**
- **RECOMMENDED:** Copy/paste the Challenge A curl command from `make credentials` output
- **Alternative:** Screen share challenges/ directory if API is unavailable
- **Backup:** Copy/paste challenge text into chat during interview

**Setup Statement:**
```
"You have 15 minutes to migrate student assessment data from our legacy system to DynamoDB.
The legacy system has data quality issues. Focus on handling the most critical issues first.
You can access schemas and sample data via the API provided in your credentials email.
[Share challenge document]"
```

**Time Management:**
- 2 min: Understanding the problem
- 10 min: Implementation
- 3 min: Quick test/validation

**Early Hints (if stuck after 7 min):**
- "Focus on grade normalization and invalid data first"
- "Don't worry about perfect error handling"

**Detailed Hints (after 5 minutes):**
- "Focus on grade normalization first"
- "Don't worry about perfect retry logic"
- "BatchWriteItem has a 25 item limit"

**Evaluation Criteria:**
- **Excellent (5/5):** Handles critical data quality issues (grade, reading level), implements batch processing, basic error handling, efficient AI usage for boilerplate. **⭐ BONUS:** Implements idempotency without being told (deterministic UUIDs or checks for existing records), makes script resumable, adds progress monitoring with ETA/rate metrics, proactively discusses production concerns
- **Good (4/5):** Handles most data quality issues, basic batch processing works, some error handling. **May mention idempotency concerns** even if not fully implemented, shows awareness of duplicate risk on re-runs, basic progress logging (X of Y processed)
- **Acceptable (3/5):** Basic migration works, handles some edge cases, gets data moving. May not consider idempotency unless prompted, minimal or no progress feedback
- **Below Expectations (<3/5):** Doesn't handle critical data issues, no batch processing, major bugs

**🎯 Senior Engineer Indicators:**
- **Unprompted idempotency implementation** = Strong senior signal (deterministic UUIDs, duplicate checking)
- **Progress tracking/checkpointing** = Production thinking (ability to resume from partial failures)
- **Progress monitoring with ETA** = Operational excellence (shows progress %, processing rate, time remaining)
- **Structured logging/metrics** = Production readiness (CloudWatch metrics, not just print statements)
- **Discusses re-run scenarios** = Operational maturity (what happens on script failure)

**Discussion Questions (wrap-up):**
1. How would you handle this at scale (millions of records)?
2. What monitoring would you add?
3. How would you validate the migration was successful?
4. What would you do differently if this was a live migration?
5. **What happens if your script fails halfway through and needs to be re-run?**
6. **How would you ensure no duplicate records on multiple runs?**
7. **How would you track migration progress for resumability?**
8. **How would you provide visibility into migration progress for stakeholders?**
9. **What metrics would you expose during the migration? (processing rate, ETA, etc.)**

**💡 Interviewer Notes:** Questions 5-9 test production concerns that senior engineers should consider automatically. Strong candidates will have already addressed these without prompting.

**🎯 What to Look For in Progress Monitoring:**
- Progress percentage (X% complete)
- Processing rate (records/second)
- Estimated time remaining
- Periodic status updates (every N records or X seconds)
- Structured logging vs simple print statements
- Consideration of CloudWatch metrics or monitoring integration

### Challenge B: API Debugging (15 minutes if selected)

**Present Challenge via:**
- **FIRST: Check background for version selection**
  - C++/.NET experience: Copy/paste Challenge B (C++/.NET) curl command from `make credentials` output
  - Otherwise: Copy/paste Challenge B (Alternative) curl command from `make credentials` output
- **Alternative:** Screen share challenges/ directory if API is unavailable
- **Backup:** Copy/paste challenge text into chat

**Setup Statement:**
```
"You have 15 minutes to identify and fix memory leaks in this service.
It crashes under load. Focus on finding the main causes.
Use the setup script for fastest download: curl and run setup-project.sh
[Share appropriate challenge document based on their background]"
```

**Project-Based Challenge Instructions (for challenge-b-debugging.md):**
- Candidate should use setup-project.sh script for quick download
- Monitor their approach to multi-module analysis (6 modules total)
- Watch for systematic file-by-file review vs random exploration
- Note: Setup script creates proper directory structure automatically

**Time Management:**
- 1 min: Download project using setup script
- 4 min: Analyze symptoms and trace architecture across modules
- 9 min: Identify multiple memory leak sources
- 1 min: Explain systematic approach

**Key Observation Points:**
- Do they systematically review all 6 modules or focus randomly?
- Can they distinguish real leaks from performance red herrings?
- Do they identify connection pooling, event listeners, and cache issues?
- How do they handle the complexity of multi-module architecture?
- Do they follow the curl download instructions properly?

**Detailed Hints (provide after 10 minutes):**
- "Look at what happens to Maps and Arrays across Lambda invocations"
- "Check where event listeners are added vs removed"
- "Consider cache eviction strategies"
- "Think about circular references in the data structures"
- "Examine the .NET connection lifecycle"

**Evaluation Criteria:**
- **Excellent (5/5):** Identifies 6+ memory leak sources across multiple modules, recognizes the .NET connection pool as primary issue, fixes event listener accumulation, implements cache eviction strategies, addresses circular reference patterns, shows systematic debugging methodology, uses AI strategically for syntax/implementation only
- **Good (4/5):** Identifies 4-5 memory leak sources, fixes connection pool cleanup, addresses cache growth issues, shows good debugging process, some AI usage for research
- **Acceptable (3/5):** Identifies 2-3 main issues, recognizes memory growth problem, basic fixes attempted, shows some understanding of .NET interop

**What NOT to Use AI For:**
Candidates should demonstrate debugging methodology first:
- ❌ "AI, find all the memory leaks in this code"
- ❌ "AI, what's causing the SIGSEGV?"
- ❌ "AI, fix the memory issues"
- ✅ Identify patterns themselves, then ask for implementation help
- ✅ Understand root causes before asking for syntax
- ✅ Use AI for specific fixes after diagnosis

**🔍 INTERVIEWER REFERENCE - Memory Leak Sources:**

**📋 Complete Answer Key (10 Memory Leaks):**
1. **Connection Pool Map** (legacy-client.js:317) - Never cleaned, grows forever
2. **Request Metrics Map** (metrics-collector.js:235) - Never cleaned up after recordSuccess
3. **Connection Stats Array** (legacy-client.js:361) - Unbounded growth
4. **Request Queue Array** (legacy-client.js:296) - Never cleaned
5. **Event Listeners** (request-processor.js:71-73) - Added but never removed
6. **Cache with no eviction** (cache-manager.js:191) - Unbounded cache growth
7. **Circular References** (data-enricher.js:411) - enrichmentContext references itself
8. **Validation History** (validation-middleware.js:449) - Unbounded array growth
9. **Active Requests Map** (request-processor.js:122) - Cleanup commented out
10. **Performance Metrics Array** (metrics-collector.js:233) - Grows forever

**⚠️ Performance Red Herrings (NOT Memory Leaks):**
These look problematic but candidates should NOT focus on them:
- Synchronous JSON.stringify in cache-manager.js - Looks slow, but doesn't leak memory
- Multiple DynamoDB clients in request-processor.js - Inefficient but AWS SDK handles cleanup
- Deep object spreading in data-enricher.js - CPU intensive but temporary objects get GC'd
- Lack of connection pooling for DynamoDB - Performance issue but not a memory leak
- Recursive event emission in request-processor.js - Could cause stack overflow but stack memory is released

**Discussion Questions (wrap-up):**
1. How would you monitor this in production?
2. What's the trade-off between singleton and creating new instances?
3. How would you load test this fix?

**Challenge B Alternative Version (for non-C++/.NET candidates):**

**Alternative Hints (if stuck after 10 minutes):**
- "Look at what happens to event listeners"
- "Check the lifecycle of axios instances"
- "Consider what happens to the cache over time"
- "Think about the recursive history fetching"
- "What happens to failed assessments in the queue?"

**Alternative Evaluation Criteria:**
- **Excellent (5/5):** Identifies all 4+ memory leaks (event listeners, axios instances, unbounded cache, recursive calls), fixes connection cleanup issues, implements proper error handling for failed queue items, shows systematic debugging approach
- **Good (4/5):** Identifies 3+ main issues, fixes event listener accumulation, addresses cache growth, shows good debugging methodology
- **Acceptable (3/5):** Identifies 2+ issues, recognizes memory growth patterns, attempts basic fixes

### Challenge C: Performance Optimization (15 minutes if selected)
⚡ **Only use if candidate is moving very quickly**

**Present Challenge via:**
- **RECOMMENDED:** Copy/paste the Challenge C curl command from `make credentials` output
- **Alternative:** Screen share challenges/ directory if API is unavailable
- **Backup:** Copy/paste challenge text into chat

**Setup Statement:**
```
"You have 15 minutes to optimize this conflict resolution system.
Focus on the biggest performance wins first.
[Share challenge document]"
```

**Detailed Hints (if needed):**
- "Consider alternatives to recursive CTEs"
- "Think about caching hierarchical data"
- "Look at the conflict resolution algorithm complexity"

**🔍 INTERVIEWER REFERENCE - Performance Issues:**

**📋 Root Cause Analysis (Expected Findings):**
1. **Database**: Recursive CTE is inefficient for large hierarchies
2. **Memory**: Loading all data at once causes memory pressure
3. **CPU**: O(n²) complexity in conflict resolution
4. **No caching**: Same data fetched repeatedly

**📝 Expected Solutions Candidates Should Identify:**
1. **Optimize the SQL query** (consider alternatives to recursive CTE)
2. **Implement streaming/pagination** to reduce memory usage
3. **Add caching strategy** for hierarchical data
4. **Optimize the conflict resolution algorithm**
5. **Consider moving some logic to the database**

**Evaluation Criteria:**
- **Excellent (5/5):** Identifies SQL query as primary bottleneck, proposes specific alternatives to recursive CTE, implements caching strategy, optimizes conflict resolution algorithm, shows systematic performance analysis approach
- **Good (4/5):** Identifies main performance issues, proposes reasonable optimizations, shows understanding of database vs application logic trade-offs
- **Acceptable (3/5):** Identifies some bottlenecks, basic optimization attempts, shows awareness of performance concerns

**Discussion Questions (wrap-up):**
1. How would you measure the impact of these optimizations?
2. What monitoring would you add for production?
3. How would you handle this at scale (millions of students)?

## Part 3: Rapid Fire Challenges (5-10 minutes)

**Present Challenges via:**
- **RECOMMENDED:** Copy/paste the Rapid Fire curl command from `make credentials` output
- **Alternative:** Screen share challenges/ directory if API is unavailable
- **Backup:** Copy/paste individual tasks into chat during interview

### If time permits, present 2-3 quick tasks:

#### **⭐ Task 1: Lambda Rate Limiting (2 min)** - PRIORITIZE
Add rate limiting (100 req/min per user) to this Lambda:
```javascript
exports.handler = async (event) => {
    const { userId, action } = event;
    // Add rate limiting here
    return { statusCode: 200, body: 'Success' };
};
```

#### **Task 2: Fix BatchGetItem Bug (3 min)**
This code misses items. Fix it:
```javascript
async function getBatch(ids) {
    const params = {
        RequestItems: {
            'Students': {
                Keys: ids.map(id => ({
                    PK: `STUDENT#${id}`, SK: 'PROFILE'
                }))
            }
        }
    };
    const result = await ddb.batchGet(params).promise();
    return result.Responses.Students;
}
```

#### **Task 3: Convert Recursive CTE (3 min)**
Convert this SQL to application code:
```sql
WITH RECURSIVE subordinates AS (
    SELECT employee_id, name, manager_id, 0 as level
    FROM employees WHERE manager_id IS NULL
    UNION ALL
    SELECT e.employee_id, e.name, e.manager_id, s.level + 1
    FROM employees e
    JOIN subordinates s ON e.manager_id = s.employee_id
)
SELECT * FROM subordinates;
```

#### **Task 4: Add Monitoring (2 min)**
Add CloudWatch metrics to track API latency, error rate, DynamoDB throttling:
```javascript
async function processRequest(request) {
    // Add monitoring here
    const result = await complexOperation(request);
    return result;
}
```

#### **Task 5: Memory Leak Fix (3 min)**
Find and fix the memory leak:
```javascript
const cache = {};
app.get('/api/data/:id', async (req, res) => {
    const { id } = req.params;
    if (!cache[id]) {
        cache[id] = await fetchLargeDataset(id);
    }
    res.json(cache[id]);
});
```

**Focus on:** Speed, pattern recognition, and efficient context switching

### 🔍 RAPID FIRE SOLUTIONS & GUIDANCE

#### **Task 1: Lambda Rate Limiting** ⭐ PRIORITIZE
**Expected Solution:**
```javascript
const AWS = require('aws-sdk');
const ddb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const { userId, action } = event;
    const minute = Math.floor(Date.now() / 60000);
    const key = `rate_limit:${userId}:${minute}`;

    try {
        await ddb.update({
            TableName: 'RateLimit',
            Key: { id: key },
            UpdateExpression: 'ADD #count :one',
            ExpressionAttributeNames: { '#count': 'count' },
            ExpressionAttributeValues: { ':one': 1, ':limit': 100 },
            ConditionExpression: 'attribute_not_exists(#count) OR #count < :limit'
        }).promise();

        return { statusCode: 200, body: 'Success' };
    } catch (err) {
        if (err.code === 'ConditionalCheckFailedException') {
            return { statusCode: 429, body: 'Rate limit exceeded' };
        }
        throw err;
    }
};
```

**Key Points to Look For:**
- ✅ DynamoDB or Redis for storage
- ✅ Sliding window approach (minute-based key)
- ✅ 429 status code for rate limit exceeded
- ✅ Conditional updates to prevent race conditions

**Hints if Stuck:**
- "Think about time windows for rate limiting"
- "What HTTP status code for rate limits?"
- "Consider race conditions with concurrent requests"

#### **Task 2: BatchGetItem Bug Fix**
**Expected Solution:**
```javascript
async function getBatch(ids) {
    let allItems = [];
    let remainingKeys = ids.map(id => ({
        PK: `STUDENT#${id}`, SK: 'PROFILE'
    }));

    while (remainingKeys.length > 0) {
        // DynamoDB has 100 item limit
        const batch = remainingKeys.splice(0, 100);

        const params = {
            RequestItems: {
                'Students': { Keys: batch }
            }
        };

        const result = await ddb.batchGet(params).promise();
        allItems.push(...result.Responses.Students);

        // Handle unprocessed keys
        if (result.UnprocessedKeys?.Students?.Keys) {
            remainingKeys.unshift(...result.UnprocessedKeys.Students.Keys);
            await new Promise(resolve => setTimeout(resolve, 100)); // Backoff
        }
    }

    return allItems;
}
```

**Key Points to Look For:**
- ✅ Handles UnprocessedKeys
- ✅ Respects 100 item batch limit
- ✅ Retry logic with backoff
- ✅ Returns all requested items

**Hints if Stuck:**
- "What's DynamoDB's batch limit?"
- "What happens when DynamoDB can't process all items?"
- "How would you handle throttling?"

#### **Task 3: Recursive CTE Conversion**
**Expected Solution:**
```javascript
async function getSubordinates() {
    // Get all employees first
    const employees = await db.query('SELECT * FROM employees');
    const empMap = new Map(employees.map(e => [e.employee_id, e]));

    // Find root managers
    const roots = employees.filter(e => e.manager_id === null);
    const result = [];

    // BFS traversal
    const queue = roots.map(emp => ({ ...emp, level: 0 }));
    const visited = new Set();

    while (queue.length > 0) {
        const current = queue.shift();

        // Prevent cycles
        if (visited.has(current.employee_id)) continue;
        visited.add(current.employee_id);

        result.push(current);

        // Add subordinates to queue
        const subordinates = employees.filter(e =>
            e.manager_id === current.employee_id &&
            !visited.has(e.employee_id)
        );

        queue.push(...subordinates.map(emp => ({
            ...emp,
            level: current.level + 1
        })));
    }

    return result;
}
```

**Key Points to Look For:**
- ✅ BFS or DFS approach
- ✅ Cycle detection (prevents infinite loops)
- ✅ Level tracking
- ✅ Efficient data structures (Map/Set)

**Hints if Stuck:**
- "Think about graph traversal algorithms"
- "How would you prevent infinite loops?"
- "Consider breadth-first vs depth-first"

#### **Task 4: CloudWatch Monitoring**
**Expected Solution:**
```javascript
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

async function processRequest(request) {
    const startTime = Date.now();
    let errorOccurred = false;

    try {
        const result = await complexOperation(request);

        // Success metrics
        await cloudwatch.putMetricData({
            Namespace: 'MyApp/API',
            MetricData: [{
                MetricName: 'RequestLatency',
                Value: Date.now() - startTime,
                Unit: 'Milliseconds',
                Timestamp: new Date()
            }]
        }).promise();

        return result;

    } catch (error) {
        errorOccurred = true;

        // Error metrics
        await cloudwatch.putMetricData({
            Namespace: 'MyApp/API',
            MetricData: [
                {
                    MetricName: 'ErrorRate',
                    Value: 1,
                    Unit: 'Count'
                },
                {
                    MetricName: 'RequestLatency',
                    Value: Date.now() - startTime,
                    Unit: 'Milliseconds'
                }
            ]
        }).promise();

        // Check for DynamoDB throttling
        if (error.code === 'ProvisionedThroughputExceededException') {
            await cloudwatch.putMetricData({
                Namespace: 'MyApp/DynamoDB',
                MetricData: [{
                    MetricName: 'ThrottleCount',
                    Value: 1,
                    Unit: 'Count'
                }]
            }).promise();
        }

        throw error;
    }
}
```

**Key Points to Look For:**
- ✅ Custom CloudWatch metrics
- ✅ Proper metric units (Milliseconds, Count)
- ✅ Error tracking and categorization
- ✅ DynamoDB throttling detection

**Hints if Stuck:**
- "What units make sense for latency?"
- "How would you track different error types?"
- "Consider DynamoDB-specific error codes"

#### **Task 5: Memory Leak Fix**
**Expected Solution:**
```javascript
const LRU = require('lru-cache');

// Option 1: LRU Cache
const cache = new LRU({
    max: 1000,           // Max 1000 items
    ttl: 1000 * 60 * 10  // 10 minute TTL
});

app.get('/api/data/:id', async (req, res) => {
    const { id } = req.params;

    let data = cache.get(id);
    if (!data) {
        data = await fetchLargeDataset(id);
        cache.set(id, data);
    }

    res.json(data);
});

// Option 2: Manual implementation
const cache = new Map();
const cacheTimestamps = new Map();
const MAX_CACHE_SIZE = 1000;
const TTL = 10 * 60 * 1000; // 10 minutes

app.get('/api/data/:id', async (req, res) => {
    const { id } = req.params;
    const now = Date.now();

    // Check TTL
    if (cacheTimestamps.has(id) &&
        now - cacheTimestamps.get(id) > TTL) {
        cache.delete(id);
        cacheTimestamps.delete(id);
    }

    if (!cache.has(id)) {
        // Evict oldest if cache full
        if (cache.size >= MAX_CACHE_SIZE) {
            const oldestKey = cache.keys().next().value;
            cache.delete(oldestKey);
            cacheTimestamps.delete(oldestKey);
        }

        const data = await fetchLargeDataset(id);
        cache.set(id, data);
        cacheTimestamps.set(id, now);
    }

    res.json(cache.get(id));
});
```

**Key Points to Look For:**
- ✅ Cache size limits (LRU eviction)
- ✅ TTL implementation
- ✅ Memory leak identification (unbounded growth)
- ✅ Practical solution (LRU library or manual)

**Hints if Stuck:**
- "What happens to this cache over time?"
- "How would you limit cache size?"
- "Consider time-based expiration"

### **🎯 Evaluation Criteria for Rapid Fire:**
- **Speed**: Can they recognize patterns quickly?
- **Accuracy**: Core solution correct even if not perfect?
- **AI Usage**: Do they use AI efficiently for syntax/APIs?
- **Context Switching**: Can they jump between different problem types?
- **Startup Fitness**: Grace under pressure, practical solutions over perfect ones

## Part 4: Wrap-up (5 minutes)

**Quick Questions:**
- "Which solution are you most proud of?"
- "What would you do differently with more time?"
- "How did AI help or hinder you today?"

### 🎯 60-Minute Decision Framework

**Which Challenges to Choose:**

| Candidate Type | Challenge Selection |
|----------------|-------------------|
| Strong Systems Background | A + B (original) |
| Web/Cloud Background | A + B (alternative) |
| Moving Fast | A + B + Rapid Fire |
| Moving Slow | A + B (give more hints) |
| Very Senior | B + C (skip migration) |

### 🚩 Adjusted Red Flags for 60 Minutes

- Can't complete at least ONE challenge
- Spends too long reading without coding
- No AI usage in 60 minutes (concerning)
- Over-relies on AI without understanding
- **Challenge B specific**: Only relies on AI findings without independent validation
- **Challenge B specific**: Cannot identify issues beyond what AI suggests
- **Challenge B specific**: Cannot trace through multiple modules methodically

### ✅ Adjusted Green Flags for 60 Minutes

- Completes both main challenges
- Quick to identify problems
- Efficient AI usage
- Makes pragmatic trade-offs for speed
- Clear communication despite time pressure
- **Challenge B specific**: Uses AI efficiently for initial discovery, then validates findings
- **Challenge B specific**: Identifies memory leak sources beyond what AI suggests
- **Challenge B specific**: Systematically traces through all modules (not just AI findings)
- **Challenge B specific**: Distinguishes real leaks from performance red herrings
- **Challenge B specific**: Can explain WHY issues cause memory leaks (not just implement fixes)
