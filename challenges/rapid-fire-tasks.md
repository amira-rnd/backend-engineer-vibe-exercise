# Rapid Fire Challenges
## ⚡ IF TIME PERMITS
## Time: 5-10 minutes total

Present 2-3 of these based on remaining time. These are optional but valuable for evaluating startup fitness and context-switching ability.

## ⭐ Task 1: Lambda Rate Limiting (PRIORITIZE)
**Time: 2 minutes**

Add rate limiting (100 req/min per user) to this Lambda:

**JavaScript Version:**
```javascript
exports.handler = async (event) => {
    const { userId, action } = event;
    // Add rate limiting here
    return { statusCode: 200, body: 'Success' };
};
```

**Python Version:**
```python
import json

def lambda_handler(event, context):
    user_id = event['userId']
    action = event['action']
    # Add rate limiting here
    return {
        'statusCode': 200,
        'body': json.dumps('Success')
    }
```

**Looking for:** DynamoDB/Redis, sliding window, 429 response

## Task 2: Fix BatchGetItem Bug
**Time: 3 minutes**

This code misses items. Fix it:

**JavaScript Version:**
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

**Python Version:**
```python
import boto3

def get_batch(ids):
    dynamodb = boto3.resource('dynamodb')

    request_items = {
        'Students': {
            'Keys': [
                {'PK': f'STUDENT#{id}', 'SK': 'PROFILE'}
                for id in ids
            ]
        }
    }

    response = dynamodb.batch_get_item(RequestItems=request_items)
    return response['Responses']['Students']
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

**JavaScript Version:**
```javascript
function getSubordinates(employees) {
    // Convert SQL CTE to JavaScript
    // Input: array of {employee_id, name, manager_id}
    // Output: array with level added
}
```

**Python Version:**
```python
def get_subordinates(employees):
    """Convert SQL CTE to Python

    Args:
        employees: List of dicts with employee_id, name, manager_id

    Returns:
        List of dicts with level added
    """
    pass
```

**Looking for:** BFS/DFS approach, handling cycles, efficiency

## Task 4: Add Monitoring
**Time: 2 minutes**

Add CloudWatch metrics to track:
- API latency
- Error rate
- DynamoDB throttling

**JavaScript Version:**
```javascript
async function processRequest(request) {
    // Add monitoring here
    const result = await complexOperation(request);
    return result;
}
```

**Python Version:**
```python
import time

async def process_request(request):
    # Add monitoring here
    result = await complex_operation(request)
    return result
```

**Looking for:** Custom metrics, proper units, error tracking

## Task 5: Memory Leak Fix
**Time: 3 minutes**

Find and fix the memory leak:

**JavaScript Version:**
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

**Python Version:**
```python
from flask import Flask, request, jsonify

app = Flask(__name__)
cache = {}

@app.route('/api/data/<id>')
async def get_data(id):
    if id not in cache:
        cache[id] = await fetch_large_dataset(id)
    return jsonify(cache[id])
```

**Looking for:** Unbounded cache, LRU implementation, TTL

## Evaluation Notes
- Speed and correctness balance
- AI tool usage efficiency  
- Ability to context switch
- Grace under time pressure
