# Known Issues

Issues documented here are deferred from pre-interview fixes to avoid destabilizing the live environment.

---

## 1. Schema mismatch: `populate-data.sh` vs `schemas.sql`

**Severity:** Medium — affects Challenge C if candidate queries the seeded RDS database

**Detail:** `aws-setup/populate-data.sh` creates and seeds an `assessments` table with columns `assessment_type`, `possible_points`, `period_id`, `assessment_date`. The canonical schema in `sample-data/schemas.sql` uses `type`, `window_tag`, `completed_at`. The SQL in `challenges/challenge-c-optimization.md` references the canonical schema columns. A candidate who runs `\d assessments` and then pastes the challenge SQL verbatim will get column-not-found errors.

**Workaround for interview:** If the candidate hits this, tell them: "The production schema is what's in `schemas.sql` — the seeded data uses a staging variant; treat the challenge doc as authoritative." This is not ideal, but doesn't invalidate the exercise.

**Proper fix (post-interview):** Reconcile `populate-data.sh` to seed columns matching `schemas.sql`, or add a migration step in `reset-interview.sh` that alters the table if columns don't match. Test with `make verify` after fixing.

---

## 2. `solutions/challenge-a-solution.js` — syntax error

**Severity:** Low — interviewer reference only, not shown to candidate

**Detail:** Methods `handleDataQualityIssues`, `normalizeName`, `deriveWindowTag`, and several others fall outside the `DataMigrator` class body because a `}` on line ~43 closes the class prematurely. The file will throw `SyntaxError` if executed.

**Fix:** Move the closing `}` to after the last method. Tracked in deliverables checklist.

---

## 3. `sample-data/test-data.json` — malformed JSON

**Severity:** Low — unclear if anything references this file

**Detail:** Line 47 has a `}` that closes the root object, but then `"sample_assessments":` continues as a top-level property (invalid JSON). `JSON.parse()` throws on load.

**Fix:** Either remove the premature `}` or restructure to wrap `sample_assessments` inside the root object. Or delete if nothing imports this file.

**Check before fixing:** `grep -r "test-data.json" .` to confirm nothing references it.

---

## 4. `challenge-b-alternative.md` contains full buggy source inline

**Severity:** High for signal quality — now addressed by stripping `// Memory leak:` comments from the deployed Lambda source

**Detail:** The markdown file itself pastes all memory-leak-relevant code directly in the challenge prompt. Even with comments stripped from the Lambda source in S3, a candidate who reads `challenge-b-alternative.md` carefully can extract the leak patterns without touching the actual code. The `// Memory leak:` comments in the markdown are still present.

**Partial mitigation:** With comments stripped from the actual Lambda source files, pasting the deployed code into AI no longer produces a perfect taxonomy instantly. The markdown inline code is a secondary exposure.

**Future fix (Tier 3):** Remove inline code from `challenge-b-alternative.md`, replace with CloudWatch log excerpts and API behavior description. Candidate must inspect actual source via S3/console.
