# 60-Minute Session Prioritization Guide
> **2026 format — see INTERVIEW-RUNBOOK.md for full detail**

## ⭐ REQUIRED SEQUENCE

| Time | Activity | Notes |
|------|----------|-------|
| 0–5 min | Setup & Introduction | AWS access check, AI tool chat |
| 5–27 min | **Challenge A: Data Migration** | Always run; 22 min hard limit |
| 27–30 min | **Task 5: AI Output Review** | Always run; 3 planted bugs |
| 30–33 min | Task 2: BatchGetItem Bug | Only if time permits |
| 33–60 min | Wrap-up & Probing | Use PROBING-QUESTION-BANK.md |

## ⚡ IF TIME PERMITS

- **Task 2** (3 min): BatchGetItem UnprocessedItems bug — good signal on DynamoDB depth
- **Deeper probing**: Pull 1-2 questions from `PROBING-QUESTION-BANK.md`
- Do NOT add Challenge B or C unless the candidate finishes Challenge A in under 15 min and has clearly strong fundamentals

## 🎯 Candidate Pace Adjustments

| Situation | Action |
|-----------|--------|
| Struggling with Challenge A | Stay on it — the struggle is the signal. Give a hint at 18 min if totally stuck. |
| Finishes Challenge A early (< 18 min) | Move to Task 5 immediately, then Task 2 if still ahead |
| Finishes Task 5 early | Task 2, then extra probing |
| Running behind at 25 min | Timebox Challenge A at 27 min regardless |

## ⏰ Timing Calls to Make

- At **20 min**: "5 minutes left on Challenge A — wrap up what you have"
- At **27 min**: "Let's move on — I have a quick review task for you" (Task 5)
- At **30 min**: "Nice. One more quick one if you're up for it" (Task 2, optional)
- At **33 min**: "Let's shift to wrap-up"

## 📊 Scoring Expectations

| Result | Assessment |
|--------|-----------|
| Completes Challenge A + catches ≥2 Task 5 bugs | Strong signal — likely hire |
| Completes Challenge A + catches 1 Task 5 bug | Acceptable — probe AI validation habits |
| Completes Challenge A but misses all Task 5 bugs | Red flag on AI output review |
| Does not complete Challenge A | Below bar — note what blocked them |

**Quality > Quantity** — one challenge done with real judgment beats two done on autopilot.

---
*Remember: watch HOW they work, not just output. See INTERVIEWER-ADDENDUM-2026.md for candidate profile definitions (A/B/C/D).*
