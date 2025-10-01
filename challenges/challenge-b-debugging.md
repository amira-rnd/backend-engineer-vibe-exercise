# Challenge B: GraphQL API Memory Leak
## ⭐ PRIORITY CHALLENGE
## Time: 15 minutes

### Background

Our GraphQL API (AppSync) is experiencing memory leaks and crashes under load. The resolver calls a Lambda function that interfaces with both Node.js services and legacy .NET/C++ components.

### Getting the Project

**Download the buggy codebase:**
```bash
# Quick setup (recommended):
curl "$SAMPLE_DATA_URL?file=setup-project.sh" > setup-project.sh
chmod +x setup-project.sh
./setup-project.sh

# Or get project overview first:
curl "$SAMPLE_DATA_URL?file=buggy-assessment-api"

# Or download files individually:
curl "$SAMPLE_DATA_URL?file=main.js" > main.js
curl "$SAMPLE_DATA_URL?file=lib/request-processor.js" > lib/request-processor.js
# ... etc
```

### Project Structure

```
buggy-assessment-api/
├── main.js                    # Lambda handler entry point
├── lib/
│   ├── request-processor.js   # Main processing logic
│   ├── legacy-client.js       # .NET/C++ interop layer
│   ├── cache-manager.js       # In-memory caching
│   ├── metrics-collector.js   # Performance tracking
│   └── data-enricher.js       # Data transformation
├── package.json               # Project dependencies
└── README.md                  # Problem description and symptoms
```

### Key Areas to Investigate

**Start by examining the project structure and understanding the data flow:**

1. **Main Entry Point**: `main.js` - Lambda handler with singleton pattern
2. **Core Processing**: `lib/request-processor.js` - Event-driven architecture with multiple services
3. **Legacy Integration**: `lib/legacy-client.js` - .NET/C++ interop via Edge.js
4. **Caching Layer**: `lib/cache-manager.js` - In-memory caching with metadata
5. **Metrics Collection**: `lib/metrics-collector.js` - Performance tracking
6. **Data Enrichment**: `lib/data-enricher.js` - Data transformation with context
7. **Project Info**: `README.md` - Complete symptom description and error logs

### Error Symptoms

```
CloudWatch Logs:
- Memory usage grows linearly: 256MB → 1GB → 2GB → 3GB → CRASH
- ERROR: Exit Code 139 (SIGSEGV)
- ERROR: "double free or corruption"
- ERROR: "JavaScript heap out of memory"
- Lambda timeouts after ~80-120 requests
- Occasional "UnhandledPromiseRejectionWarning"

Performance Metrics:
- P99 latency: 15+ seconds (was 2 seconds initially)
- Memory: Continuous growth, no garbage collection
- Active connections: Hundreds to legacy SQL Server
- Cache hit ratio: 95% (seems good, but...)
- Event listeners: Growing count in process inspection

.NET/Edge.js Errors:
- "Assembly could not be loaded after GC"
- "P/Invoke marshalling failed"
- "AppDomain memory pressure high"
- SQL connection pool exhaustion (max 100 connections)
```

### Accessing the Lambda Function

**Lambda Function Name:** `interview-buggy-api`
**CloudWatch Logs:** `/aws/lambda/interview-buggy-api`

You can download the function code and update it after fixing the memory leak.

### Your Task

1. **Identify ALL memory leak sources**
2. **Fix the implementation**
3. **Add proper cleanup and error handling**
4. **Optimize for concurrent requests**
5. **Prevent .NET/C++ resource exhaustion**

### Additional Context

- The .NET assembly uses unmanaged C++ code internally
- P/Invoke marshalling is involved
- The Lambda has 3GB memory allocated
- Cold starts are not the issue
- The problem only occurs under sustained load

