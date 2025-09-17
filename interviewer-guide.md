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
- [ ] Slack #interview-support monitored
- [ ] **Set timers for each section**
- [ ] **Verify infrastructure readiness (see Data Verification Checklist below)**

### 🔗 Getting Challenge URLs

**✅ URLs are displayed when you run `make credentials CANDIDATE=name`**

The command outputs ready-to-copy challenge URLs like this:
```bash
🔗 CHALLENGE URLs FOR INTERVIEWER (save these for interview):

Base API: https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod

📋 Copy/paste these during interview:
Challenge A: curl "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod?file=challenge-a-migration.md"
Challenge B (C++/.NET): curl "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod?file=challenge-b-debugging.md"
...
```

**📋 During Interview - Just copy/paste the exact curl commands shown above to candidates**

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
  # Example URL: https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod
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

## Part 3: Rapid Fire Challenges (5-10 minutes)

**Present Challenges via:**
- **RECOMMENDED:** Copy/paste the Rapid Fire curl command from `make credentials` output
- **Alternative:** Screen share challenges/ directory if API is unavailable
- **Backup:** Copy/paste individual tasks into chat during interview

### If time permits, present 2-3 quick tasks:

1. **Rate Limiting (2 min):** "Add rate limiting to this Lambda"
2. **BatchGetItem Fix (2 min):** "Fix the missing items issue"
3. **Memory Leak (2 min):** "Spot the memory leak in this cache"
4. **Recursive CTE (3 min):** "Convert this SQL to application code"
5. **Monitoring (2 min):** "Add CloudWatch metrics"

**Focus on:** Speed, pattern recognition, and efficient context switching

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
