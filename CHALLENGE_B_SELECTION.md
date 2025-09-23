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
- Should understand architecture before using AI tools
- Can use AI for initial discovery but must go beyond it
- Must validate and explain all AI findings
- Should identify issues AI missed through manual analysis

### Key Differences

| Aspect | Original (C++/.NET) | Alternative (Node.js) |
|--------|---------------------|----------------------|
| **Stack Knowledge** | C++, .NET, P/Invoke, Edge.js | JavaScript, EventEmitter, async/await |
| **Error Types** | SIGSEGV, marshalling, AppDomain | Heap exhaustion, stack overflow |
| **Memory Issues** | Connection pools, unmanaged code | Event loops, closures, caches |
| **Architecture** | 6 modules, 10+ leak sources | Single service, 7 leak sources |
| **Complexity** | **EQUAL** - Multi-module analysis | **EQUAL** - Complex object graphs |
| **Accessibility** | Specialized .NET knowledge | Mainstream JavaScript |

### Evaluation Consistency

Both challenges now have **equivalent complexity** and use the same scoring:
- **5 points**: Identifies 6+ memory leak sources, systematic multi-module analysis
- **4 points**: Finds 4-5 problems, traces through architecture methodically
- **3 points**: Identifies some key issues, basic debugging approach
- **2 points**: Struggles with complexity, needs heavy guidance
- **1 point**: Cannot debug systematically across modules

### Red Flags (Same for Both)

❌ **AI-Only Dependency**: Only relies on AI without further analysis
❌ **No Architecture Understanding**: Cannot trace through multiple modules systematically
❌ **Missing Methodology**: No systematic debugging approach beyond AI suggestions
❌ **Surface-Level Analysis**: Cannot distinguish real leaks from performance issues
❌ **Blind Implementation**: Implements AI suggestions without understanding them
❌ **Zero Independent Analysis**: Cannot identify ANY issue without AI help
❌ **Stops After AI**: Accepts AI findings as complete without validation

### Green Flags (Same for Both)

✅ **Systematic Architecture Analysis**: Traces through all modules/components methodically
✅ **Independent Problem Identification**: Finds multiple memory leak sources without AI dependency
✅ **Pattern Recognition**: Distinguishes real leaks from performance red herrings
✅ **Deep Understanding**: Explains WHY each issue causes memory growth
✅ **Domain Knowledge**: Recognizes common patterns (event listeners, unbounded caches, etc.)
✅ **Strategic AI Usage**: Uses AI for initial discovery, then validates and extends findings
✅ **Efficient Tool Use**: Combines AI assistance with manual investigation
✅ **Goes Beyond AI**: Identifies issues AI missed through systematic analysis
✅ **Validation Skills**: Can explain and improve upon AI suggestions
✅ **Monitoring Mindset**: Proposes prevention strategies and observability improvements

### AI Usage: Acceptable vs Concerning Patterns

#### ✅ **GOOD: AI-First Approach (Efficient & Strategic)**
```
"Let me quickly understand the architecture... 6 modules, interesting.
AI, analyze this code for potential memory leaks.
[Reviews AI findings]
Okay, so it found connection pool growth and event listener accumulation.
Let me trace through manually to see what it missed...
[Systematic analysis continues]
I see AI missed the circular reference in data-enricher.js."
```

#### ❌ **BAD: AI-Only Approach (Over-Dependent)**
```
"AI, fix all the memory leaks in this code.
[Copies AI suggestions without review]
Done, the AI found everything that needs fixing."
```

#### 🤔 **NUANCED: What Evaluators Should Look For**
- **Time to Understanding**: Do they grasp what AI found and why?
- **Going Beyond**: Do they find issues AI missed?
- **Validation**: Do they test or question AI suggestions?
- **Root Cause**: Can they explain the underlying problems?

### Interview Flow

1. **Choose challenge based on background**
2. **Present the same way:**
   - "Service has memory leaks"
   - "Works fine initially, fails under load"
   - "Here's the code and error logs"

3. **Watch for same behaviors:**
   - Do they systematically read through all modules?
   - Do they trace data flow and object lifecycles?
   - Do they identify multiple leak sources?
   - Do they distinguish real leaks from performance issues?

4. **Probe the same way:**
   - "Why does this cause a leak?"
   - "How would you prevent this?"
   - "What monitoring would you add?"

### Note for Scoring

**IMPORTANT**: Both challenges now have **equivalent complexity**:

**Original (C++/.NET)**:
- 6 modules with 10+ memory leak sources
- Multi-module architecture analysis required
- Event listeners, connection pools, unbounded caches
- .NET/Edge.js interop complexity

**Alternative (Node.js)**:
- Single service with 7 memory leak sources
- Complex object graph analysis required
- Event emitters, circular references, recursive depth
- Pure JavaScript but equally challenging

**Choose based on candidate stack experience, NOT difficulty level.**
