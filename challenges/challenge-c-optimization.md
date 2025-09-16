# Challenge C: Assignment Conflict Resolution Performance
## ⚡ OPTIONAL - Only if candidate is moving very quickly
## Time: 15 minutes (60-minute format) | 25 minutes (90-minute format)

### Background

Our assignment conflict resolution system processes student assessments across a hierarchy:
DISTRICT > SCHOOL > CLASS > STUDENT

The system is taking 30+ seconds for large districts. We need to optimize both the database queries and the application logic.

### Current Implementation

```sql
-- Current slow query
WITH RECURSIVE hierarchy AS (
    -- Base case: get all students in district
    SELECT 
        s.student_id,
        s.class_id,
        c.school_id,
        sc.district_id,
        s.grade_level,
        s.reading_level
    FROM students s
    JOIN classes c ON s.class_id = c.class_id
    JOIN schools sc ON c.school_id = sc.school_id
    WHERE sc.district_id = $1
    
    UNION ALL
    
    -- Recursive case: get all assessments
    SELECT 
        h.student_id,
        a.assessment_id,
        a.type,
        a.score,
        a.window_tag,
        a.created_at
    FROM hierarchy h
    JOIN assessments a ON h.student_id = a.student_id
    WHERE a.created_at >= $2 AND a.created_at <= $3
)
SELECT * FROM hierarchy;
```

### Conflict Resolution Logic

```javascript
// Current implementation (simplified)
async function resolveConflicts(districtId, windowTag) {
    // Step 1: Get all data (30+ seconds for large districts)
    const allData = await db.query(RECURSIVE_QUERY, [districtId, startDate, endDate]);
    
    // Step 2: Group by student
    const studentGroups = {};
    allData.rows.forEach(row => {
        if (!studentGroups[row.student_id]) {
            studentGroups[row.student_id] = [];
        }
        studentGroups[row.student_id].push(row);
    });
    
    // Step 3: Apply conflict rules
    const resolved = [];
    for (const studentId in studentGroups) {
        const assessments = studentGroups[studentId];
        
        // Complex priority rules
        const prioritized = assessments.sort((a, b) => {
            // BENCHMARK > PROGRESS_MONITORING > INSTRUCT
            if (a.type === 'BENCHMARK' && b.type !== 'BENCHMARK') return -1;
            if (a.type === 'PROGRESS_MONITORING' && b.type === 'INSTRUCT') return -1;
            
            // Within same type, prefer most recent
            return new Date(b.created_at) - new Date(a.created_at);
        });
        
        // Keep only the highest priority per window
        const windows = {};
        prioritized.forEach(assessment => {
            if (!windows[assessment.window_tag] || 
                shouldReplace(windows[assessment.window_tag], assessment)) {
                windows[assessment.window_tag] = assessment;
            }
        });
        
        resolved.push(...Object.values(windows));
    }
    
    return resolved;
}
```

### Performance Issues

1. **Database**: Recursive CTE is inefficient for large hierarchies
2. **Memory**: Loading all data at once causes memory pressure
3. **CPU**: O(n²) complexity in conflict resolution
4. **No caching**: Same data fetched repeatedly

### Sample Data Scale

- Large district: 50,000 students
- Average assessments per student: 12
- Total records processed: 600,000+
- Current execution time: 30-45 seconds
- Target execution time: <3 seconds

### Your Task

1. **Optimize the SQL query** (consider alternatives to recursive CTE)
2. **Implement streaming/pagination** to reduce memory usage
3. **Add caching strategy** for hierarchical data
4. **Optimize the conflict resolution algorithm**
5. **Consider moving some logic to the database**

### Evaluation Criteria

**Excellent (5/5):**
- Eliminates recursive CTE 
- Implements streaming/batching
- Adds Redis/ElastiCache layer
- Reduces complexity to O(n log n)
- Uses database functions for rules

**Good (4/5):**
- Improves query performance
- Implements basic batching
- Adds some caching
- Shows clear optimization strategy

**Acceptable (3/5):**
- Identifies main bottlenecks
- Makes some improvements
- Basic understanding of issues

### Hints (if needed)

- "Could you denormalize the hierarchy?"
- "What if you pre-computed the conflicts?"
- "Consider using window functions"
- "Think about materialized views"

### Discussion Questions

1. How would you roll this out safely?
2. What metrics would you monitor?
3. Trade-offs between complexity and performance?
4. How would you handle cache invalidation?
