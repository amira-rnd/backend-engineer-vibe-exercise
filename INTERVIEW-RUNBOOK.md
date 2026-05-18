# Interview Runbook — Senior Backend Engineer
## 60-Minute Session Guide — Self-Contained

**Session structure:** Setup (5 min) → Challenge A (22 min) → Rapid Fire Task 5 (3 min) → Optional Task 2 if time permits (3 min) → Wrap-up probing (rest of time)

---

## Before the Interview (~10 min before)

```bash
cd /Users/rob/working/amira-rnd/backend-engineer-vibe-exercise/aws-setup

# Replace with actual candidate name
make reset CANDIDATE=firstname-lastname INTERVIEW_ID=20250923-0446
make verify CANDIDATE=firstname-lastname
make credentials CANDIDATE=firstname-lastname
```

**If verify fails — S3 lib files missing (most common issue):**
```bash
# Run these manually — the sync script has a known path bug
aws s3 cp lambda-functions/sample-data-api/challenge-b-project/lib/cache-manager.js \
  s3://455737799003-challenges/lib/cache-manager.js --profile personal --region us-east-1
aws s3 cp lambda-functions/sample-data-api/challenge-b-project/lib/request-processor.js \
  s3://455737799003-challenges/lib/request-processor.js --profile personal --region us-east-1
aws s3 cp lambda-functions/sample-data-api/challenge-b-project/lib/legacy-client.js \
  s3://455737799003-challenges/lib/legacy-client.js --profile personal --region us-east-1
aws s3 cp lambda-functions/sample-data-api/challenge-b-project/lib/data-enricher.js \
  s3://455737799003-challenges/lib/data-enricher.js --profile personal --region us-east-1
aws s3 cp lambda-functions/sample-data-api/challenge-b-project/lib/metrics-collector.js \
  s3://455737799003-challenges/lib/metrics-collector.js --profile personal --region us-east-1
```

**What `make credentials` outputs — share this block with the candidate:**
```
AWS_ACCESS_KEY_ID=ASIA...
AWS_SECRET_ACCESS_KEY=...
AWS_SESSION_TOKEN=...
AWS_DEFAULT_REGION=us-east-1

SAMPLE_DATA_URL=https://1rlg3bpzj7.execute-api.us-east-1.amazonaws.com/prod  # same for all candidates

DynamoDB Tables:
  interview-students
  interview-assessments

RDS PostgreSQL:
  Host: [printed by make credentials]
  DB: interview
  User: candidate
  Password: [printed by make credentials]
```

Tell the candidate: credentials are valid for 12 hours. Share the block via Slack/chat — do not share the RDS password verbally.

---

## Setup & Introduction — 5 min

**Say to candidate:**

> "This is 60 minutes of collaborative work — real-world problems in a live AWS environment. You're encouraged to use AI tools heavily. We care about your process as much as the output, so think out loud. I'll ask questions along the way — some are to understand your thinking, not to test you.
>
> Quick question before we start: what's your usual AI workflow when you're writing new code? Do you start with a prompt, do you draft first and let AI fill gaps, or something else?"

**What to listen for:**
- Do they have a deliberate strategy or is it ad hoc?
- Do they mention validating AI output, or jump straight to "paste and run"?
- Note the answer — you'll compare it to their actual behavior during Challenge A.

**Then:** Confirm their AWS CLI works (`aws sts get-caller-identity --profile [or env vars]`) and they can curl the sample data URL.

---

## Challenge A — Legacy Data Migration — 22 min

### What to say

> "Amira is migrating student assessment data from a legacy SQL Server system into DynamoDB. I'll paste the challenge doc in chat. The CSV files are downloadable from the sandbox URL I just gave you.
>
> Your job: write a migration script that reads the CSVs, transforms the data, and writes to DynamoDB. You have about 20 minutes. Go."

The candidate fetches the challenge doc from their sandbox URL:
```bash
curl "https://1rlg3bpzj7.execute-api.us-east-1.amazonaws.com/prod?file=challenge-a-migration.md" -o challenge-a-migration.md
```

---

### The Hidden Test

The challenge doc lists 5 "known" data quality issues. The CSVs contain **7 additional undocumented traps**. The entire point of this challenge is whether the candidate opens the data or just codes against the spec.

**Watch immediately:** Does the candidate download and inspect the CSVs before writing code? If they start coding right away without looking at the data, note it.

---

### Pacing Guide

| Time into Challenge A | If candidate is... | Do this |
|-----------------------|--------------------|---------|
| 0-3 min | Coding without downloading CSVs | Say nothing yet — watch |
| 5 min | Still hasn't looked at data | Ask: "Have you had a chance to look at the actual CSV files?" |
| 10 min | Stuck on normalization logic | Let them use AI; ask "what did Claude give you?" |
| 15 min | Not finding any undocumented traps | Ask one probing question (see below) to surface a trap |
| 18 min | Far from done | Say: "Two more minutes — show me what you have so far" |
| 22 min | Anywhere | "Let's stop there. Walk me through what you built and what you'd do next." |

---

### Undocumented Traps — What to Watch For

| Trap | Location | What good looks like |
|------|----------|----------------------|
| Duplicate StudentID 141 (different grade + reading level) | `legacy-students.csv` rows 42-43 | Asks which record wins; doesn't silently pick one |
| Empty FirstName for student 142 | `legacy-students.csv` row 44 | Asks if FirstName is required; doesn't default to blank |
| Whitespace-padded names for student 143 | `legacy-students.csv` row 45 | Trims all text fields as general practice |
| Assessment 241 dated before student 103's CreatedDate | Cross-file (students row 4, assessments row 42) | Notices temporal impossibility; asks which date to trust |
| Assessment 242 score 115.5 (over 100) | `legacy-assessments.csv` row 43 | Asks if scores are capped vs. migrates blindly |
| Assessment 243 for inactive student 124 | Cross-file check | Asks what "inactive" means for migration scope |
| Assessment 244 score -5.0 (distinct from 0.0) | `legacy-assessments.csv` row 45 | Distinguishes data error from absent-student zero |

You don't need them to find all 7. Watch the *process*: interrogating the data vs. coding from memory.

---

### Interviewer Answers to Business Questions

Give these answers when the candidate asks — good candidates will ask several:

| Their question | Your answer |
|----------------|-------------|
| Duplicate StudentID 141 — which record do I use? | "Use the record with the latest CreatedDate. In production we'd flag for manual review." |
| Student 142 has no FirstName — what do I do? | "Skip records missing required fields and log them. FirstName and LastName are both required." |
| Names have extra whitespace — should I clean them? | "Yes, trim all text fields. The legacy system didn't validate input." |
| Assessment 241 is dated before the student was created — which date do I trust? | "Trust the assessment date. CreatedDate is when they were entered in the system, not when they enrolled." |
| Score 115.5 — is that valid? | "Scores can exceed 100 in some assessment types that include extra credit. Keep the original." |
| Should I migrate inactive students? | "Migrate all students regardless of IsActive. We need historical data for reporting." |
| Negative score -5.0 — valid? | "Negative scores are always data errors. Skip and log for review." |

---

### Mid-Challenge Probing Questions

Pick **one** after each significant AI-generated block. Casual, curious tone — not an interrogation.

**After normalization or data-loading logic:**
- "You're handling the duplicate StudentID 141 — walk me through how you decided which record to keep."
- "What business question would you ask before deciding how to handle a score of `-5.0` vs a score of `0.0`?"

**After assessment type mapping:**
- "You mapped DIBELS to BENCHMARK. How confident are you in that? What breaks downstream if it's wrong?"
- "There's no `window_tag` column in the source CSV. How did you derive BOY/MOY/EOY, and how accurate is date-based inference at the window boundaries?"

**After any AI-generated block:**
- "Your script just wrote N students. How do you know that's the right count?"
- "Show me which part of this output you verified yourself."

**If they haven't checked across files:**
- "Did you check whether any assessments are dated before the student's CreatedDate?" *(Not a gotcha — a signal that they interrogated the data holistically.)*

---

### Challenge A Scoring

| Score | What it looks like |
|-------|--------------------|
| **5/5** | Opens CSVs early, finds 5+ undocumented traps, asks clarifying questions *before* implementing, can explain every rule when probed |
| **4/5** | Finds 3-4 traps, asks most of the right questions, uses AI for implementation after getting answers |
| **3/5** | Finds 1-2 traps, makes some assumptions without asking, migration works but may lose edge-case data |
| **2/5** | Codes from spec only, finds 0 undocumented traps, cannot explain edge case handling |
| **1/5** | Doesn't open the CSVs; copy-pastes AI output without understanding; asks AI what the business rules should be |

**Red flags:**
- Asks AI "should I skip inactive students?" — AI must not make business decisions
- Doesn't question the output record count
- Reads AI-generated code back verbatim when probed instead of explaining the mechanism
- No logging of data quality issues

**Green flags:**
- Downloads CSVs and visually scans before writing a line of code
- Takes notes on anomalies, batches clarifying questions
- Uses AI for BatchWrite boilerplate but reviews normalization logic line by line
- Distinguishes error records from legitimate edge cases unprompted

---

## Transition to Rapid Fire

> "Good — let's switch gears. Quick 3-minute task. No setup needed."

---

## Rapid Fire Task 5 — AI Output Review — 3 min

### What to say

> "A teammate asked Claude to write a migration script and it came back in 30 seconds. They're about to run it against production. You have 3 minutes to review it. Ship it, fix it, or block it — and tell me specifically what's wrong."

The candidate fetches the script from their sandbox URL:
```bash
curl "https://1rlg3bpzj7.execute-api.us-east-1.amazonaws.com/prod?file=rapid-fire-ai-review.md" -o rapid-fire-ai-review.md
```

The script is also reproduced below for your reference (interviewer copy — includes the planted bugs):

```javascript
// Migration script - generated by Claude Sonnet 4.6
// Migrates legacy-students.csv and legacy-assessments.csv → DynamoDB

const AWS = require('aws-sdk');
const csvParse = require('csv-parse/sync');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const dynamoDB = new AWS.DynamoDB.DocumentClient({ region: 'us-east-1' });

const GRADE_MAP = {
  'K': 0, 'Kindergarten': 0,
  'First': 1, 'Second': 2, 'Third': 3, '3rd': 3,
  'Fourth': 4, 'Fifth': 5, 'Fifth Grade': 5, 'Sixth': 6
};

const ASSESSMENT_TYPE_MAP = {
  'DIBELS': 'PROGRESS_MONITORING',
  'PROGRESS': 'PROGRESS_MONITORING',
  'BENCHMARK': 'BENCHMARK'
};

const BATCH_SIZE = 26;

async function batchWrite(tableName, items) {
  for (let i = 0; i < items.length; i += BATCH_SIZE) {
    const batch = items.slice(i, i + BATCH_SIZE);
    const params = {
      RequestItems: {
        [tableName]: batch.map(item => ({
          PutRequest: { Item: item }
        }))
      }
    };
    await dynamoDB.batchWrite(params).promise();
  }
}

async function migrateStudents() {
  const raw = fs.readFileSync('./legacy-students.csv', 'utf8');
  const rows = csvParse.parse(raw, { columns: true, skip_empty_lines: true });
  const idMap = {};

  const students = rows
    .filter(row => row.FirstName && row.LastName)
    .map(row => {
      const newId = uuidv4();
      idMap[row.StudentID] = newId;
      const readingLevel = parseFloat(row.ReadingLevel);
      return {
        studentId: newId,
        legacyId: row.StudentID,
        firstName: row.FirstName.trim(),
        lastName: row.LastName.trim(),
        grade: GRADE_MAP[row.Grade] ?? parseInt(row.Grade),
        readingLevel: isNaN(readingLevel) || readingLevel < 0
          ? Math.max(0, (GRADE_MAP[row.Grade] ?? 0) - 0.5)
          : readingLevel,
        isActive: row.IsActive === '1' ? 'ACTIVE' : 'INACTIVE',
        createdAt: row.CreatedDate
      };
    });

  await batchWrite('interview-students', students);
  console.log(`Migrated ${students.length} students`);
  return idMap;
}

async function migrateAssessments(idMap) {
  const raw = fs.readFileSync('./legacy-assessments.csv', 'utf8');
  const rows = csvParse.parse(raw, { columns: true, skip_empty_lines: true });
  const now = new Date().toISOString();

  const assessments = rows
    .filter(row => idMap[row.StudentID])
    .map(row => {
      const score = parseFloat(row.Score);
      const dateTaken = new Date(row.DateTaken) > new Date() ? now : row.DateTaken;
      return {
        assessmentId: uuidv4(),
        studentId: idMap[row.StudentID],
        type: ASSESSMENT_TYPE_MAP[row.Type] || row.Type,
        score: score < 0 ? null : score,
        dateTaken,
        windowTag: deriveWindowTag(dateTaken)
      };
    });

  await batchWrite('interview-assessments', assessments);
  console.log(`Migrated ${assessments.length} assessments`);
}

function deriveWindowTag(dateStr) {
  const month = new Date(dateStr).getMonth() + 1;
  if (month >= 8 && month <= 10) return 'BOY';
  if (month >= 11 || month <= 1) return 'MOY';
  return 'EOY';
}

async function main() {
  const idMap = await migrateStudents();
  await migrateAssessments(idMap);
  console.log('Migration complete');
}

main().catch(console.error);
```

---

### The Three Planted Bugs

| Bug | Where | Why it breaks in production |
|-----|-------|----------------------------|
| `BATCH_SIZE = 26` | Line 4 of constants | DynamoDB BatchWriteItem hard limit is 25. Any batch of 26 throws `ValidationException`. Migration fails on the first full batch — immediately. |
| `batchWrite` discards the response | Inside `batchWrite()` — no `UnprocessedItems` check | BatchWriteItem can partially fail without throwing. Under throttling or load, items are silently lost. The code *looks* complete. |
| `'DIBELS': 'PROGRESS_MONITORING'` | `ASSESSMENT_TYPE_MAP` | DIBELS is a BENCHMARK type. This corrupts the assessment hierarchy and breaks BOY/MOY/EOY rollup reports for every DIBELS record. |

**Bonus bug — don't reveal unless they find it:**
`row.Type` — the actual CSV column is `AssessmentType`. Every assessment gets `type: undefined`. The DIBELS mapping bug above never fires at runtime because the lookup key is always undefined. If they find it, ask: "How would you have caught this before it hit production?"

---

### Task 5 Scoring

| Score | What it looks like |
|-------|--------------------|
| **5/5** | Finds all 3 bugs, explains why each breaks in production specifically (not just "it's wrong") |
| **4/5** | Finds 2 of 3, reasons about the risk category of each |
| **3/5** | Finds 1, correctly blocks the script |
| **1/5** | Ships it — automatic red flag regardless of Challenge A score |

**Signal to watch:** Does the candidate enter in *skeptic mode* (looking for what's wrong) or *reader mode* (reading it as if correct)? The ideal candidate starts suspicious by default.

**Probing after:**
- "Walk me through why each bug matters in production specifically — not just 'it's wrong,' but what fails and when."
- "If Claude had given you a version with no bugs, what's your review process when you have no signal something is wrong?"

---

## Optional Rapid Fire — only if time permits

### Task 2 — BatchGetItem Bug (3 min)

> "This code sometimes misses items from DynamoDB. Why, and how do you fix it?"

```javascript
async function getBatch(ids) {
    const params = {
        RequestItems: {
            'Students': {
                Keys: ids.map(id => ({
                    PK: `STUDENT#${id}`, SK: 'PROFILE'
                }))
            }
        }
    };
    const result = await ddb.batchGet(params).promise();
    return result.Responses.Students;
}
```

**What a strong answer looks like:**
- Identifies `UnprocessedKeys` — DynamoDB can return a partial result without throwing; the code discards the response entirely
- Adds a retry loop: while `UnprocessedKeys` is non-empty, re-request those keys (with exponential backoff)
- Mentions the 100-item batch limit as a second issue — no chunking logic
- Connects this to the `UnprocessedItems` pattern from Task 5 if they did that task (same partial-failure class)

**What a weak answer looks like:**
- "It has a bug somewhere" without identifying the mechanism
- Adds error handling (`try/catch`) — catches thrown errors but not partial failures, which is the actual problem
- Doesn't know DynamoDB can succeed partially without throwing

**Scoring:**

| Score | What it looks like |
|-------|--------------------|
| **5/5** | Identifies `UnprocessedKeys`, adds retry loop, mentions 100-item limit, explains why no exception is thrown |
| **4/5** | Identifies `UnprocessedKeys` and retry — misses 100-item limit |
| **3/5** | Knows something is missing from the response handling but needs a hint to name `UnprocessedKeys` |
| **1/5** | Adds try/catch and calls it fixed |

**Probing:**
- "Why doesn't DynamoDB throw an exception when it drops items?"
- "How does this relate to the `batchWrite` function in the Task 5 script?" *(if they did Task 5 — connects the two partial-failure patterns)*
- "What's the maximum number of keys you can pass to `BatchGetItem`?"

---

## Wrap-Up & Probing — 10 min

This is where the real signal lives if mid-challenge probing was light.

**Cross-challenge questions — pick 2-3:**
- "Looking back at your Challenge A script — what's the part where *you* made the decision, not Claude?"
- "If Claude had given you the wrong DIBELS mapping, at what point in your process would you have caught it?"
- "What would you do differently if this migration was 10 million rows instead of 264?"
- "What's the part of your solution you'd feel least confident defending in a production post-mortem?"
- "You said at the start that your usual AI process is [what they said]. How did that play out today?"

**One question to always ask:**
> "Is there anything you wanted to handle but didn't have time for?"

This surfaces judgment about prioritization — what did they deliberately defer vs. not notice at all?

---

## Scoring Summary

Score each dimension 1-5:

| Dimension | Weight | Challenge A signal | Task 5 signal |
|-----------|--------|--------------------|---------------|
| AI Tool Proficiency | 25% | Delegates implementation, owns all decisions | Reviews AI output skeptically before accepting |
| Technical Execution | 25% | DynamoDB BatchWrite, retry, UUID ID mapping | Knew 25-item limit; knew UnprocessedItems |
| Problem Solving | 20% | Found undocumented traps, asked right questions | Caught failure modes that don't throw exceptions |
| Startup Fitness | 15% | Shipped something working in 22 min | Made a clear call in 3 min |
| Domain Understanding | 15% | DIBELS = BENCHMARK, BOY/MOY/EOY derivation, IsActive semantics | Assessment type hierarchy, DIBELS mapping |

**Weighted score:** (AI × 0.25) + (Tech × 0.25) + (PS × 0.20) + (SF × 0.15) + (Domain × 0.15)

**Instant disqualifiers — any one is a no-hire:**
- Cannot explain any AI-generated code when probed (not the *why*, doesn't even know the *what*)
- Asked AI what the business rule should be (inactive students, orphaned assessments, etc.)
- Shipped the Task 5 script without flagging any bugs
- Produced zero working code in 22 minutes

---

## Candidate Profile — Circle One After the Session

**A — Hire:** Delegated aggressively to AI, reviewed all output, caught issues, defended every decision under probing. Moves fast AND owns the output.

**B — No hire:** Delegated aggressively, accepted AI output uncritically. Cannot explain generated code. Deferred business decisions to AI.

**C — Pass:** Barely used AI tools. Slower than the role demands. May be technically strong but not productivity-multiplied. Note: this is a red flag, not a virtue.

**D — Acceptable:** Used AI only for boilerplate and syntax. Owns all decisions. Thorough but conservative. Not the ideal, but defensible for some team compositions.

The hire target is **A**. If the candidate is B or C, do not hire regardless of Challenge A score.

---

## Between Candidates

```bash
cd /Users/rob/working/amira-rnd/backend-engineer-vibe-exercise/aws-setup
make reset CANDIDATE=next-candidate-name INTERVIEW_ID=20250923-0446
make credentials CANDIDATE=next-candidate-name
```

DynamoDB and RDS data are cleared; Lambda and infrastructure stay up. Takes ~2 minutes.
