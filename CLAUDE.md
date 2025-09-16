# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **60-minute vibe coding exercise framework** for evaluating Senior Backend Engineers at Amira Learning. The core innovation is evaluating **AI tool proficiency** alongside technical skills, specifically testing when candidates should and should NOT use AI tools.

## Key Architecture Components

### Interview Framework Structure
```
vibe-coding-exercise/
├── CONTEXT-FOR-CLAUDE-CODE.md     # Start here - comprehensive overview
├── README.md                      # Quick start guide for interviewers
├── interviewer-guide.md           # Detailed session management (60-min timeboxing)
├── comprehensive-scoring-rubric.md # AI usage evaluation (core innovation)
├── QUICK_REFERENCE.md            # Day-of interview checklist
├── challenges/                   # 3 main + rapid fire challenges
├── solutions/                    # Reference implementations (DO NOT SHARE)
├── sample-data/                  # Test schemas, APIs, and data
└── post-interview/              # Evaluation templates and debrief
```

### Challenge Architecture

The framework has **3 core challenges** designed to test different AI usage patterns:

1. **Challenge A (Migration)** - Tests business logic decisions that should NOT use AI
   - Legacy SQL Server → DynamoDB migration
   - Data quality issues (negative reading levels, invalid grades)
   - Business rules must be human-decided, implementation can use AI

2. **Challenge B (Debugging)** - Tests root cause analysis without AI dependency
   - Two versions: C++/.NET memory leaks OR Node.js/Python alternatives
   - Must identify singleton/connection pooling issues independently
   - AI acceptable for fix implementation only

3. **Challenge C (Optimization)** - Tests architectural decision-making
   - Performance bottlenecks in recursive CTEs
   - Caching strategy decisions
   - Must choose optimization approach before using AI

### Scoring Framework Architecture

**Multi-dimensional evaluation (5-point scale per category):**
- **AI Tool Proficiency (25%)** - Core differentiator
- **Technical Execution (25%)** - Code quality and implementation
- **Problem-Solving (20%)** - Root cause analysis and debugging
- **Startup Fitness (15%)** - Speed, ambiguity handling, self-direction
- **Domain Understanding (15%)** - EdTech context and Amira-specific knowledge

### Time Management Architecture

**60-minute strict timeboxing:**
- Setup (5 min) → 2 Main Challenges (30 min) → Rapid Fire/Third (10 min) → Wrap-up (5 min)
- **⭐ PRIORITY:** Two main challenges must be completed
- **⚡ OPTIONAL:** Third challenge or rapid fire tasks
- Built-in flexibility for candidate skill level adjustment

## Commands and Usage

### Quick Start
```bash
# Initialize session context
./start-claude-code.sh

# Core files to review first
cat CONTEXT-FOR-CLAUDE-CODE.md
cat comprehensive-scoring-rubric.md
```

### Document Generation
When creating new challenges or improvements:
- Follow the markdown pattern in `challenges/` directory
- Include timing guidance (⭐ required vs ⚡ optional)
- Specify AI usage boundaries clearly
- Provide sample data in `sample-data/` if needed

### Evaluation Tools
- Use `comprehensive-scoring-rubric.md` for AI proficiency evaluation
- Reference `post-interview/evaluation-template.md` for structured feedback
- Check `QUICK_REFERENCE.md` for day-of execution

## AI Usage Evaluation Patterns

### Critical: When Candidates Should NOT Use AI
- **Root Cause Analysis** - Must debug memory leaks/performance issues independently
- **Business Logic Decisions** - Data quality rules, conflict resolution priorities
- **Security Decisions** - Authentication, credential handling
- **Architectural Strategy** - Performance optimization approach, caching decisions

### Acceptable AI Usage
- **Implementation Details** - Connection pooling code, error handling patterns
- **Syntax Help** - AWS SDK usage, database query syntax
- **Boilerplate Generation** - Migration scripts, batch processing templates
- **Research** - Best practices for specific technologies

### Red Flags in AI Usage
- Cannot explain AI-generated code
- Asks AI to make business decisions
- No validation of critical code paths
- Copy-pastes without understanding
- Cannot debug without AI assistance

## Domain Context

**Amira Learning Scale:** 3.5M students, K-5 reading assessment platform
**Technical Context:** AWS Lambda, DynamoDB, PostgreSQL, GraphQL, Node.js/Python
**Education Domain:** BOY/MOY/EOY assessment windows, grade progression, COPPA compliance
**Assessment Types:** BENCHMARK > PROGRESS_MONITORING > INSTRUCT (hierarchy matters)

## Working with This Framework

### When Creating New Challenges
1. Define clear AI usage boundaries upfront
2. Include both technical and domain-specific elements
3. Provide time estimates for 60-minute format
4. Test with actual candidates before production use

### When Modifying Existing Challenges
- Maintain the AI evaluation focus
- Keep domain context (Amira education platform)
- Preserve time constraints and priority markings
- Update scoring rubric if evaluation criteria change

### When Analyzing Results
- Focus on AI tool proficiency as primary differentiator
- Look for process over completion due to time constraints
- Use the 5-dimensional scoring matrix consistently
- Document specific examples of AI usage patterns observed

## Important Files for AI Context

- `sample-data/schemas.sql` - Production PostgreSQL schema + legacy migration context
- `sample-data/graphql-schema.graphql` - Current API structure
- `AI_USAGE_RED_FLAGS.md` - Specific anti-patterns to watch for
- `CHALLENGE_B_SELECTION.md` - Guidelines for choosing debugging version based on candidate background

This framework is specifically designed to identify senior engineers who can effectively collaborate with AI tools without becoming dependent on them for critical thinking and decision-making.