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

- [ ] Run `make deploy CANDIDATE=their-name` to create AWS environment
- [ ] Run `make verify CANDIDATE=their-name` to test all resources
- [ ] Run `make credentials CANDIDATE=their-name` to generate materials
- [ ] Candidate received prep materials 24 hours ago (via `make prep-email`)
- [ ] **Choose 2 main challenges based on candidate background**
- [ ] Screen recording software ready (with consent)
- [ ] **CRITICAL: Review comprehensive-scoring-rubric.md for AI usage evaluation**
- [ ] Scoring rubric printed/open
- [ ] Slack #interview-support monitored
- [ ] **Set timers for each section**
- [ ] **Verify infrastructure readiness (see Data Verification Checklist below)**

### 📋 Data Verification Checklist

**Before starting the interview, verify:**

- [ ] **CloudFormation Stack**: Status is CREATE_COMPLETE
- [ ] **PostgreSQL Data**: Tables created and populated with sample data
  ```bash
  psql -h [DB_ENDPOINT] -U postgres -d postgres -c "SELECT COUNT(*) FROM students;"
  # Should return > 0 rows
  ```
- [ ] **DynamoDB Data**: Sample students exist
  ```bash
  aws dynamodb scan --table-name [STUDENTS_TABLE] --limit 1
  # Should return student records
  ```
- [ ] **Sample Data API**: Accessible and serving files
  ```bash
  curl "[SAMPLE_DATA_URL]"
  # Should return JSON with available files
  ```
- [ ] **Lambda Function**: Deployed and accessible
  ```bash
  aws lambda get-function --function-name [LAMBDA_NAME]
  # Should return function details
  ```

**If any checks fail:**
- Re-run deploy script: `./deploy-interview.sh [candidate-name] [interview-id]`
- Check AWS console for CloudFormation stack errors
- Verify credentials generation script passes all validations

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

**Setup Statement:**
```
"You have 15 minutes to migrate student assessment data from our legacy system to DynamoDB.
The legacy system has data quality issues. Focus on handling the most critical issues first.
You can access schemas and sample data via the API provided in your credentials email - look for the 'Sample Data & Schema API' section."
```

**Time Management:**
- 2 min: Understanding the problem
- 10 min: Implementation
- 3 min: Quick test/validation

**Early Hints (if stuck after 7 min):**
- "Focus on grade normalization and invalid data first"
- "Don't worry about perfect error handling"

### Challenge B: API Debugging (15 minutes if selected)

**FIRST: Check background for version selection**
- C++/.NET experience → Use challenge-b-debugging.md
- Otherwise → Use challenge-b-alternative.md

**Setup Statement:**
```
"You have 15 minutes to identify and fix memory leaks in this service.
It crashes under load. Focus on finding the main causes."
```

**Time Management:**
- 3 min: Analyze symptoms
- 10 min: Identify and fix main issues
- 2 min: Explain approach

### Challenge C: Performance Optimization (15 minutes if selected)
⚡ **Only use if candidate is moving very quickly**

**Setup Statement:**
```
"You have 15 minutes to optimize this conflict resolution system.
Focus on the biggest performance wins first."
```

## Part 3: Rapid Fire Challenges (5-10 minutes)

### If time permits, present 2-3 quick tasks:

1. **Rate Limiting (2 min):** "Add rate limiting to this Lambda"
2. **BatchGetItem Fix (2 min):** "Fix the missing items issue"
3. **Memory Leak (2 min):** "Spot the memory leak in this cache"

**Focus on:** Speed and correct pattern identification

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

### ✅ Adjusted Green Flags for 60 Minutes

- Completes both main challenges
- Quick to identify problems
- Efficient AI usage
- Makes pragmatic trade-offs for speed
- Clear communication despite time pressure
