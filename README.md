# Amira Learning - Backend Engineer Vibe Coding Exercise
## AI-Powered Development Interview (60 Minutes)

> **Complete AWS-based interview environment with automated deployment and candidate material generation**

## 🚀 Quick Start for Interviewers

### **Complete Interview Workflow:**

```bash
# 0️⃣ PRE-INTERVIEW (24 hours before)
make prep-email                     # Send candidate-prep.md

# 1️⃣ SETUP & PREPARE (One-time setup)
make setup                          # Validate tools & AWS credentials
make status                         # Check AWS account & existing stacks

# 2️⃣ DEPLOY ENVIRONMENT (Day of interview)
make deploy CANDIDATE=jane-smith    # Deploy AWS infrastructure
make verify CANDIDATE=jane-smith    # Verify resources & sample data

# 3️⃣ GENERATE MATERIALS (Send to candidate)
make credentials CANDIDATE=jane-smith  # Generate email + zip challenges

# 4️⃣ INTERVIEW SESSION
make reset CANDIDATE=next-candidate    # Quick reset between interviews (1-2 min)

# 5️⃣ CLEANUP (After interview)
make cleanup CANDIDATE=jane-smith      # Delete all AWS resources
```

### **What Gets Automatically Created:**
- ☁️ **AWS Infrastructure**: DynamoDB, Lambda, RDS PostgreSQL, Redis
- 🔐 **Temporary AWS credentials** (12-hour expiration)
- 📧 **Complete email** with setup instructions
- 📦 **Challenge package** with source code and docs
- 🐛 **Sample data with intentional bugs** for debugging challenges

---

## ⏱️ Session Timeline (60 minutes)

| Time | Activity | Priority | Focus |
|------|----------|----------|-------|
| 0-5 min | Setup & Introduction | ⭐ Required | AWS access verification |
| 5-27 min | Challenge A: Migration | ⭐ Required | Data quality judgment, AI implementation |
| 27-30 min | Task 5: AI Output Review | ⭐ Required | Spotting planted bugs in AI-generated code |
| 30-33 min | Task 2: BatchGetItem Bug | ⚡ If time permits | DynamoDB UnprocessedItems handling |
| 33-60 min | Wrap-up & Probing | ⭐ Required | AI tool reflection, candidate profiling |

## 🎯 Interview Focus: Agentic AI Development

This interview evaluates **strategic AI usage** - how candidates work with AI tools to amplify their engineering capabilities.

### **✅ Expected AI Usage:**
- **Code generation & boilerplate** (should be fast!)
- **API documentation & examples**
- **Error analysis & debugging assistance**
- **Implementation details & syntax**

### **🎯 What We're Evaluating:**
- **Problem decomposition** - How they break down complex problems
- **Strategic prompting** - How effectively they direct AI tools
- **Architecture decisions** - Their technical judgment
- **Debugging methodology** - Their systematic approach
- **Code review skills** - Spotting issues and improvements

---

## 📁 Repository Structure

```
backend-engineer-vibe-exercise/
├── Makefile                        # 🎯 Complete interview workflow automation
├── README.md                       # This file
├── .gitignore                      # Prevents committing generated files
│
├── challenges/                     # 📚 Challenge files for candidates
│   ├── challenge-a-migration.md    # ⭐ Legacy data migration (22 min)
│   ├── challenge-b-debugging.md    # ⭐ C++/.NET memory leak (optional)
│   ├── challenge-b-alternative.md  # ⭐ Node.js memory leak (optional)
│   ├── challenge-c-optimization.md # ⚡ Performance optimization (optional)
│   └── rapid-fire-tasks.md         # ⚡ Quick adaptation tasks (5-10 min)
│
├── interviewer-guide.md            # 📋 Complete interviewer reference + solutions
├── comprehensive-scoring-rubric.md # 🎯 AI usage evaluation criteria
│
├── aws-setup/                      # ☁️ AWS infrastructure & deployment
│   ├── deploy-interview.sh         # Deploys CloudFormation + populates data
│   ├── reset-interview.sh          # Quick reset between interviews (1-2 min)
│   ├── verify-interview-environment.sh # Tests all resources
│   ├── cleanup-interview.sh        # Removes all AWS resources
│   └── interview-stack.yaml        # Complete infrastructure definition
│
├── interviewee-collateral/         # 📧 Materials for candidates
│   ├── candidate-prep.md           # Pre-interview setup (send 24hrs before)
│   └── generate-credentials-email.sh # Creates email + challenge zip
│
├── post-interview/                 # 📊 Evaluation templates
└── solutions/                      # 🔒 Reference solutions (DO NOT SHARE)
```

---

## 🎯 Challenge Overview

### **⭐ Challenge A: Legacy Data Migration (22 min) — Always Run**
Transform legacy SQL data to DynamoDB, handling real data quality issues.
- **Skills**: Data quality judgment, transformation logic, batch processing, error handling
- **AWS**: DynamoDB, PostgreSQL with intentional data problems
- **Key signal**: Do they find the traps, or do they blindly migrate bad data?

### **⭐ Task 5: AI Output Review (3 min) — Always Run**
Candidate reviews an AI-generated migration script with 3 planted bugs.
- **Bugs**: BATCH_SIZE=26 (violates DynamoDB 25-item limit), UnprocessedItems not checked, DIBELS mapped to PROGRESS_MONITORING instead of BENCHMARK
- **Key signal**: Do they catch the bugs, or do they ship the AI output uncritically?

### **⚡ Task 2: BatchGetItem Bug (3 min) — Optional**
Fix a DynamoDB BatchGetItem that silently drops items (UnprocessedItems not retried).
- **Run if**: Time permits after Task 5 and candidate is moving well

### **Backup Challenges (rarely used)**
- **Challenge B**: Memory leak debugging (C++/.NET or Node.js)
- **Challenge C**: Performance optimization (PostgreSQL + Redis)
- **Other rapid fire**: Rate Limiting, Recursive CTE, Monitoring

---

## 💡 Interviewer Tips

### **🎯 60-Minute Prioritization:**
- **MUST DO**: Setup (5) + Challenge A (22) + Task 5 AI Review (3) + Wrap-up (rest) = 60 min
- **IF TIME**: Task 2 BatchGetItem bug (3 min) before wrap-up

### **⚡ Quick Reset Between Interviews:**
For multiple interviews in one day, use `make reset CANDIDATE=next-name` instead of full rebuild:
- **Time**: 1-2 minutes vs 20+ minutes
- **Preserves**: All AWS infrastructure
- **Resets**: All data, Lambda code, credentials
- **Use when**: Same interviewer, same day, different candidates

### **📊 What to Observe:**
1. **AI Interaction Style**: Do they prompt effectively or just copy/paste?
2. **Problem Approach**: Do they analyze first or jump straight to coding?
3. **Error Handling**: How do they debug when things don't work?
4. **Code Review**: Can they spot issues in their own or provided code?
5. **Context Switching**: How do they adapt to rapid fire tasks?
6. **Time Management**: Do they focus on high-impact changes?

### **🚨 Red Flags:**
- Asking AI to solve the entire problem without understanding
- Not testing their solutions
- Ignoring error messages or warnings
- Unable to explain their code choices

### **✅ Green Flags:**
- Using AI for boilerplate while making architectural decisions themselves
- Iterating and improving solutions based on results
- Asking clarifying questions about requirements
- Demonstrating systematic debugging approach
- Quick adaptation during rapid fire challenges
- Efficient context switching between different problem types

---

## 🛠️ Technical Requirements

### **Prerequisites:**
- AWS CLI configured with appropriate permissions (account: 455737799003)
- Tools: `jq`, `psql`, `python3`, `zip`
- GitHub access to this repository

### **AWS Resources Created:**
- **CloudFormation Stack** with all resources
- **DynamoDB Tables**: Students, Assessments, Classes, Schools
- **Lambda Function**: Buggy API with memory leaks
- **RDS PostgreSQL**: Sample data with intentional quality issues
- **ElastiCache Redis**: Available for Lambda functions
- **VPC + Security Groups**: Proper network isolation

### **⚠️ Troubleshooting:**

**If CloudFormation stack gets stuck in DELETE_FAILED:**
```bash
# Emergency force cleanup (use only when normal cleanup fails)
make force-cleanup CANDIDATE=candidate-name

# Or directly:
cd aws-setup && ./force-cleanup.sh candidate-name interview-id
```

**Common issues:**
- **S3 buckets not empty**: Force cleanup script empties buckets before deletion
- **VPC deletion timeout**: Script proactively detaches Internet Gateway
- **Resource dependencies**: Script deletes resources in proper order

### **Costs:**
- **ElastiCache**: ~$0.02/hour
- **RDS**: Free tier eligible
- **Lambda/DynamoDB**: Free tier
- **Auto-cleanup**: Stack deletes after 24 hours (lifecycle policy)

---

## 📞 Support

### **For Technical Issues:**
- `make help` - See all available commands
- `make status` - Check AWS account and active stacks
- Slack: #interview-support

### **For Interview Questions:**
- **Complete guidance**: `interviewer-guide.md` (session management, solutions, rapid fire)
- **AI evaluation**: `comprehensive-scoring-rubric.md` (what to watch for, red flags)
- **Quick reset**: `QUICK_RESET_GUIDE.md` (multiple interviews per day)

---

## 🎉 Success Metrics

A successful interview demonstrates:
- **Strategic AI usage** that amplifies rather than replaces engineering skills
- **Systematic problem-solving** approach to debugging and optimization
- **Production mindset** with proper error handling and edge case consideration
- **Startup agility** through rapid context switching and efficient task completion
- **Clear communication** about technical decisions and trade-offs

---

*🤖 Generated with [Claude Code](https://claude.ai/code) - Complete automated interview environment*