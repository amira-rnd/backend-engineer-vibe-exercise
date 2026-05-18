# Interviewer Addendum — AI Evaluation for 2026

> **This document supersedes some rubric language in `comprehensive-scoring-rubric.md`.** Read it before the interview.

## The Core Shift

When this framework was built, the risk was: *candidate trusts AI too much.* In 2026, that risk still exists — but an equally dangerous failure mode has emerged: *candidate uses AI too timidly and falls behind on throughput.* The ideal hire is not "careful AI user." It is **aggressive AI user who owns every decision.**

---

## Four Candidate Profiles

| Profile | AI Usage | Validation | Decision Ownership | Verdict |
|---------|----------|------------|-------------------|---------|
| **A — Ideal** | Delegates freely, including full functions | Reviews output, catches issues, iterates | Makes all architectural + business calls | Hire |
| **B — Dependent** | Delegates freely | Accepts output uncritically, can't explain | Defers to AI | Do not hire |
| **C — Resistant** | Rarely or never uses AI | N/A | Owns everything, but slowly | Probably pass |
| **D — Conservative** | Uses AI only for boilerplate/syntax | Reviews the boilerplate thoroughly | Owns decisions | Acceptable, but not the ideal |

**Profile A is who you are hiring.** The existing rubric's 4/5 description ("Uses AI mainly for boilerplate and syntax") describes Profile D. Resist anchoring on D as the gold standard.

**Profile C is not a virtue.** `interviewer-guide.md` calls "no AI usage" a red flag. Treat it as one. A candidate who codes everything by hand in a 60-minute interview is demonstrating they are not productivity-multiplied.

---

## How to Distinguish A from B (the critical call)

The tell is what happens **after** the AI responds. Profile A:
- Reads the output, pauses, identifies something incomplete or wrong
- Runs it or traces it mentally before accepting
- Can explain every line under probing — not by reading it back to you, but by explaining *why* it works

**Mid-challenge: ask one probing question per AI-generated block.** See `PROBING-QUESTION-BANK.md` for per-challenge prompts. The question doesn't need to be adversarial — just ask them to explain a specific mechanism. Profile A answers from understanding. Profile B restates the code.

---

## How to Distinguish A from D

Profile D usually moves more slowly and writes less code. The score differential is:
- **Startup Fitness** — A ships faster; D often runs out of time before reaching Challenge C or rapid-fire
- **AI Tool Proficiency** — reinterpreted below

**Do not penalize A for volume of AI use.** If a candidate delegates an entire Challenge B diagnosis to AI and then explains each leak mechanism with precision when probed, they are 5/5 on AI Proficiency, not 3/5.

---

## Rubric Language Overrides

These phrases in `comprehensive-scoring-rubric.md` should be reinterpreted for 2026:

| Original language | Reinterpretation |
|-------------------|-----------------|
| **4/5:** "Uses AI mainly for boilerplate and syntax" | **4/5:** Uses AI effectively for implementation, reviews all output, validates critical paths |
| **5/5:** "Makes all critical decisions independently" | **5/5:** Makes all *judgment calls* independently — what to build, what rule to apply, whether to trust AI's answer |
| **4/5:** "Iterative prompting" | This belongs at 5/5 — it signals strategic engagement, not just lucky first-shot prompting |
| Red flag: "Extensive AI usage without understanding" | Reframe: "Accepted AI output without verification" — the volume is not the flag, the lack of review is |

---

## Scoring the AI-Review Rapid-Fire Task

Task 5 has been replaced with an AI-output review task (see `challenges/rapid-fire-ai-review.md`). Scoring:

| Finding | Points |
|---------|--------|
| Catches all 3 bugs + explains why each breaks in production | 5/5 on the task |
| Catches 2 of 3 + can reason about the category of risk | 4/5 |
| Catches 1 + identifies it as a "trust but verify" moment | 3/5 |
| Accepts the script uncritically | 1/5 (red flag regardless of Challenge A/B score) |

The most diagnostic signal here: does the candidate *start* by looking for bugs, or do they start by reading the code as if it's correct? Profile A enters in review mode by default.

---

## What Instant Disqualifiers Still Apply

These hold regardless of the above reinterpretation:
1. Cannot explain any AI-generated code when probed — doesn't know what it does, not just why
2. Accepts a business decision from AI without pushback (e.g., asks AI what to do with orphaned student IDs)
3. Does not test any code they produce in a 60-minute interview with full AWS access
