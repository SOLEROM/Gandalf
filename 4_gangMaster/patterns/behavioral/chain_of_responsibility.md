# Chain of Responsibility — Operational Architecture Specification

## 1. Pattern Intent

Provide a **sequential processing pipeline** where a request is passed through a chain of independent handlers.
Each handler decides to:

1. Process the request and optionally stop the flow.
2. Delegate the request to the next handler.

The pattern eliminates large conditional logic blocks by replacing them with **composable handler objects**.

Primary goal: enable **extensible rule pipelines** without modifying existing processing logic.

---

## 2. Recognition Signals

An AI agent should identify the need for Chain of Responsibility when the following signals appear in code or requirements:

* Large functions containing **long `if / else` or `switch` chains**.
* Sequential rule evaluation such as:

  * validation steps
  * authentication → authorization → verification flows
  * logging or event processing pipelines
  * moderation or compliance pipelines
  * fallback logic across providers
* Logic where **each rule can stop processing early**.
* Code where **order of evaluation matters** but may change later.
* Repeated patterns of:

  ```
  if rule1 fails → stop
  else if rule2 fails → stop
  else if rule3 fails → stop
  ```

Strong indicators:

* Request moves **stage-by-stage**.
* Each stage has **one responsibility**.
* Stages are **reorderable or extendable**.

---

## 3. Core Invariant Rule

A request must travel through a **linked chain of handler objects**, where:

1. Each handler performs **exactly one responsibility**.
2. A handler **must not directly invoke any handler except its immediate successor**.
3. If a handler cannot fully process or terminate the request, it **delegates to `next`**.

Invariant:

```
Handler_i → Handler_i+1 → Handler_i+2 ...
```

No handler may bypass the chain or directly invoke non-adjacent handlers.

---

## 4. Structural Roles

### Request

Object containing data to be processed.

Responsibilities:

* Transport context across handlers.

Constraints:

* Must be immutable or mutation-controlled.

---

### Handler (Abstract Base)

Defines the **chain structure and delegation mechanism**.

Required methods:

```
setNext(handler)
handle(request)
```

Responsibilities:

* Maintain reference to `next` handler
* Delegate when current handler does not terminate flow

Required behavior:

```
if next exists:
    return next.handle(request)
else:
    return success
```

---

### Concrete Handlers

Individual rule processors.

Responsibilities:

* Perform **single validation or transformation**
* Stop the chain if rule fails
* Delegate to next handler if rule passes

Examples of handler responsibilities:

* Authentication
* Permission check
* Input validation
* Rate limiting
* Moderation filter
* Payment gateway fallback
* Logging stage

Constraints:

* Must not contain multiple unrelated rules.
* Must not instantiate other handlers.

---

### Chain Builder

Component responsible for constructing the pipeline.

Possible implementations:

* DI container configuration
* Factory method
* Builder pattern
* Startup initialization logic

Responsibilities:

* Determine handler ordering
* Link handlers using `setNext`.

---

## 5. Lifecycle / Concurrency Constraints

1. Handlers should be **stateless** when possible.
2. Chain construction occurs **once during application startup**.
3. Request processing must be **single-directional**.
4. Handlers must **not retain request state between invocations**.
5. Concurrency safety must be guaranteed if handlers are shared.

Recommended rule:

```
Handlers = Singleton
Request = Per invocation
```

---

## 6. SOLID Alignment

### Single Responsibility Principle (SRP)

Each handler implements **one rule or processing step only**.

---

### Open Closed Principle (OCP)

New behaviors must be introduced by:

```
Adding a new handler
```

Not by modifying existing handlers.

---

### Dependency Inversion Principle (DIP)

High-level pipeline logic depends on **handler abstraction**, not concrete handlers.

---

### Liskov Substitution Principle (LSP)

Any concrete handler must be interchangeable with any other handler implementing the base interface.

---

### Interface Segregation Principle (ISP)

Handlers expose only minimal methods:

```
handle()
setNext()
```

---

## 7. Implementation Rules for AI Agents

When generating Chain of Responsibility implementations:

1. Create **abstract handler base class or interface**.

2. Include:

```
nextHandler reference
setNext(handler)
handle(request)
```

3. Concrete handlers must:

```
override handle(request)
```

4. Delegation must follow:

```
if rule passes:
    call super.handle(request)
else:
    terminate chain
```

5. Handler classes must contain **only one validation or processing rule**.

6. Pipeline construction must occur **outside handlers**.

7. Ordering must be **configurable**.

---

## 8. Prompt Constraints for AI Code Generation

To enforce correct pattern generation, prompts must include the following requirements:

Required instructions:

```
Use Chain of Responsibility pattern
Create an abstract Handler
Include setNext() method
Each rule must be a separate handler class
Avoid if/else ladders
Pipeline must be extensible
Handlers must delegate to next
```

Recommended wording:

```
Design a validation pipeline using Chain of Responsibility.
Each rule must be implemented as an independent handler class.
Handlers must be linked using setNext().
Avoid monolithic validation methods.
```

---

## 9. Deterministic Refactoring Steps

When converting procedural logic into Chain of Responsibility:

### Step 1 — Identify Rules

Locate each conditional rule inside a large function.

Example pattern:

```
if ruleA
if ruleB
if ruleC
```

---

### Step 2 — Create Handler Abstraction

Introduce base handler containing:

```
nextHandler
setNext()
handle()
```

---

### Step 3 — Extract Rule Handlers

Each rule becomes:

```
RuleXHandler
```

Implement rule-specific logic inside `handle()`.

---

### Step 4 — Implement Delegation

Successful rule → forward request:

```
return next.handle(request)
```

---

### Step 5 — Build Pipeline

Replace procedural logic with chain construction:

```
auth.setNext(permission)
permission.setNext(validation)
```

---

### Step 6 — Replace Original Method

Original monolithic method becomes:

```
chain.handle(request)
```

---

## 10. Common AI Generation Errors

### 1. Monolithic Validation Function

AI produces:

```
validateRequest():
    if auth
    if permission
    if data
```

Violation: not a chain.

---

### 2. Handlers Calling Each Other Directly

Example:

```
authHandler → permissionHandler.handle()
```

Violation: breaks chain abstraction.

---

### 3. Multiple Rules in One Handler

Example:

```
ValidationHandler:
   checkAuth()
   checkPermissions()
   checkData()
```

Violation: SRP.

---

### 4. Hardcoded Pipeline

Handlers instantiated and invoked inside a single class method.

Violation: pipeline not configurable.

---

### 5. No `setNext` Method

Without chaining method, pattern cannot exist.

---

## 11. Verification Checklist

A correct implementation must satisfy all conditions:

* [ ] Abstract handler class exists
* [ ] Handler defines `setNext`
* [ ] Handler defines `handle`
* [ ] Each rule implemented in a separate handler
* [ ] Handlers delegate using `next`
* [ ] No long conditional chains exist
* [ ] Pipeline ordering configurable
* [ ] Handlers contain single responsibility
* [ ] Chain construction occurs outside handlers
* [ ] Request flows sequentially through handlers

---

## 12. Minimal Structural Diagram

```
        Request
           │
           ▼
   +------------------+
   |   Handler Base   |
   |------------------|
   | handle(request)  |
   | setNext(handler) |
   +--------+---------+
            │
            ▼
     +-------------+
     | AuthHandler |
     +-------------+
            │
            ▼
  +--------------------+
  | PermissionHandler  |
  +--------------------+
            │
            ▼
  +----------------------+
  | DataValidationHandler|
  +----------------------+
            │
            ▼
         Result
```

Dependency direction:

```
Client → Handler Abstraction → Concrete Handlers
```
