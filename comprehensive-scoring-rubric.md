# Comprehensive Scoring Rubric - Vibe Coding Exercise (60-Minute Version)
## Senior Backend Engineer - AI Usage & Technical Evaluation

### 🎯 Core Principle: AI Should Amplify, Not Replace, Critical Thinking
### ⏰ Note: Adjusted expectations for 60-minute format

---

## 🚫 Areas Where Candidates Should NOT Use AI

### Critical Decision Points (Automatic Red Flags if AI-Dependent)

#### 1. Root Cause Analysis
**Challenge B - Memory Leak Debugging**
- ❌ **Wrong:** "AI, fix this memory leak in my Lambda function"
- ✅ **Right:** Analyze the singleton pattern issue first, then: "How do I properly dispose edge.js connections?"
- **Evaluator Note:** Candidate must identify the connection array issue themselves

#### 2. Business Logic & Domain Rules  
**Challenge C - Conflict Resolution**
- ❌ **Wrong:** "AI, implement assessment conflict resolution for education"
- ✅ **Right:** Understand BENCHMARK > PROGRESS_MONITORING > INSTRUCT hierarchy, then use AI for implementation
- **Evaluator Note:** Must grasp Amira-specific rules before coding

#### 3. Data Quality Decisions
**Challenge A - Migration**
- ❌ **Wrong:** "AI, handle these data quality issues"
- ✅ **Right:** Decide that negative reading levels default to grade-0.5, then implement
- **Evaluator Note:** Business impact understanding required

#### 4. Security & Authentication
- **Never:** Use AI-generated credentials or secrets
- **Never:** Accept AI auth implementations without validation
- **Always:** Manually verify security-critical code

#### 5. Performance Strategy
- ❌ **Wrong:** "Make this query faster"
- ✅ **Right:** "I need to eliminate the recursive CTE using window functions"
- **Evaluator Note:** Strategy is human decision, implementation can use AI

---

## 📊 Detailed AI Proficiency Scoring (25% of total)

### 5 - Exceptional AI Usage
**Demonstrates Mastery of AI as a Tool**
- Makes all critical decisions independently
- Uses sophisticated, iterative prompting
- Catches and corrects AI mistakes
- Validates every critical path manually
- Explains AI limitations clearly
- Uses AI for research and exploration effectively

**Example Behaviors:**
- "Let me understand this SIGSEGV first... okay, now I'll use AI to implement the connection pooling"
- Rewrites AI suggestions that don't match requirements
- Tests AI-generated code before trusting it

### 4 - Strong AI Usage
**Effective Balance**
- Generally makes decisions before using AI
- Good prompting techniques
- Validates important outputs
- Knows when not to use AI
- Can explain all generated code

**Example Behaviors:**
- Asks clarifying questions before prompting AI
- Reviews AI code for logic errors
- Uses AI mainly for boilerplate and syntax

### 3 - Acceptable AI Usage
**Basic Competence**
- Sometimes over-relies on AI
- Basic validation of output
- Can explain most generated code
- Occasionally lets AI make decisions

**Example Behaviors:**
- Uses AI for entire functions without deep review
- Generally understands output but misses edge cases

### 2 - Below Expectations
**Over-Dependent**
- Relies on AI for problem-solving
- Limited validation
- Struggles to explain AI code
- Lets AI make architectural decisions

**Red Flags:**
- "Let me ask AI what's wrong here"
- Cannot debug AI-generated code
- Accepts first AI suggestion without iteration

### 1 - Unacceptable
**Cannot Function Without AI**
- Blindly copies AI output
- No validation process
- Cannot explain solutions
- AI usage hinders progress

**Critical Failures:**
- Copy-pastes without understanding
- Cannot proceed when AI gives wrong answer
- No debugging ability

---

## 🎯 Challenge-Specific AI Evaluation (60-Minute Adjusted)

### Challenge A: Data Migration (15 min)

#### What They Should NOT Use AI For:
- Deciding how to handle invalid reading levels
- Determining grade mapping rules
- Understanding business impact

#### Acceptable AI Usage:
- BatchWriteItem implementation
- UUID generation code
- Basic retry logic

#### 60-Min Scoring Guide:
- **5 pts:** Handles critical issues, uses AI efficiently
- **3 pts:** Basic migration works with some AI help
- **1 pt:** Over-relies on AI or makes no progress

### Challenge B: Memory Leak Debugging (15 min)

#### Original Version (C++/.NET Interop)
**What They Should NOT Use AI For (Root Cause Analysis):**
- Relying solely on AI for systematic analysis across 6 modules
- Using only AI to identify memory leak sources (should find 10+ total)
- Letting AI explain SIGSEGV in Edge.js/.NET context without manual investigation
- Having AI decide architectural solutions (cache eviction strategies)

**What's Acceptable (AI-First with Manual Validation):**
- Using AI to scan for memory leak patterns, then systematically validating findings
- Getting initial AI suggestions, then analyzing each module manually
- Identifying additional leak sources beyond what AI suggested

#### Alternative Version (Node.js/Python/Java)
**What They Should NOT Use AI For (Root Cause Analysis):**
- Relying solely on AI to identify all memory leak sources
- Using only AI to understand heap exhaustion patterns
- Having AI decide cache eviction strategy without analysis

**What's Acceptable (AI-First with Manual Validation):**
- Using AI to scan for common patterns, then manually verifying each
- Getting AI suggestions for leak types, then systematically investigating
- Identifying issues AI missed through manual code review

#### Acceptable AI Usage (Both Versions):
- Connection cleanup implementation patterns
- Cache eviction algorithm syntax
- Event listener removal code
- Error handling boilerplate
- AWS SDK syntax
- Specific .NET disposal patterns (after identifying the need)

#### Scoring Guide (Updated for Enhanced Complexity):
- **5 pts:** Systematic multi-module analysis, finds 6+ leaks, strategic AI usage (AI-first then validation)
- **4 pts:** Traces through most modules, finds 4-5 leaks, good AI-first approach with analysis
- **3 pts:** Identifies some key issues, uses AI for discovery but validates findings
- **2 pts:** Basic issue recognition, relies heavily on AI but shows some independent thinking
- **1 pt:** Cannot function without AI, only uses AI findings without validation or understanding

### Challenge C: Performance Optimization (25 min)

#### What They Should NOT Use AI For:
- Analyzing why recursive CTE is slow
- Choosing optimization strategy
- Deciding on caching approach
- Understanding conflict resolution rules

#### Acceptable AI Usage:
- Window function syntax
- Redis implementation
- Batch processing code
- Query rewriting assistance

#### Scoring Guide:
- **5 pts:** Designs solution, uses AI for syntax
- **3 pts:** Some AI assistance in strategy
- **1 pt:** Asks AI to optimize without understanding

### Rapid Fire Tasks

#### Task-Specific Evaluation:
**Rate Limiting:** Should decide on algorithm (sliding window vs token bucket) before AI
**BatchGetItem:** Must understand 100-item limit and UnprocessedKeys themselves
**Memory Leak:** Should identify unbounded cache before asking for LRU help
**Monitoring:** Should know what metrics matter before implementation

---

## 🔍 Interview Probing Questions

### After Each Challenge, Ask:
1. "Why did you choose not to use AI for [specific decision]?"
2. "How did you validate that AI suggestion?"
3. "What could go wrong with the AI's approach?"
4. "Walk me through a part where you deliberately avoided AI"

### Red Flag Responses:
- "I always trust AI for these things"
- "I didn't think to validate it"
- "AI knows better than me"
- Cannot explain their code

### Green Flag Responses:
- "I wanted to understand the problem first"
- "AI's suggestion didn't account for our specific case"
- "I tested three approaches before choosing"
- "The AI missed this edge case"

---

## 📈 Technical Execution Scoring (25% of total)

### Beyond AI: Core Engineering Skills

#### 5 - Exceptional
- Production-ready code despite time pressure
- Comprehensive error handling
- Performance optimizations included
- Security considerations addressed
- Clean architecture
- Tests critical paths

#### 4 - Strong  
- Good code quality
- Solid error handling
- Some optimizations
- Generally secure
- Readable and maintainable

#### 3 - Acceptable
- Working solutions
- Basic error handling
- Functional but not optimal
- Some rough edges
- Minimal security issues

#### 2 - Below Expectations
- Buggy implementations
- Poor error handling
- Inefficient solutions
- Security vulnerabilities
- Hard to maintain

#### 1 - Unacceptable
- Non-functional code
- No error handling
- Major bugs
- Unsafe practices
- Unreadable

---

## 🎓 Amira Domain-Specific Evaluation (15% of total)

### Critical Domain Understanding (Cannot Use AI)

#### Education Context
- **Must Understand:** BOY/MOY/EOY assessment windows
- **Must Understand:** Grade progression logic
- **Must Understand:** Teacher workflow implications
- **Must Understand:** Student privacy (COPPA)

#### Technical Context  
- **Must Understand:** Legacy system constraints
- **Must Understand:** Assessment hierarchy
- **Must Understand:** Conflict resolution priorities
- **Must Understand:** Scale (3.5M students)

### Scoring:
- **5 pts:** Shows deep EdTech understanding
- **4 pts:** Asks good domain questions
- **3 pts:** Basic domain grasp
- **2 pts:** Little domain interest
- **1 pt:** Ignores context completely

---

## 🚀 Startup Fitness Evaluation (15% of total)

### Ambiguity Handling
Watch how they react to incomplete requirements:
- **5 pts:** Thrives, makes reasonable assumptions
- **3 pts:** Some discomfort but proceeds
- **1 pt:** Paralyzed without complete specs

### Speed vs Quality Balance
- **5 pts:** Ships fast without sacrificing critical quality
- **3 pts:** Reasonable balance
- **1 pt:** Too slow (perfectionist) or too sloppy

### Self-Direction
- **5 pts:** Completely self-directed
- **3 pts:** Needs occasional guidance
- **1 pt:** Requires constant direction

---

## 📋 Final Scoring Matrix

| Category | Weight | Key Evaluation Points | Score |
|----------|--------|----------------------|-------|
| **AI Tool Proficiency** | 25% | Knows when NOT to use AI, validates output, iterative prompting | /5 |
| **Technical Execution** | 25% | Code quality, error handling, performance, security | /5 |
| **Problem-Solving** | 20% | Root cause analysis, debugging methodology, trade-offs | /5 |
| **Startup Fitness** | 15% | Ambiguity handling, speed, self-direction | /5 |
| **Domain Understanding** | 15% | EdTech awareness, Amira context, user empathy | /5 |

### Overall Score Interpretation
- **4.5-5.0:** Exceptional - Strong hire
- **3.5-4.4:** Solid - Hire
- **3.0-3.4:** Borderline - Consider with reservations
- **<3.0:** Not ready - No hire

---

## 🚨 Instant Disqualifiers

These behaviors should trigger serious concerns:

1. **Cannot explain AI-generated code when asked**
2. **Uses AI for sensitive data or credentials**
3. **No validation of critical code paths**
4. **Asks AI to make business decisions**
5. **Cannot debug without AI assistance**
6. **Copy-pastes without any understanding**

---

## ✅ Excellence Indicators

These behaviors indicate exceptional candidates:

1. **Catches AI hallucinations or errors**
2. **Explains why they avoided AI for specific parts**
3. **Uses AI for research, then implements differently**
4. **Shows sophisticated prompt engineering**
5. **Validates with test cases before accepting AI code**
6. **Makes all architectural decisions independently**

---

## 📝 Evaluator Notes Template

**Candidate:__ _____________ **Date:** _____________

**AI Usage Observations:**
- Best example of appropriate AI use:
- Concerning AI dependency:
- Validation approach:
- Understanding depth:

**Specific Examples:**
- Challenge A AI decision:
- Challenge B debugging approach:
- Challenge C optimization strategy:
- Rapid fire adaptability:

**Overall AI Maturity Level:** 
□ Master (uses as tool) 
□ Competent (good balance) 
□ Developing (over-relies) 
□ Concerning (dependent)

**Recommendation:** _______________
