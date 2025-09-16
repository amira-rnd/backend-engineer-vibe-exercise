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

# 4️⃣ INTERVIEW SESSION (Optional testing)
make test-candidate CANDIDATE=jane-smith  # Test candidate access

# 5️⃣ CLEANUP (After interview)
make cleanup CANDIDATE=jane-smith   # Delete all AWS resources
```

### **What Gets Automatically Created:**
- ☁️ **AWS Infrastructure**: DynamoDB, Lambda, RDS PostgreSQL, Redis
- 🔐 **Temporary AWS credentials** (4-hour expiration)
- 📧 **Complete email** with setup instructions
- 📦 **Challenge package** with source code and docs
- 🐛 **Sample data with intentional bugs** for debugging challenges

---

## ⏱️ Session Timeline (60 minutes)

| Time | Activity | Priority | Focus |
|------|----------|----------|-------|
| 0-5 min | Setup & Introduction | ⭐ Required | AWS access verification |
| 5-20 min | Challenge A: Migration | ⭐ PRIORITIZE | AI prompting, data quality |
| 20-35 min | Challenge B: Debugging | ⭐ PRIORITIZE | Memory leak analysis |
| 35-50 min | Challenge C: Performance | ⚡ If moving fast | Query optimization |
| 50-55 min | Discussion | ⭐ Required | Architecture decisions |
| 55-60 min | Wrap-up | ⭐ Required | AI tool reflection |

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
├── challenges/                     # 📚 Source of truth for all challenges
│   ├── challenge-a-migration.md    # ⭐ Legacy data migration (15 min)
│   ├── challenge-b-debugging.md    # ⭐ C++/.NET memory leak (15 min)
│   ├── challenge-b-alternative.md  # ⭐ Node.js memory leak (15 min)
│   └── challenge-c-optimization.md # ⚡ Performance optimization (15 min)
│
├── aws-setup/                      # ☁️ AWS infrastructure & deployment
│   ├── deploy-interview.sh         # Deploys CloudFormation + populates data
│   ├── verify-interview-environment.sh # Tests all resources
│   ├── cleanup-interview.sh        # Removes all AWS resources
│   └── interview-stack.yaml        # Complete infrastructure definition
│
├── interviewee-collateral/         # 📧 Materials for candidates
│   ├── candidate-prep.md           # Pre-interview setup (send 24hrs before)
│   ├── generate-credentials-email.sh # Creates email + challenge zip
│   └── send-to-candidate/          # 🤖 Auto-generated (email + challenges.zip)
│
└── solutions/                      # 🔒 Reference solutions (DO NOT SHARE)
```

---

## 🎯 Challenge Overview

### **⭐ Challenge A: Legacy Data Migration (PRIORITY - 15 min)**
Transform legacy SQL data to DynamoDB, handling data quality issues.
- **Skills**: Data transformation, error handling, batch processing
- **AWS**: DynamoDB, PostgreSQL with intentional data problems

### **⭐ Challenge B: Memory Leak Debugging (PRIORITY - 15 min)**
**Choose based on candidate background:**
- **Option 1**: C++/.NET Lambda memory leak (advanced)
- **Option 2**: Node.js service memory leak (standard)
- **Skills**: Debugging methodology, resource management, performance analysis
- **AWS**: Lambda function with subtle memory leaks, CloudWatch logs

### **⚡ Challenge C: Performance Optimization (OPTIONAL - 15 min)**
**Only if candidate is moving quickly through A & B**
- Optimize slow database queries and application logic
- **Skills**: Query optimization, caching strategies, algorithmic thinking
- **AWS**: PostgreSQL, Redis cache, complex data hierarchies

---

## 💡 Interviewer Tips

### **🎯 60-Minute Prioritization:**
- **MUST DO**: Setup (5) + Challenge A (15) + Challenge B (15) + Discussion (10) + Wrap-up (5) = 50 min
- **IF TIME**: Challenge C (15 min) or extended discussion

### **📊 What to Observe:**
1. **AI Interaction Style**: Do they prompt effectively or just copy/paste?
2. **Problem Approach**: Do they analyze first or jump straight to coding?
3. **Error Handling**: How do they debug when things don't work?
4. **Code Review**: Can they spot issues in their own or provided code?
5. **Time Management**: Do they focus on high-impact changes?

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
- Follow `interviewer-guide.md` for detailed session management
- Use scoring rubrics in `comprehensive-scoring-rubric.md`

---

## 🎉 Success Metrics

A successful interview demonstrates:
- **Strategic AI usage** that amplifies rather than replaces engineering skills
- **Systematic problem-solving** approach to debugging and optimization
- **Production mindset** with proper error handling and edge case consideration
- **Clear communication** about technical decisions and trade-offs

---

*🤖 Generated with [Claude Code](https://claude.ai/code) - Complete automated interview environment*