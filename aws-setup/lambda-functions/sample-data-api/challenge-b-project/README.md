# Buggy Assessment API - Memory Leak Debugging Challenge

## 🚨 Problem Statement

This Lambda function is experiencing severe memory issues and crashes under load. Your task is to identify and fix the memory leaks causing the instability.

## 📋 Symptoms Observed

- Lambda function crashes with SIGSEGV errors under load
- Memory usage grows continuously during execution
- Performance degrades over time
- Eventual OutOfMemoryError in production

## 🏗️ Architecture Overview

The assessment API consists of 6 modules:

```
main.js                    # Lambda handler - entry point
├── lib/request-processor.js   # Core request processing logic
├── lib/legacy-client.js       # .NET Core interop for legacy data
├── lib/cache-manager.js       # Redis and in-memory caching
├── lib/metrics-collector.js   # CloudWatch metrics collection
└── lib/data-enricher.js       # Assessment data enrichment
```

## ⚙️ Getting Started

1. **Review all 6 modules systematically**
2. **Look for memory leak patterns across the codebase**
3. **Pay special attention to:**
   - Resource cleanup (connections, timers, event listeners)
   - Data structure growth (Maps, Arrays, caches)
   - .NET interop and unmanaged memory
   - Event listener accumulation
   - Cache eviction strategies

## 🔍 Debugging Tips

### Primary Memory Leak Categories to Investigate:

1. **Connection Pool Issues**
   - Database connections not closed
   - Redis client accumulation
   - .NET interop resource disposal

2. **Cache Memory Leaks**
   - Unbounded cache growth
   - Missing TTL/eviction policies
   - Double caching (memory + Redis)

3. **Event Listener Accumulation**
   - Process event listeners
   - Connection event handlers
   - Timer callbacks

4. **Data Structure Growth**
   - Maps and Arrays that never shrink
   - Historical data accumulation
   - Error context storage

5. **Circular References**
   - Object reference cycles
   - Parent-child relationships
   - Closure captures

6. **Timer/Interval Leaks**
   - Intervals not cleared
   - Timers creating closures
   - Recursive timer patterns

## 🎯 Success Criteria

- **Identify** the root causes of memory growth
- **Fix** the most critical memory leaks
- **Explain** why each issue causes memory problems
- **Prioritize** fixes by impact

## 🚀 Testing

```bash
# Run the application locally
npm start

# Monitor memory usage
node --inspect main.js

# Simulate load (if time permits)
# Use multiple concurrent requests to trigger leaks
```

## ⚠️ Important Notes

- **Focus on root cause analysis first** - don't just apply generic fixes
- **Consider the Lambda execution model** - understand cold starts vs warm containers
- **Think about production impact** - which leaks would cause crashes soonest?
- **Look for patterns across modules** - some anti-patterns may be repeated

## 💡 Debugging Strategy

1. **Start with systematic file review** (don't rely on tools initially)
2. **Trace object lifecycle** - creation, usage, disposal
3. **Map data flow** between modules
4. **Identify resource acquisition points** and their cleanup pairs
5. **Look for missing cleanup in error paths**

## 🔧 Expected Fixes Categories

You should find and fix issues in these areas:
- [ ] Connection pooling and cleanup
- [ ] Cache size management and eviction
- [ ] Event listener management
- [ ] Timer/interval cleanup
- [ ] Data structure bounds checking
- [ ] Circular reference breaking
- [ ] .NET resource disposal
- [ ] Error handling resource cleanup

## ⏱️ Time Management

- **4 minutes**: Analyze symptoms and architecture
- **9 minutes**: Systematic review and leak identification
- **2 minutes**: Explain findings and prioritize fixes

Remember: **Understanding WHY** each issue causes memory leaks is as important as identifying them!