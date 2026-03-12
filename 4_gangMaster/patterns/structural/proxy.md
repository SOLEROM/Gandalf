# Proxy Pattern — Architectural Specification for AI Coding Agents

---

# 1. Pattern Intent

Provide a **surrogate object that controls access to a real object** while preserving the same interface so the client remains unaware of the indirection.

The proxy acts as a **control layer** that can:

* Defer expensive object creation (lazy initialization)
* Enforce access control
* Add cross-cutting behaviors (logging, caching, throttling)
* Optimize resource usage
* Protect sensitive or remote operations

The proxy must behave **identically to the real subject from the client's perspective** while adding control logic around method invocation.

---

# 2. Recognition Signals

Identify Proxy Pattern applicability when the following signals appear in a system:

1. A **resource-heavy object** is instantiated even when not always used.
2. Initialization or calls involve **expensive operations** (IO, network, disk, heavy computation).
3. Multiple cross-cutting concerns appear around a service:

   * logging
   * caching
   * access validation
   * rate limiting
4. The client **should not control object creation timing**.
5. Behavior must be extended **without modifying the real service**.
6. The client can depend on an **interface abstraction**.

Proxy should be considered when:

```
client -> heavy_service
```

needs to become

```
client -> proxy -> heavy_service
```

while the **client remains unchanged**.

---

# 3. Core Invariant Rule

The proxy **must implement the same interface as the real subject** and **must delegate operations to the real subject**, optionally adding control logic before or after delegation.

The following must always remain true:

```
Client depends only on Subject interface
Proxy and RealSubject both implement Subject
RealSubject creation is controlled by Proxy
```

Proxy existence must be **transparent to the client**.

---

# 4. Structural Roles

### Subject (Interface)

Defines the contract used by the client.

Responsibilities:

* Declare operations available to clients
* Decouple client from real implementation
* Enable substitution between proxy and real subject

Example role characteristics:

```
interface ReportService
    generateReport()
```

---

### RealSubject

Implements the actual business logic.

Responsibilities:

* Execute the core functionality
* Remain unaware of proxy existence
* Avoid cross-cutting logic

Constraints:

* Must not include logging, caching, or access control related to proxy responsibilities.

---

### Proxy

Implements the same interface and controls access to the real subject.

Responsibilities:

* Hold reference to RealSubject
* Manage lifecycle of RealSubject
* Decide when to instantiate the real object
* Delegate calls after performing control logic

Proxy may perform:

* Lazy initialization
* Logging
* Caching
* Authorization
* Rate limiting
* Network forwarding

---

### Client

Depends only on the Subject interface.

Responsibilities:

* Invoke operations defined by the Subject
* Remain unaware of proxy vs real implementation

Client must **not instantiate RealSubject directly** when proxy behavior is required.

---

# 5. Lifecycle and Concurrency Constraints

### Lazy Initialization Rule

RealSubject must be created **only when first needed**.

```
if realSubject == null
    realSubject = new RealSubject()
```

Creation must occur **inside the proxy**, never inside the client.

---

### Delegation Rule

Every proxy method must:

```
perform_control_logic()
ensure_real_subject_initialized()
delegate_call_to_real_subject()
```

---

### Concurrency Considerations

If proxy is used in concurrent environments:

* Lazy initialization must be **thread-safe**
* Prevent multiple initializations

Possible enforcement strategies:

```
double-checked locking
synchronized initialization
atomic reference initialization
```

---

# 6. SOLID Alignment

### Single Responsibility Principle

Responsibilities are separated:

```
RealSubject → business logic
Proxy → control logic
```

---

### Open / Closed Principle

Behavior can be extended via proxies without modifying RealSubject.

---

### Dependency Inversion Principle

Client depends on **Subject interface**, not on RealSubject.

---

### Interface Segregation Principle

Subject must expose **only operations required by clients**.

---

# 7. Implementation Rules for AI Agents

When generating a Proxy implementation, enforce the following rules:

### Rule 1 — Interface First

Define a Subject interface before implementing RealSubject or Proxy.

```
interface Subject
```

---

### Rule 2 — Dual Implementation

Both classes must implement the interface.

```
RealSubject implements Subject
Proxy implements Subject
```

---

### Rule 3 — Proxy Holds RealSubject Reference

Proxy must contain:

```
private RealSubject realSubject
```

or

```
private Subject realSubject
```

---

### Rule 4 — Lazy Creation Inside Proxy

RealSubject must **not be constructed until required**.

Forbidden:

```
client -> new RealSubject()
```

Required:

```
Proxy.createRealSubjectOnFirstCall()
```

---

### Rule 5 — Delegation Enforcement

Proxy methods must forward calls to RealSubject.

Pattern:

```
method():
    pre_logic()
    ensure_real_subject()
    realSubject.method()
    post_logic()
```

---

### Rule 6 — Cross-Cutting Logic Isolation

Only the Proxy may contain:

* caching
* authorization
* throttling
* logging
* metrics

RealSubject must remain clean.

---

### Rule 7 — Client Uses Interface

Client dependency must be:

```
Subject service
```

not

```
RealSubject service
```

---

# 8. Prompt Constraints for AI Code Generation

When prompting AI systems to generate a proxy implementation, include these constraints:

Required instructions:

1. Generate a **Subject interface**.
2. Create a **RealSubject implementing the interface**.
3. Create a **Proxy implementing the same interface**.
4. Ensure **lazy initialization occurs in the proxy**.
5. The **client must depend only on the interface**.
6. Cross-cutting concerns must exist **only in the proxy class**.
7. Show **delegation flow from proxy to real subject**.
8. Demonstrate **first-call initialization behavior**.

Verification prompt example:

```
Explain where lazy initialization occurs and why the client does not instantiate the real object.
```

---

# 9. Deterministic Refactoring Steps

Transform a naive implementation into Proxy architecture using the following steps.

### Step 1 — Extract Interface

Create interface from existing service.

```
RealService -> IService
```

---

### Step 2 — Implement Interface

Modify RealService:

```
class RealService implements IService
```

---

### Step 3 — Create Proxy Class

```
class ServiceProxy implements IService
```

---

### Step 4 — Add Reference to RealService

```
private RealService realService
```

---

### Step 5 — Move Control Logic

Move from client or service:

* logging
* caching
* permissions
* initialization logic

into Proxy.

---

### Step 6 — Add Lazy Initialization

```
if realService == null
    realService = new RealService()
```

---

### Step 7 — Replace Client Dependency

Client must depend on:

```
IService service = new ServiceProxy()
```

---

### Step 8 — Verify Delegation

Each interface method must delegate to RealService.

---

# 10. Common AI Generation Errors

AI frequently produces incorrect proxy implementations.

### Error 1 — Client Instantiates RealSubject

Incorrect:

```
client -> new RealService()
```

This bypasses the proxy.

---

### Error 2 — Modifying the RealSubject

Adding logging or caching inside RealSubject violates separation of concerns.

---

### Error 3 — Proxy Without Interface

Proxy and real subject must share an interface.

---

### Error 4 — Eager Initialization

Incorrect:

```
realService = new RealService()
```

inside proxy constructor.

Lazy initialization must occur **inside method invocation**.

---

### Error 5 — Wrapper Instead of Proxy

A wrapper that simply forwards calls without lifecycle or control logic is not a true proxy.

---

### Error 6 — No Delegation

Proxy methods must call the real subject.

---

# 11. Verification Checklist

Use this checklist to validate a Proxy implementation.

| Check                    | Requirement                               |
| ------------------------ | ----------------------------------------- |
| Interface exists         | Subject interface defined                 |
| Dual implementation      | Proxy and RealSubject implement interface |
| Client dependency        | Client depends only on interface          |
| Proxy contains reference | Proxy holds RealSubject reference         |
| Lazy initialization      | RealSubject created only when needed      |
| Delegation               | Proxy forwards calls                      |
| Separation of concerns   | Cross-cutting logic isolated in proxy     |
| RealSubject purity       | Business logic only                       |
| Client transparency      | Client unaware of proxy                   |

All conditions must pass for a valid proxy architecture.

---

# 12. Minimal Structural Diagram

```
          +----------------+
          |     Client     |
          +--------+-------+
                   |
                   v
             +-----+------+
             |   Subject  |
             | (Interface)|
             +-----+------+
                   ^
         implements| implements
                   |
        +----------+-----------+
        |                      |
+-------+-------+      +-------+-------+
|      Proxy    |----->|   RealSubject |
| control layer |      | business logic|
+---------------+      +---------------+
```
