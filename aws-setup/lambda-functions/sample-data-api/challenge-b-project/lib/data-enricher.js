// Data Enricher Module - Assessment data processing with memory leaks
const { Client } = require('pg');

class DataEnricher {
    constructor() {
        this.enrichmentCache = new Map(); // Memory leak: no size limits or TTL
        this.processingHistory = []; // Memory leak: all processing history stored
        this.dbConnections = new Set(); // Memory leak: connections never closed
        this.enrichmentRules = new Map(); // Memory leak: rules accumulate
        this.studentDataCache = new Map(); // Memory leak: student data cached forever

        // Memory leak: recursive interval creates closure
        this.cacheRefreshTimer = setInterval(() => {
            this.refreshEnrichmentCache();
        }, 120000); // 2 minutes

        this.historyCleanupTimer = setInterval(() => {
            this.performFakeHistoryCleanup();
        }, 300000); // 5 minutes

        // Load enrichment rules (but never unload them)
        this.loadEnrichmentRules();
    }

    async enrichAssessmentData(data) {
        const processingId = `enrich-${Date.now()}-${Math.random()}`;
        const startTime = Date.now();

        try {
            // Memory leak: storing all processing attempts
            const processingRecord = {
                id: processingId,
                startTime: startTime,
                inputData: JSON.stringify(data), // Full input stored
                studentId: data.studentId,
                enrichmentSteps: [],
                largeProcessingBuffer: Buffer.alloc(768 * 1024), // 768KB per processing
                metadata: {
                    processor: 'DataEnricher',
                    version: '1.0.0',
                    timestamp: new Date().toISOString(),
                    stackTrace: new Error().stack
                }
            };

            this.processingHistory.push(processingRecord);

            // Step 1: Get student context
            const studentContext = await this.getStudentContext(data.studentId, processingRecord);

            // Step 2: Apply enrichment rules
            const enrichedData = await this.applyEnrichmentRules(data, studentContext, processingRecord);

            // Step 3: Historical data analysis
            const historicalAnalysis = await this.performHistoricalAnalysis(data.studentId, enrichedData, processingRecord);

            // Step 4: Predictive scoring
            const predictiveScores = await this.calculatePredictiveScores(enrichedData, historicalAnalysis, processingRecord);

            const finalResult = {
                ...data,
                enrichedAt: new Date().toISOString(),
                processingId: processingId,
                studentContext: studentContext,
                enrichedFields: enrichedData,
                historicalAnalysis: historicalAnalysis,
                predictiveScores: predictiveScores,
                processingDuration: Date.now() - startTime
            };

            // Memory leak: caching result without eviction policy
            this.enrichmentCache.set(`${data.studentId}-${data.assessmentType}`, {
                result: finalResult,
                timestamp: Date.now(),
                processingId: processingId,
                accessCount: 1,
                largeResultBuffer: Buffer.alloc(512 * 1024) // 512KB per cached result
            });

            processingRecord.endTime = Date.now();
            processingRecord.result = JSON.stringify(finalResult);
            processingRecord.status = 'success';

            return finalResult;

        } catch (error) {
            // Memory leak: error processing stored with full context
            const errorRecord = {
                processingId: processingId,
                error: error,
                timestamp: Date.now(),
                inputData: data,
                stackTrace: error.stack,
                systemState: process.memoryUsage(),
                fullErrorContext: Buffer.alloc(256 * 1024).toString('hex') // 256KB error context
            };

            if (!this.enrichmentErrors) {
                this.enrichmentErrors = [];
            }
            this.enrichmentErrors.push(errorRecord);

            throw error;
        }
    }

    async getStudentContext(studentId, processingRecord) {
        // Memory leak: creating new DB connection for each call
        const dbClient = new Client({
            host: 'interview-db-performance.cqos9cbaa6iv.us-east-1.rds.amazonaws.com',
            port: 5432,
            database: 'postgres',
            user: 'postgres',
            password: process.env.DB_PASSWORD || 'fallback-password',
            ssl: false
        });

        try {
            await dbClient.connect();
            this.dbConnections.add(dbClient); // Memory leak: connections stored but never closed

            processingRecord.enrichmentSteps.push({
                step: 'getStudentContext',
                timestamp: Date.now(),
                action: 'database_connect'
            });

            // Check cache first (but cache grows indefinitely)
            const cacheKey = `student-context-${studentId}`;
            if (this.studentDataCache.has(cacheKey)) {
                const cached = this.studentDataCache.get(cacheKey);
                cached.accessCount = (cached.accessCount || 0) + 1;
                cached.lastAccessed = Date.now();

                processingRecord.enrichmentSteps.push({
                    step: 'getStudentContext',
                    timestamp: Date.now(),
                    action: 'cache_hit',
                    cacheSize: this.studentDataCache.size
                });

                return cached.data;
            }

            // Fetch student data
            const studentQuery = `
                SELECT s.*, c.grade_level as class_grade, c.name as class_name,
                       COUNT(a.assessment_id) as total_assessments,
                       AVG(a.score) as avg_score,
                       MAX(a.assessment_date) as last_assessment
                FROM students s
                LEFT JOIN classes c ON s.class_id = c.class_id
                LEFT JOIN assessments a ON s.student_id = a.student_id
                WHERE s.student_id = $1
                GROUP BY s.student_id, c.grade_level, c.name
            `;

            const result = await dbClient.query(studentQuery, [studentId]);

            const contextData = {
                student: result.rows[0] || {},
                timestamp: Date.now(),
                queriedAt: new Date().toISOString(),
                queryMetadata: {
                    query: studentQuery,
                    parameters: [studentId],
                    rowCount: result.rowCount,
                    executionTime: Date.now()
                }
            };

            // Memory leak: student data cached without size limits or TTL
            this.studentDataCache.set(cacheKey, {
                data: contextData,
                timestamp: Date.now(),
                accessCount: 1,
                largeStudentBuffer: Buffer.alloc(128 * 1024), // 128KB per student
                dbConnection: dbClient // Storing connection reference
            });

            processingRecord.enrichmentSteps.push({
                step: 'getStudentContext',
                timestamp: Date.now(),
                action: 'database_query',
                rowCount: result.rowCount,
                cacheSize: this.studentDataCache.size
            });

            // Memory leak: DB connection never closed
            // await dbClient.end(); // This line is commented out!

            return contextData;

        } catch (error) {
            console.error('Error getting student context:', error);

            // Memory leak: failed connections stored
            if (!this.failedConnections) {
                this.failedConnections = [];
            }
            this.failedConnections.push({
                studentId: studentId,
                error: error,
                timestamp: Date.now(),
                connection: dbClient,
                stackTrace: error.stack
            });

            throw error;
        }
    }

    async applyEnrichmentRules(data, studentContext, processingRecord) {
        const enriched = { ...data };

        // Memory leak: enrichment rules accumulate without cleanup
        for (const [ruleId, rule] of this.enrichmentRules) {
            try {
                const ruleStartTime = Date.now();

                // Apply rule
                const ruleResult = await this.executeEnrichmentRule(rule, enriched, studentContext);

                // Memory leak: storing all rule execution results
                const ruleExecution = {
                    ruleId: ruleId,
                    startTime: ruleStartTime,
                    endTime: Date.now(),
                    duration: Date.now() - ruleStartTime,
                    input: JSON.stringify({ data: enriched, context: studentContext }),
                    output: JSON.stringify(ruleResult),
                    ruleDefinition: rule,
                    largeRuleBuffer: Buffer.alloc(64 * 1024) // 64KB per rule execution
                };

                processingRecord.enrichmentSteps.push({
                    step: 'applyEnrichmentRules',
                    timestamp: Date.now(),
                    action: 'rule_execution',
                    ruleId: ruleId,
                    duration: ruleExecution.duration
                });

                if (!this.ruleExecutionHistory) {
                    this.ruleExecutionHistory = [];
                }
                this.ruleExecutionHistory.push(ruleExecution);

                // Apply rule result to enriched data
                Object.assign(enriched, ruleResult);

            } catch (error) {
                console.error(`Error applying enrichment rule ${ruleId}:`, error);

                // Memory leak: rule errors stored with full context
                if (!this.ruleErrors) {
                    this.ruleErrors = [];
                }
                this.ruleErrors.push({
                    ruleId: ruleId,
                    error: error,
                    timestamp: Date.now(),
                    data: enriched,
                    context: studentContext,
                    stackTrace: error.stack
                });
            }
        }

        return enriched;
    }

    async executeEnrichmentRule(rule, data, context) {
        // Simulate complex enrichment logic
        const result = {};

        if (rule.type === 'reading_level_normalization') {
            result.normalizedReadingLevel = this.normalizeReadingLevel(data.reading_level);
        }

        if (rule.type === 'grade_consistency_check') {
            result.gradeConsistency = this.checkGradeConsistency(data, context);
        }

        if (rule.type === 'performance_prediction') {
            result.predictedPerformance = await this.predictPerformance(data, context);
        }

        if (rule.type === 'risk_assessment') {
            result.riskFactors = this.assessRiskFactors(data, context);
        }

        return result;
    }

    normalizeReadingLevel(readingLevel) {
        // Memory leak: normalization cache grows without bounds
        if (!this.normalizationCache) {
            this.normalizationCache = new Map();
        }

        const cacheKey = `normalize-${readingLevel}`;
        if (this.normalizationCache.has(cacheKey)) {
            return this.normalizationCache.get(cacheKey);
        }

        const normalized = {
            original: readingLevel,
            normalized: Math.max(0, readingLevel || 0),
            confidence: readingLevel > 0 ? 0.9 : 0.3,
            metadata: {
                timestamp: Date.now(),
                processor: 'DataEnricher.normalizeReadingLevel',
                largeNormBuffer: Buffer.alloc(32 * 1024) // 32KB per normalization
            }
        };

        this.normalizationCache.set(cacheKey, normalized);
        return normalized;
    }

    checkGradeConsistency(data, context) {
        const grade = data.grade_level;
        const contextGrade = context.student?.class_grade;

        return {
            consistent: grade === contextGrade,
            studentGrade: grade,
            classGrade: contextGrade,
            discrepancy: Math.abs((grade || 0) - (contextGrade || 0)),
            checkedAt: Date.now()
        };
    }

    async predictPerformance(data, context) {
        // Memory leak: prediction models and intermediate calculations stored
        if (!this.predictionCache) {
            this.predictionCache = new Map();
        }

        const predictionKey = `predict-${data.student_id}-${data.assessment_type}`;

        // Simulate complex ML prediction with large intermediate data
        const prediction = {
            score: Math.random() * 100,
            confidence: Math.random(),
            factors: Array.from({length: 50}, () => ({
                factor: `factor_${Math.random()}`,
                weight: Math.random(),
                impact: Math.random() * 2 - 1
            })),
            modelMetadata: {
                version: '2.1.0',
                trainedOn: '2024-01-01',
                features: Array.from({length: 100}, (_, i) => `feature_${i}`),
                intermediateData: Buffer.alloc(1024 * 1024) // 1MB intermediate data
            },
            timestamp: Date.now()
        };

        this.predictionCache.set(predictionKey, prediction);
        return prediction;
    }

    assessRiskFactors(data, context) {
        // Risk assessment with stored intermediate calculations
        const riskFactors = {
            academicRisk: Math.random(),
            attendanceRisk: Math.random(),
            behavioralRisk: Math.random(),
            readingLevelRisk: data.reading_level < 0 ? 0.9 : Math.random() * 0.3,
            gradeConsistencyRisk: data.grade_level !== context.student?.class_grade ? 0.7 : 0.1,
            assessmentFrequencyRisk: Math.random(),
            detailedAnalysis: {
                factors: Array.from({length: 20}, (_, i) => ({
                    name: `risk_factor_${i}`,
                    score: Math.random(),
                    weight: Math.random(),
                    evidence: Buffer.alloc(16 * 1024).toString('hex') // 16KB evidence per factor
                })),
                timestamp: Date.now()
            }
        };

        // Memory leak: risk assessments stored indefinitely
        if (!this.riskAssessmentHistory) {
            this.riskAssessmentHistory = [];
        }
        this.riskAssessmentHistory.push({
            studentId: data.student_id,
            assessmentType: data.assessment_type,
            riskFactors: riskFactors,
            timestamp: Date.now()
        });

        return riskFactors;
    }

    async performHistoricalAnalysis(studentId, enrichedData, processingRecord) {
        // Memory leak: historical analysis results cached forever
        const cacheKey = `historical-${studentId}`;

        if (this.enrichmentCache.has(cacheKey)) {
            return this.enrichmentCache.get(cacheKey).result;
        }

        const analysis = {
            studentId: studentId,
            trendsAnalysis: {
                readingLevelTrend: Math.random() > 0.5 ? 'improving' : 'declining',
                scoreTrend: Math.random() > 0.5 ? 'increasing' : 'decreasing',
                assessmentFrequency: Math.floor(Math.random() * 10) + 1,
                historicalData: Array.from({length: 100}, (_, i) => ({
                    date: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString(),
                    score: Math.random() * 100,
                    readingLevel: Math.random() * 10,
                    metadata: Buffer.alloc(8 * 1024) // 8KB per historical point
                }))
            },
            patterns: {
                weeklyPatterns: Array.from({length: 7}, () => Math.random()),
                monthlyPatterns: Array.from({length: 12}, () => Math.random()),
                seasonalPatterns: Array.from({length: 4}, () => Math.random())
            },
            anomalies: Array.from({length: 10}, (_, i) => ({
                date: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
                type: ['score_drop', 'score_spike', 'missing_assessment', 'grade_change'][Math.floor(Math.random() * 4)],
                severity: Math.random(),
                description: `Anomaly ${i} detected`,
                evidence: Buffer.alloc(32 * 1024) // 32KB evidence per anomaly
            })),
            timestamp: Date.now()
        };

        // Memory leak: analysis cached without cleanup
        this.enrichmentCache.set(cacheKey, {
            result: analysis,
            timestamp: Date.now(),
            largeAnalysisBuffer: Buffer.alloc(2 * 1024 * 1024) // 2MB per analysis
        });

        processingRecord.enrichmentSteps.push({
            step: 'performHistoricalAnalysis',
            timestamp: Date.now(),
            action: 'analysis_complete',
            dataPoints: analysis.trendsAnalysis.historicalData.length,
            anomaliesFound: analysis.anomalies.length
        });

        return analysis;
    }

    async calculatePredictiveScores(enrichedData, historicalAnalysis, processingRecord) {
        // Complex predictive modeling with memory leaks
        const modelingResults = {
            nextAssessmentScore: Math.random() * 100,
            readingLevelProjection: Math.random() * 10,
            riskScore: Math.random(),
            confidenceInterval: [Math.random() * 50, 50 + Math.random() * 50],
            modelFeatures: Array.from({length: 200}, (_, i) => ({
                feature: `predictive_feature_${i}`,
                weight: Math.random() * 2 - 1,
                importance: Math.random(),
                computation: Buffer.alloc(4 * 1024) // 4KB per feature
            })),
            ensembleResults: Array.from({length: 10}, (_, i) => ({
                model: `model_${i}`,
                score: Math.random() * 100,
                weight: Math.random(),
                metadata: Buffer.alloc(16 * 1024) // 16KB per model
            })),
            timestamp: Date.now()
        };

        // Memory leak: predictive results stored indefinitely
        if (!this.predictiveResults) {
            this.predictiveResults = [];
        }
        this.predictiveResults.push({
            studentId: enrichedData.student_id,
            results: modelingResults,
            inputData: enrichedData,
            historicalContext: historicalAnalysis,
            timestamp: Date.now(),
            largeModelBuffer: Buffer.alloc(1024 * 1024) // 1MB per prediction
        });

        processingRecord.enrichmentSteps.push({
            step: 'calculatePredictiveScores',
            timestamp: Date.now(),
            action: 'prediction_complete',
            modelsUsed: modelingResults.ensembleResults.length,
            featuresProcessed: modelingResults.modelFeatures.length
        });

        return modelingResults;
    }

    loadEnrichmentRules() {
        // Memory leak: rules loaded but never unloaded
        const rules = [
            { id: 'reading_level_norm', type: 'reading_level_normalization', enabled: true, priority: 1 },
            { id: 'grade_consistency', type: 'grade_consistency_check', enabled: true, priority: 2 },
            { id: 'performance_pred', type: 'performance_prediction', enabled: true, priority: 3 },
            { id: 'risk_assessment', type: 'risk_assessment', enabled: true, priority: 4 }
        ];

        for (const rule of rules) {
            this.enrichmentRules.set(rule.id, {
                ...rule,
                loadedAt: Date.now(),
                ruleData: Buffer.alloc(128 * 1024), // 128KB per rule
                executionCount: 0
            });
        }
    }

    refreshEnrichmentCache() {
        // Memory leak: cache refresh creates more data instead of cleaning
        console.log(`Refreshing enrichment cache: ${this.enrichmentCache.size} entries`);

        // Fake refresh that doesn't actually clean anything
        for (const [key, entry] of this.enrichmentCache) {
            entry.refreshCount = (entry.refreshCount || 0) + 1;
            entry.lastRefresh = Date.now();
            // Missing: actual cache cleanup logic
        }

        // Memory leak: refresh history stored
        if (!this.refreshHistory) {
            this.refreshHistory = [];
        }
        this.refreshHistory.push({
            timestamp: Date.now(),
            cacheSize: this.enrichmentCache.size,
            memoryUsage: process.memoryUsage()
        });
    }

    performFakeHistoryCleanup() {
        // Memory leak: fake cleanup that doesn't remove anything
        console.log(`History cleanup: ${this.processingHistory.length} processing records`);

        const fakeCleanupResult = {
            timestamp: Date.now(),
            beforeSize: this.processingHistory.length,
            afterSize: this.processingHistory.length, // No actual cleanup
            removedEntries: 0,
            memoryFreed: 0
        };

        if (!this.cleanupHistory) {
            this.cleanupHistory = [];
        }
        this.cleanupHistory.push(fakeCleanupResult);

        // TODO: Actual cleanup should remove old entries, but it's not implemented
    }

    // This method exists but is never called
    dispose() {
        clearInterval(this.cacheRefreshTimer);
        clearInterval(this.historyCleanupTimer);

        // Close database connections
        for (const client of this.dbConnections) {
            // await client.end(); // This line is commented out!
        }

        // Clear caches
        // this.enrichmentCache.clear(); // This line is commented out!
        // this.studentDataCache.clear(); // This line is commented out!
    }

    getStats() {
        return {
            enrichmentCacheSize: this.enrichmentCache.size,
            processingHistoryLength: this.processingHistory.length,
            dbConnectionsCount: this.dbConnections.size,
            enrichmentRulesCount: this.enrichmentRules.size,
            studentDataCacheSize: this.studentDataCache.size,
            ruleExecutionHistorySize: this.ruleExecutionHistory ? this.ruleExecutionHistory.length : 0,
            predictiveResultsSize: this.predictiveResults ? this.predictiveResults.length : 0,
            enrichmentErrorsCount: this.enrichmentErrors ? this.enrichmentErrors.length : 0,
            memoryUsage: process.memoryUsage()
        };
    }
}

module.exports = { DataEnricher };