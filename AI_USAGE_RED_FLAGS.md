# ⚠️ AI Usage Red Flags - Quick Reference
## Critical Areas Where Candidates Should NOT Use AI

### 🔴 Instant Red Flags

If candidate uses AI for these, mark as concerning:

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

These show maturity:

1. **After Understanding**
   - ✅ "I need to implement connection pooling, here's my approach..."
   - ✅ "Help me with the syntax for window functions"
   - ✅ "Generate the retry logic with exponential backoff"

2. **Validation Focus**
   - ✅ Tests AI code before using
   - ✅ Rewrites parts that don't fit
   - ✅ Questions suspicious output

### 📝 Quick Evaluation per Challenge

**Challenge A (Migration):**
- Watch: Do they decide grade mapping rules or ask AI?
- Watch: Do they determine invalid data handling?

**Challenge B (Debugging):**
- Watch: Do they identify memory leak cause or ask AI?
- Watch: Do they understand SIGSEGV or Google it via AI?

**Challenge C (Optimization):**
- Watch: Do they analyze performance issue first?
- Watch: Do they choose optimization strategy or ask AI?

**Rapid Fire:**
- Watch: Do they know what to implement before asking how?

### 🎯 The Key Question

**"Could they solve this problem if AI gave them wrong information?"**

If No → Red flag
If Yes → Green flag
