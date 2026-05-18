// Legacy Client Module - .NET Core interop with connection leaks
const edge = require('edge-js');

class LegacyClient {
    constructor() {
        this.connections = new Map();
        this.connectionPool = [];
        this.activeConnections = new Set();

        this.dotnetAssembly = edge.func({
            assemblyFile: '/opt/AmiraAssessment.dll', // Simulated path
            typeName: 'AmiraAssessment.LegacyDataService',
            methodName: 'ProcessStudentData'
        });

        this.connectionCleanupTimer = setInterval(() => {
            // This cleanup never actually happens properly
            console.log(`Active connections: ${this.activeConnections.size}`);
            // Missing: actual cleanup logic
        }, 30000);
    }

    async fetchStudentData(studentId) {
        const connectionId = `conn-${studentId}-${Date.now()}`;

        try {
            const connection = await this.createConnection(connectionId);
            this.activeConnections.add(connection);

            this.connections.set(connectionId, {
                connection: connection,
                studentId: studentId,
                createdAt: Date.now(),
                lastUsed: Date.now(),
                buffer: Buffer.alloc(1024 * 1024), // 1MB per connection
                metadata: {
                    host: 'legacy-sql-server.amira.com',
                    port: 1433,
                    database: 'AmiraLegacy',
                    timeout: 30000,
                    connectionString: `Server=legacy-sql-server.amira.com;Database=AmiraLegacy;User Id=legacy_user;Password=legacy_pass_${studentId};` // Storing passwords in memory
                }
            });

            // Call .NET component - potential managed/unmanaged memory leak
            const legacyResult = await this.callDotNetService(studentId, connection);

            this.connectionPool.push(connection);

            return legacyResult;

        } catch (error) {
            console.error(`Legacy client error for student ${studentId}:`, error);

            if (!this.errorHistory) {
                this.errorHistory = [];
            }
            this.errorHistory.push({
                connectionId: connectionId,
                studentId: studentId,
                error: error,
                connection: this.connections.get(connectionId), // Full connection object
                timestamp: Date.now(),
                stack: error.stack
            });

            throw error;
        }
        // Missing: connection cleanup and disposal
    }

    async createConnection(connectionId) {
        // Simulate connection creation with resource allocation
        const connection = {
            id: connectionId,
            socket: {
                fd: Math.floor(Math.random() * 1000),
                buffer: Buffer.alloc(64 * 1024), // 64KB per socket
                state: 'connecting'
            },
            sqlConnection: {
                handle: `handle-${connectionId}`,
                preparedStatements: new Map(),
                transactionLog: [],
                resultSetCache: new Map()
            },
            createdAt: Date.now()
        };

        connection.socket.onError = (error) => {
            console.error('Socket error:', error);
            // Error stored but connection never cleaned up
        };

        connection.socket.onData = (data) => {
            if (!connection.receivedData) {
                connection.receivedData = [];
            }
            connection.receivedData.push({
                data: data,
                timestamp: Date.now(),
                size: data.length
            });
        };

        return connection;
    }

    async callDotNetService(studentId, connection) {
        try {
            const result = await new Promise((resolve, reject) => {
                // Simulate .NET call with unmanaged memory allocation
                const unmanagedBuffer = Buffer.alloc(2 * 1024 * 1024); // 2MB unmanaged

                setTimeout(() => {
                    resolve({
                        studentData: {
                            id: studentId,
                            assessments: Array.from({length: 100}, (_, i) => ({
                                id: `assessment-${i}`,
                                score: Math.random() * 100,
                                data: Buffer.alloc(10 * 1024).toString('hex') // 10KB per assessment
                            })),
                            largeDataBlob: unmanagedBuffer.toString('hex')
                        },
                        connectionInfo: connection,
                        processedAt: Date.now()
                    });
                    // Missing: unmanagedBuffer disposal
                }, 100);
            });

            if (!this.dotnetCallHistory) {
                this.dotnetCallHistory = [];
            }
            this.dotnetCallHistory.push({
                studentId: studentId,
                result: result,
                timestamp: Date.now(),
                connection: connection // Full connection object stored
            });

            return result;
        } catch (error) {
            if (!this.dotnetErrors) {
                this.dotnetErrors = [];
            }
            this.dotnetErrors.push({
                studentId: studentId,
                error: error,
                connection: connection,
                timestamp: Date.now(),
                managedHeapSize: Math.random() * 1024 * 1024 * 100, // Simulated heap size
                unmanagedSize: Math.random() * 1024 * 1024 * 50
            });
            throw error;
        }
    }

    // This method is never called - missing cleanup!
    async dispose() {
        // TODO: This should clean up connections, timers, and .NET resources
        // But it's never called from the main application
        clearInterval(this.connectionCleanupTimer);
        for (const connection of this.activeConnections) {
            // connection.close(); // This line is commented out!
        }
        this.connections.clear();
        this.connectionPool.length = 0;
    }

    getStats() {
        return {
            connectionsCount: this.connections.size,
            poolSize: this.connectionPool.length,
            activeConnections: this.activeConnections.size,
            errorHistorySize: this.errorHistory ? this.errorHistory.length : 0,
            dotnetCallsCount: this.dotnetCallHistory ? this.dotnetCallHistory.length : 0,
            dotnetErrorsCount: this.dotnetErrors ? this.dotnetErrors.length : 0
        };
    }
}

module.exports = { LegacyClient };