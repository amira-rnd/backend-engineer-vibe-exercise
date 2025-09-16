# Rapid Fire Challenges
## ⚡ IF TIME PERMITS
## Time: 5 minutes total (60-minute format)

Present 2-3 of these based on remaining time. In 60-minute format, these are optional.

## ⭐ Task 1: Lambda Rate Limiting (PRIORITIZE)
**Time: 2 minutes**

Add rate limiting (100 req/min per user) to this Lambda:

```javascript
exports.handler = async (event) => {
    const { userId, action } = event;
    // Add rate limiting here
    return { statusCode: 200, body: 'Success' };
};
```

**Looking for:** DynamoDB/Redis, sliding window, 429 response

## Task 2: Fix BatchGetItem Bug
**Time: 3 minutes**

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

**Looking for:** UnprocessedKeys, 100 item limit, retry logic

## Task 3: Convert Recursive CTE
**Time: 3 minutes**

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

**Looking for:** BFS/DFS approach, handling cycles, efficiency

## Task 4: Add Monitoring
**Time: 2 minutes**

Add CloudWatch metrics to track:
- API latency
- Error rate
- DynamoDB throttling

```javascript
async function processRequest(request) {
    // Add monitoring here
    const result = await complexOperation(request);
    return result;
}
```

**Looking for:** Custom metrics, proper units, error tracking

## Task 5: Memory Leak Fix
**Time: 3 minutes**

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

**Looking for:** Unbounded cache, LRU implementation, TTL

## Evaluation Notes
- Speed and correctness balance
- AI tool usage efficiency  
- Ability to context switch
- Grace under time pressure
