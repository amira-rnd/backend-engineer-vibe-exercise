// Reference Solution - Challenge A: Data Migration
// DO NOT SHARE WITH CANDIDATES

const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
const ddb = new AWS.DynamoDB.DocumentClient();

const GRADE_MAP = {
  'kindergarten': 0, 'k': 0,
  'first': 1, '1st': 1, '1': 1,
  'second': 2, '2nd': 2, '2': 2,
  'third': 3, '3rd': 3, '3': 3,
  'fourth': 4, '4th': 4, '4': 4,
  'fifth': 5, '5th': 5, '5': 5,
  'sixth': 6, '6th': 6, '6': 6,
};

const ASSESSMENT_TYPE_MAP = {
  'DIBELS': 'BENCHMARK',
  'PROGRESS': 'PROGRESS_MONITORING',
  'BENCHMARK': 'BENCHMARK'
};

class DataMigrator {
  constructor(tableName = 'Students') {
    this.tableName = tableName;
    this.idMap = new Map();
    this.errors = [];
    this.stats = {
      processed: 0,
      successful: 0,
      failed: 0,
      dataQualityIssues: []
    };
  }

  normalizeGrade(gradeValue) {
    if (typeof gradeValue === 'number') {
      return gradeValue >= 0 && gradeValue <= 12 ? gradeValue : null;
    }
    const normalized = String(gradeValue).toLowerCase().trim();
    return GRADE_MAP[normalized] ?? null;
  }

  normalizeReadingLevel(level, grade) {
    if (level === null || level === undefined || level < 0) {
      return Math.max(0, (grade || 0) - 0.5);
    }
    return Math.min(12.0, Math.max(0, level));
  }

  validateDate(dateStr) {
    const date = new Date(dateStr);
    const now = new Date();
    if (date > now) {
      this.stats.dataQualityIssues.push({
        type: 'FUTURE_DATE',
        value: dateStr,
        corrected: now.toISOString()
      });
      return now.toISOString();
    }
    return date.toISOString();
  }

  deriveWindowTag(dateStr) {
    const month = new Date(dateStr).getMonth() + 1;
    if (month >= 8 && month <= 10) return 'BOY';
    if (month >= 11 || month <= 1) return 'MOY';
    return 'EOY';
  }

  async batchWriteWithRetry(tableName, items, retries = 3) {
    const batches = [];
    for (let i = 0; i < items.length; i += 25) {
      batches.push(items.slice(i, i + 25));
    }

    for (const batch of batches) {
      const params = {
        RequestItems: {
          [tableName]: batch.map(item => ({
            PutRequest: { Item: item }
          }))
        }
      };

      let response = await ddb.batchWrite(params).promise();
      let attempt = 0;

      while (
        response.UnprocessedItems &&
        Object.keys(response.UnprocessedItems).length > 0 &&
        attempt < retries
      ) {
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 100));
        response = await ddb.batchWrite({ RequestItems: response.UnprocessedItems }).promise();
        attempt++;
      }

      if (response.UnprocessedItems && Object.keys(response.UnprocessedItems).length > 0) {
        this.errors.push({ type: 'UNPROCESSED_ITEMS', items: response.UnprocessedItems });
      }
    }
  }

  // NOTE: Interviewer watch-fors for undocumented traps:
  // 1. Duplicate StudentID 141 — spec doesn't mention it. Correct: use latest CreatedDate.
  // 2. Empty FirstName (student 142) — must skip + log, not crash
  // 3. Whitespace names (student 143) — trim() is required
  // 4. Assessment 241 dated before student 103 CreatedDate — temporal impossibility; trust assessment date
  // 5. Score 115.5 — >100 is valid (extra credit); do NOT clamp
  // 6. Score -5.0 vs 0.0 — -5.0 is an error (skip); 0.0 is valid (absent student)
  // 7. 5 orphaned StudentIDs (999, 888, 777, 666, 555) — skip all + log; spec says 1
  // 8. window_tag must be derived from DateTaken — source column doesn't exist
}

module.exports = { DataMigrator };
