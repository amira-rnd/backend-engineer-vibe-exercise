# Challenge C: Assignment Conflict Resolution Performance
## ⚡ OPTIONAL - Only if candidate is moving very quickly
## Time: 15 minutes

### Background

Our assignment conflict resolution system processes student assessments across a hierarchy:
DISTRICT > SCHOOL > CLASS > STUDENT

The system is taking 30+ seconds for large districts. We need to optimize both the database queries and the application logic.

### Database Connection Details

**PostgreSQL Endpoint:** `interview-db-performance.[region].rds.amazonaws.com`
**Username:** `postgres`
**Password:** (see credentials email)
**Database:** `postgres`

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

### Observed Symptoms

- **Query execution**: 30-45 seconds for large districts
- **Memory usage**: Spikes to 8GB during processing
- **CPU utilization**: Sustained 100% for entire duration
- **Database connections**: Frequent timeouts under load
- **User experience**: UI freezes, timeouts on API calls

### Sample Data Scale

- Large district: 50,000 students
- Average assessments per student: 12
- Total records processed: 600,000+
- Current execution time: 30-45 seconds
- Target execution time: <3 seconds

### Your Task

1. **Identify and fix database bottlenecks**
2. **Reduce memory consumption during processing**
3. **Improve response time to <3 seconds**
4. **Ensure solution scales to millions of students**
5. **Optimize the conflict resolution logic**

