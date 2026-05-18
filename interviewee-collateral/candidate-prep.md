# Vibe Coding Exercise - Candidate Preparation
## Senior Backend Engineer Position at Amira Learning

### Welcome! 👋

Thank you for continuing in our interview process. This document will help you prepare for your upcoming 60-minute vibe coding session.

### What is a Vibe Coding Session?

This is a collaborative coding session where you'll work through real-world challenges similar to those you'd encounter at Amira. Unlike traditional coding interviews:

- **You're encouraged to use AI coding tools** (Cursor, Claude Code, GitHub Copilot, etc.)
- **We care about your process** as much as your output
- **Ambiguity is intentional** - we want to see how you handle uncertainty
- **Speed and pragmatism matter** - perfect is the enemy of shipped
- **Time is limited** - 60 minutes goes quickly!

### What to Prepare

#### Technical Setup
- [ ] Your preferred development environment (ready to code immediately)
- [ ] Your AI coding assistant of choice (and any backup options)
- [ ] Node.js, Python, or .NET Core environment (your choice)
- [ ] **AWS CLI** installed and ready to use (for accessing AWS resources)
- [ ] **PostgreSQL client** (psql) for database access
- [ ] **curl** for API testing (usually pre-installed)
- [ ] Any personal productivity tools you normally use

#### Quick Installation Guide
**AWS CLI:**
```bash
# macOS
brew install awscli

# Ubuntu/Debian
sudo apt update && sudo apt install -y curl unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Optional: Disable pager if you get pager errors
export AWS_PAGER=""

# Windows
# Download installer from: https://awscli.amazonaws.com/AWSCLIV2.msi
```

**PostgreSQL Client:**
```bash
# macOS
brew install postgresql

# Ubuntu/Debian
sudo apt install postgresql-client

# Windows
# Download from: https://www.postgresql.org/download/windows/
```

#### Mental Preparation
- Review AWS services: Lambda, DynamoDB, AppSync, S3
- Brush up on SQL query optimization
- Think about debugging strategies for production issues
- Consider how you validate AI-generated code
- **Practice working under time constraints**

### What We'll Provide

- AWS sandbox environment credentials (valid for 12 hours)
- Sample database schemas and test data
- API documentation
- Challenge descriptions during the interview session
- Screen sharing for challenge materials

### Session Structure (60 Minutes)

1. **Setup & Introduction (5 min)**
   - Quick environment setup
   - Brief discussion about your AI tool workflow

2. **Challenge A: Data Migration (~22 min)**
   - One real-world backend challenge: migrate legacy SQL data to DynamoDB
   - Includes intentional data quality issues you'll need to identify and handle
   - Challenge will be provided during the session via the Sample Data API

3. **AI Output Review (~3 min)**
   - You'll review a short AI-generated script and give your assessment
   - Tests whether you validate AI output before shipping it

4. **Optional Quick Task (~3 min, if time permits)**
   - A focused DynamoDB bug fix if we have time

5. **Wrap-up & Discussion (remaining time)**
   - Discussion of your approach and decisions
   - Questions about your AI tool workflow

### What We're Evaluating

- **AI Tool Proficiency**: How effectively you leverage AI assistants
- **Problem Solving**: Your approach to debugging and optimization
- **Code Quality**: Balance between speed and maintainability
- **Communication**: How you explain your thinking
- **Time Management**: Working efficiently under constraints

### Tips for Success in 60 Minutes

✅ **DO:**
- Start coding quickly - analysis paralysis is your enemy
- Use AI aggressively — for implementation, not just boilerplate
- Think out loud - we want to understand your process
- Make pragmatic trade-offs and explain them
- Focus on working solutions over perfect ones
- Ask for clarification if requirements are unclear
- Own every business decision and validate every AI output

❌ **DON'T:**
- Spend too long reading requirements
- Try to make everything perfect
- Blindly copy AI suggestions without understanding
- Let AI make critical business or architecture decisions
- Forget about error handling completely
- Over-engineer simple problems
- Be afraid to ask questions if stuck
