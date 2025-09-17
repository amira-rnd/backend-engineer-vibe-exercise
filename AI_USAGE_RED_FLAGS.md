# ⚠️ AI Usage Red Flags - Quick Reference
## Critical Areas Where Candidates Should NOT Use AI

### 🔴 Instant Red Flags

#### **AI-Only Dependency (Major Concern)**
- ❌ Only uses AI findings without further analysis
- ❌ Cannot identify issues beyond what AI suggests
- ❌ Accepts AI output without validation or understanding
- ❌ Stops investigation after AI provides initial results

#### **Critical Decision AI-Dependence**
If candidate uses AI for these strategic decisions, mark as concerning:

1. **Root Cause Analysis**
   - ❌ "AI, why is this code failing?"
   - ❌ "Fix this memory leak for me"
   - ❌ "What's wrong with this query?"

2. **Business Decisions**
   - ❌ "What should happen to invalid data?"
   - ❌ "How should conflicts be resolved?"
   - ❌ "What's the priority order?"

3. **Architecture Choices**
   - ❌ "Should I use caching here?"
   - ❌ "What's the best optimization approach?"
   - ❌ "How should I structure this?"

### 🟢 Good AI Usage

These show maturity and strategic thinking:

#### **AI-First (Efficient & Acceptable)**
   - ✅ "AI, scan this code for memory leaks... okay, found several, let me analyze each one"
   - ✅ "Let me use AI to get initial patterns, then validate manually"
   - ✅ "AI gave me these findings, but I see it missed the connection lifecycle issue"

#### **AI as Implementation Tool**
   - ✅ "I need to implement connection pooling, here's my approach..."
   - ✅ "Help me with the syntax for window functions"
   - ✅ "Generate the retry logic with exponential backoff"

#### **AI Validation & Iteration**
   - ✅ Tests AI code before using it
   - ✅ Rewrites parts that don't fit requirements
   - ✅ Questions suspicious or incomplete output
   - ✅ Identifies what AI missed through manual analysis

### 📝 Quick Evaluation per Challenge

**Challenge A (Migration):**
- Watch: Do they decide grade mapping rules or ask AI?
- Watch: Do they determine invalid data handling?

**Challenge B (Debugging):**
- Watch: Do they understand architecture before using AI tools?
- Watch: Do they systematically trace through all 6 modules (not just AI findings)?
- Watch: Do they identify memory leak sources beyond what AI suggests?
- Watch: Do they distinguish real leaks from performance red herrings?
- **Red Flag**: Only rely on AI to find memory leaks without validation
- **Green Flag**: Use AI for initial discovery, then analyze further
- Watch: Do they explain WHY issues cause memory leaks (not just copy fixes)?

**Challenge C (Optimization):**
- Watch: Do they analyze performance issue first?
- Watch: Do they choose optimization strategy or ask AI?

**Rapid Fire:**
- Watch: Do they know what to implement before asking how?

### 🎯 The Key Question

**"Could they solve this problem if AI gave them wrong information?"**

If No → Red flag
If Yes → Green flag
