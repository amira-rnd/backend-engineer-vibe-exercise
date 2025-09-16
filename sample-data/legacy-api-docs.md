# Legacy API Documentation
## Reference for Debugging Challenges

### Known Issues with Legacy System

#### Memory Management
- .NET assemblies use unmanaged C++ code
- P/Invoke marshalling can cause memory leaks
- Objects not properly disposed between Lambda invocations
- Reference counting issues in BaseDBObject

#### Common Error Patterns

```
Exit Code 139 - Segmentation fault
- Usually indicates memory access violation
- Often caused by accessing freed memory
- Can occur with improper P/Invoke marshalling

SIGSEGV (Signal: Segmentation Violation)
- Attempting to access restricted memory
- Double-free corruption
- Buffer overflow in C++ layer

"double free or corruption"
- Object being freed twice
- Improper cleanup in destructor
- Race condition in multi-threaded access
```

#### Legacy API Connection Pattern

```javascript
// PROBLEMATIC PATTERN - DO NOT USE
class LegacyApiClient {
  constructor() {
    this.connections = []; // Never cleaned!
    this.dotNetFunction = edge.func({...});
  }
}

// BETTER PATTERN
class LegacyApiClient {
  constructor() {
    this.maxConnections = 10;
    this.connectionPool = new ConnectionPool();
  }
  
  async cleanup() {
    await this.connectionPool.drain();
  }
}
```

### GraphQL Resolver Best Practices

- Always dispose of resources in finally blocks
- Use connection pooling for database connections
- Implement circuit breakers for legacy calls
- Add timeout handling for long-running operations
