# Challenge A: Interviewer Notes - Undocumented Data Quality Issues

## Purpose

Challenge A tests whether candidates:
- **Actually inspect the data** vs blindly trusting requirements
- **Ask clarifying questions** when encountering edge cases
- **Demonstrate validation thinking** vs just code generation with AI
- **Question incomplete requirements** vs making assumptions

## The Trap

The challenge document lists 5 "Known Data Quality Issues" with a subtle hint:

> ⚠️ **The product owner has identified the following data quality issues** that are expected in the legacy system.

This phrasing implies:
- The list is what the product owner "identified" (not necessarily complete)
- These are "expected" issues (but there may be unexpected ones)
- Candidates should inspect actual data to validate

## Undocumented Data Quality Issues

### 1. Duplicate Student Records (StudentID 141)

**Location:** `legacy-students.csv` lines 42-43

```csv
141,Jessica,Smith,3,SCH001,2023-09-25 10:00:00,1,3.5
141,Jessica,Smith,4,SCH001,2023-09-26 11:00:00,1,4.2
```

**Issue:** Same StudentID appears twice with conflicting data (different grade levels, reading levels, created dates)

**What to Look For:**
- ✅ **Excellent**: Candidate notices duplicate, asks "Which record is correct? Should I use the latest? Merge them?"
- ⚠️ **Concerning**: Candidate silently picks one record without asking
- ❌ **Red Flag**: Migration fails on duplicate key or candidate doesn't notice

**Expected Discussion:**
- Business rule needed: use latest record? Use highest grade? Manual review?
- Demonstrates understanding that data decisions have business implications

---

### 2. Missing Required Field (Empty LastName)

**Location:** `legacy-students.csv` line 44

```csv
142,,Martinez,2,SCH002,2023-09-27 09:00:00,1,2.1
```

**Issue:** FirstName field is empty (note the double comma after StudentID)

**What to Look For:**
- ✅ **Excellent**: "Student 142 has no first name - should I skip this record, use a placeholder, or is this a data entry issue?"
- ⚠️ **Concerning**: Uses "Unknown" or blank without asking
- ❌ **Red Flag**: Doesn't notice or migration silently accepts empty required field

**Expected Discussion:**
- Is FirstName actually required in target system?
- What's the policy for incomplete student records?

---

### 3. Whitespace in Names

**Location:** `legacy-students.csv` line 45

```csv
143, Benjamin , Taylor ,5,SCH003,2023-09-28 10:00:00,1,5.0
```

**Issue:** Leading/trailing spaces in FirstName (" Benjamin ") and LastName ("Taylor ")

**What to Look For:**
- ✅ **Excellent**: Implements `.trim()` on string fields as general practice
- ✅ **Good**: Notices during data inspection and asks if whitespace should be preserved
- ⚠️ **Concerning**: Doesn't clean whitespace (will cause query issues later)
- ❌ **Red Flag**: Migration creates records with spaces that break searches

**Expected Discussion:**
- Should all text fields be trimmed?
- Is this a validation issue to log?

---

### 4. Assessment Before Student Created Date

**Location:** `legacy-assessments.csv` line 42

```csv
241,103,PROGRESS,75.0,2023-08-10 09:00:00,Assessment predates student record,COMPLETED
```

**Context:** Student 103 has `CreatedDate: 2023-08-17 11:20:00` but assessment is dated `2023-08-10`

**Issue:** Temporal impossibility - assessment taken before student existed in system

**What to Look For:**
- ✅ **Excellent**: "Assessment 241 is dated before student 103 was created - should I skip this or trust the assessment date?"
- ✅ **Good**: Implements chronological validation check
- ⚠️ **Concerning**: Migrates without questioning
- ❌ **Red Flag**: Doesn't validate temporal relationships

**Expected Discussion:**
- Could be wrong assessment date or wrong student created date
- Business decision: trust which timestamp?

---

### 5. Assessment Score Over 100

**Location:** `legacy-assessments.csv` line 43

```csv
242,107,BENCHMARK,115.5,2023-10-11 10:00:00,Extra credit or data error?,COMPLETED
```

**Issue:** Score of 115.5 exceeds typical 0-100 range

**What to Look For:**
- ✅ **Excellent**: "Assessment 242 has score 115.5 - are scores capped at 100 or can they exceed?"
- ✅ **Good**: Implements validation check for reasonable score ranges
- ⚠️ **Concerning**: Silently accepts or caps to 100 without asking
- ❌ **Red Flag**: No score validation at all

**Expected Discussion:**
- Could be valid (extra credit, percentile vs percentage)
- Could be data entry error (115.5 should be 15.5?)
- What's the valid score range for each assessment type?

---

### 6. Recent Assessment for Inactive Student

**Location:** `legacy-assessments.csv` line 44

```csv
243,124,PROGRESS,82.0,2023-10-12 11:00:00,Recent test for inactive student,COMPLETED
```

**Context:** Student 124 has `IsActive: 0` (line 26 in students.csv) but has recent assessment

**Issue:** Business logic question - should inactive students be migrated? What about their assessments?

**What to Look For:**
- ✅ **Excellent**: "Several inactive students have recent assessments - should I migrate inactive students and their data?"
- ✅ **Good**: Filters by IsActive and asks if that's correct approach
- ⚠️ **Concerning**: Migrates all students without questioning
- ❌ **Red Flag**: Filters out inactive students silently, losing data

**Expected Discussion:**
- What does "inactive" mean? Graduated? Transferred? Withdrawn?
- Should inactive students be migrated for historical reporting?

---

### 7. Negative Assessment Score

**Location:** `legacy-assessments.csv` line 45

```csv
244,111,DIBELS,-5.0,2023-10-13 09:00:00,Negative score entered,ERROR
```

**Issue:** Negative score (different from zero score on line 16, which might be valid)

**What to Look For:**
- ✅ **Excellent**: Implements validation for negative scores separately from zero
- ✅ **Good**: "Assessment 244 has negative score - is that ever valid or always an error?"
- ⚠️ **Concerning**: Treats negative same as NULL/zero without asking
- ❌ **Red Flag**: Migrates negative scores without validation

**Expected Discussion:**
- Different from score=0.0 which might mean "no score yet" or "failed"
- Negative likely always an error but worth confirming

---

## Evaluation Rubric

### AI Tool Proficiency Assessment

**Level 5 (Exceptional):**
- Finds 5+ undocumented issues through data inspection
- Asks clarifying questions BEFORE implementing solutions
- Uses AI to implement solutions AFTER getting business rules
- Demonstrates validation-first mindset

**Level 4 (Strong):**
- Finds 3-4 undocumented issues
- Implements validation logic that catches issues
- Asks some clarifying questions
- Uses AI effectively for implementation

**Level 3 (Adequate):**
- Finds 1-2 undocumented issues
- Basic validation but makes assumptions on edge cases
- Relies on AI without questioning outputs
- Migration works but may lose data or create invalid records

**Level 2 (Weak):**
- Finds 0 undocumented issues
- Blindly implements requirements without data inspection
- AI generates code but candidate doesn't validate
- Migration has bugs or data quality issues

**Level 1 (Poor):**
- Doesn't inspect data at all
- Copy-pastes AI-generated code without understanding
- No validation or error handling
- Can't explain how code handles edge cases

### Red Flags

- ❌ Doesn't inspect CSV files before coding
- ❌ Makes no data quality observations beyond documented issues
- ❌ Can't explain how their code handles duplicates, missing fields, or invalid values
- ❌ Asks AI to make business decisions ("should I skip inactive students?")
- ❌ No logging of data quality issues for review

### Green Flags

- ✅ Opens CSV files and reviews actual data early
- ✅ Takes notes on data patterns and anomalies
- ✅ Asks business rule questions before implementing
- ✅ Implements comprehensive validation with logging
- ✅ Uses AI for implementation AFTER understanding requirements
- ✅ Can explain trade-offs in their approach

## Interviewer Response Guide

When candidate asks about undocumented issues:

### Duplicate Records (StudentID 141)
**Answer:** "Good catch! Use the record with the latest CreatedDate. In production, we'd flag these for manual review, but for now just take the most recent."

### Empty FirstName
**Answer:** "Skip records with missing required fields and log them. FirstName and LastName are both required in our system."

### Whitespace
**Answer:** "Yes, trim all text fields. The legacy system didn't validate input properly."

### Assessment Before Student Created
**Answer:** "If assessment date is before student CreatedDate, trust the assessment date and adjust your logic. The CreatedDate might be when they were entered in the system, not when they enrolled."

### Score > 100
**Answer:** "Scores can exceed 100 in some assessment types that include extra credit. Keep the original value."

### Inactive Students
**Answer:** "Migrate all students regardless of IsActive status. We need historical data for reporting. IsActive just means they're not currently enrolled."

### Negative Scores
**Answer:** "Negative scores are always data errors. Skip those assessments and log them for review."

## Time Management

Given 15-minute time limit:
- Candidates likely won't find ALL issues
- Look for PROCESS (inspecting data, asking questions) over COMPLETION
- 2-3 undocumented issues found = good data inspection
- Even if candidate doesn't finish, their approach shows judgment

## Follow-up Questions

If candidate finishes early or you want to probe deeper:
- "How would you handle a CSV with 1 million rows where you can't manually inspect?"
- "What would you do differently if this were a production migration affecting 1000 schools?"
- "How did you decide what to ask me vs what to implement yourself?"
