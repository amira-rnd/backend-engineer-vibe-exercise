# Challenge B Selection Guide
## Choosing Between Original and Alternative

### Quick Decision Tree

```
Ask candidate: "Tell me about your experience with different tech stacks"

If mentions C++, .NET, P/Invoke, or COM interop:
  → Use ORIGINAL (challenge-b-debugging.md)
  → Tests deeper systems knowledge
  
If primarily Node.js/Python/Java/Go experience:
  → Use ALTERNATIVE (challenge-b-alternative.md)  
  → Tests same skills, different stack

If unsure:
  → Show them the error message from original
  → If they recognize SIGSEGV/Exit Code 139 → Original
  → If confused by C++ references → Alternative
```

### Both Challenges Test The Same Core Skills

✅ **Debugging Methodology**
- Systematic problem identification
- Root cause analysis
- Not jumping to solutions

✅ **Resource Management**
- Memory leak identification
- Connection lifecycle understanding
- Cache management

✅ **Production Awareness**
- Understanding symptoms vs causes
- Monitoring and observability
- Performance implications

✅ **AI Usage Discipline**
- Must identify issues before fixing
- Cannot rely on AI for root cause
- Should validate all solutions

### Key Differences

| Aspect | Original (C++/.NET) | Alternative (Node.js) |
|--------|---------------------|----------------------|
| **Stack Knowledge** | C++, .NET, P/Invoke | JavaScript, async/await |
| **Error Types** | SIGSEGV, marshalling | Heap exhaustion, stack overflow |
| **Memory Issues** | Unmanaged memory | Event loops, closures |
| **Complexity** | Cross-language | Pure JavaScript |
| **Accessibility** | Specialized | Mainstream |

### Evaluation Consistency

Both challenges use the same scoring:
- 5 points: Identifies all issues, systematic approach
- 4 points: Finds most problems, good methodology
- 3 points: Basic understanding, some fixes
- 2 points: Struggles, needs heavy guidance
- 1 point: Cannot debug independently

### Red Flags (Same for Both)

❌ Immediately asks AI to find the bug
❌ Cannot explain the symptoms
❌ No systematic debugging approach
❌ Blindly implements AI suggestions
❌ Cannot identify ANY issue without help

### Green Flags (Same for Both)

✅ Analyzes symptoms before diving in
✅ Identifies multiple issues
✅ Explains WHY each issue causes problems
✅ Proposes monitoring/prevention
✅ Uses AI for implementation after understanding

### Interview Flow

1. **Choose challenge based on background**
2. **Present the same way:**
   - "Service has memory leaks"
   - "Works fine initially, fails under load"
   - "Here's the code and error logs"

3. **Watch for same behaviors:**
   - Do they read all the code first?
   - Do they identify patterns?
   - Do they ask clarifying questions?

4. **Probe the same way:**
   - "Why does this cause a leak?"
   - "How would you prevent this?"
   - "What monitoring would you add?"

### Note for Scoring

The alternative is NOT easier - it has more subtle bugs:
- 7 potential memory leak sources vs 4 in original
- Circular reference complexity
- Event emitter gotchas
- Recursive depth issues

Choose based on candidate comfort, not difficulty.
