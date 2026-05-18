# Probing Question Bank

Use these mid-challenge. One per AI-generated block is enough — don't interrogate. The goal is to reveal whether the candidate understands what they produced or is just moving fast.

**Delivery:** Casual, curious tone. "Walk me through how this handles X" not "Prove you understand this."

---

## Challenge A — Migration

### After they write data-loading or normalization logic

- "You're silently dropping the duplicate StudentID 141. Walk me through how you decided which record to keep. What would make you choose differently?"
- "The spec says negative reading levels should be set to `Math.max(0, grade - 0.5)`. Where did you get that rule? What would you want to confirm with the product team before shipping this?"
- "What business question would you ask before deciding how to handle a score of `-5.0` vs a score of `0.0`?" *(Looking for: the distinction that one is an error and one is a legitimate 'absent' record — these require different handling.)*

### After they handle assessment type mapping

- "You mapped DIBELS to BENCHMARK. How confident are you in that mapping? What happens to historical analysis if that's wrong?"
- "There's no `window_tag` column in the source CSV. How did you determine BOY/MOY/EOY, and what's the error rate on date-based inference at the boundaries?"

### Cross-file temporal check

- "Did you check whether any assessments are dated before the student's `CreatedDate`? What would you do with those?" *(Most candidates miss row 241. Not a gotcha — a signal that they interrogated the data holistically.)*

### Defend the AI output

- "Your migration script just wrote 264 students. How do you know that's right?"
- "Claude generated this retry logic. Show me the part of the output you verified yourself."

---

## Challenge B — Memory Leak Debugging

### After they identify a leak (any)

- "Why does the axios-per-request pattern leak at Lambda scale but not in a local test?" *(Looking for: Lambda warm-container reuse means module-level state persists across invocations — interceptors and clients accumulate.)*
- "The `setInterval` leak — what's the actual mechanism? Why doesn't the timer get garbage-collected?"
- "If I told you CloudWatch showed heap stable at 380MB for 50 invocations, would that change your diagnosis? What would you look at next?"

### After they produce a fix

- "You added LRU eviction to the cache. What's the maximum memory footprint now, worst case?"
- "You fixed the connection leak. How many connections does this Lambda actually need? What's the right pool size?"

### Distinguish understanding from AI transcription

- "Explain the `activeConnections` Map bug like I'm a junior engineer — not what line it's on, but what happens in memory over 1,000 invocations."
- "Your fix clears the interval on cleanup. When exactly is that cleanup called in a Lambda execution model?"

---

## Challenge C — Performance

### After they propose a query fix

- "How would you *verify* that `DISTINCT ON` is faster than sorting in application code without just running the query once?"
- "What does the Postgres query planner actually do differently with a composite index `(student_id, window_tag)` vs. the individual indices you see in the schema?"
- "The query runs against 600K assessments. After your fix, what's the rough order-of-magnitude improvement you'd expect? How did you estimate that?"

### On the CTE

- "The original query uses `WITH RECURSIVE`. Why is that actually wrong for this data shape, not just slow?" *(Looking for: the recursive member mixes schema types across branches — it's semantically broken, not just inefficient.)*

### On caching

- "Redis is available. When would you *not* add caching here, even though it would definitely speed this up?"

---

## Cross-Challenge — Defend AI Output (use anywhere)

These apply whenever the candidate produces or receives AI-generated code:

- "Claude just gave you that. What's the one thing in there you trust the least?"
- "Show me which part of this output you verified yourself and how."
- "If Claude had given you the wrong assessment-type mapping there, at what point would you have caught it?"
- "What's the part of this solution where you made the decision, not Claude?"
- "What would you change if you owned this code in production for a year?"

---

## Rapid-Fire AI Review Task

*(After they complete the AI-review task from `challenges/rapid-fire-ai-review.md`)*

- "You found [N] bugs. Walk me through why each one matters in production specifically — not just 'it's wrong,' but what would fail and when."
- "If Claude had generated a version with no bugs, would you have shipped it? What's your review process when you have no signal that something is wrong?"
- "What's the class of errors this kind of review catches? What class of errors does it miss?"
