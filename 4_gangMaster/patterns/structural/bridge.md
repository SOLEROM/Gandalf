# Bridge Pattern — Operational Architecture Specification

---

## 1. Pattern Intent

Decouple **high-level abstraction** from **low-level implementation** so both can evolve independently without creating combinatorial class growth.

The pattern is used when:

* A system contains **two orthogonal dimensions of variation**.
* Each dimension may expand independently.
* Direct inheritance would create a **class explosion**.

Bridge replaces inheritance combinations with **composition between two hierarchies**.

Result:

* Abstraction hierarchy = **what the system does**
* Implementation hierarchy = **how the system performs it**

The abstraction delegates execution to the implementation through an interface boundary.

---

## 2. Recognition Signals

An AI agent should detect the need for Bridge when the following structural signals appear:

### Structural Indicators

1. **Class explosion from cross-product combinations**

Example structure pattern:

```
EmailAlert
SMSAlert
SlackAlert
EmailReport
SMSReport
SlackReport
```

This indicates two varying dimensions:

```
NotificationType × DeliveryChannel
```

2. **High-level logic directly performing low-level operations**

Example indicators:

* Business class calling platform APIs
* Logging/formatting mixed with transport logic
* Hardcoded delivery mechanisms

3. **Switch / if-else on implementation types**

Example anti-pattern:

```
if(channel == "email") sendEmail()
else if(channel == "sms") sendSMS()
```

4. **Duplicated logic across multiple subclasses**

Classes differ only in the implementation mechanism.

---

## 3. Core Invariant Rule

The **abstraction hierarchy must never depend directly on concrete implementations.**

Instead:

```
Abstraction → Implementer Interface → Concrete Implementer
```

All operational work is delegated through the implementer interface.

The abstraction defines **intent**, while the implementer defines **mechanism**.

---

## 4. Structural Roles

### 4.1 Abstraction

Defines the **high-level operation interface** used by clients.

Responsibilities:

* Encapsulate domain intent
* Maintain a reference to the Implementer
* Delegate execution to Implementer methods

Constraints:

* Must not contain platform-specific logic
* Must not instantiate concrete implementers

---

### 4.2 Refined Abstraction

Extends the abstraction with **additional domain behavior**.

Responsibilities:

* Provide specialized operations
* Maintain the same implementer dependency

Constraints:

* Must not introduce new implementation dependencies
* Must reuse the same implementer interface

---

### 4.3 Implementer

Interface defining **primitive operations required by the abstraction**.

Responsibilities:

* Define execution contract
* Provide operations required by abstraction

Constraints:

* Must contain **only implementation-level operations**
* Must not contain business intent logic

---

### 4.4 Concrete Implementer

Implements the implementer interface with **actual execution logic**.

Responsibilities:

* Perform platform or infrastructure work
* Interact with APIs, systems, or services

Examples:

* API clients
* Drivers
* Renderers
* Transport mechanisms

Constraints:

* Must not depend on abstraction subclasses

---

## 5. Lifecycle and Concurrency Constraints

1. **Implementer instance must be injected into abstraction**

Allowed injection mechanisms:

```
constructor injection
dependency injection container
factory composition
```

2. Implementers must be **runtime replaceable**.

3. Abstractions must treat implementers as **stateless or thread-safe dependencies**.

4. Switching implementers must not require modifying abstraction code.

---

## 6. SOLID Alignment

### Single Responsibility Principle

Separates:

```
Domain logic
vs
Infrastructure execution
```

---

### Open / Closed Principle

New functionality added by:

* Adding **new abstractions**
* Adding **new implementers**

Without modifying existing classes.

---

### Dependency Inversion Principle

High-level modules depend on:

```
Implementer Interface
```

Not concrete implementations.

---

## 7. Implementation Rules for AI Agents

When generating Bridge pattern code, enforce the following rules.

### Rule 1 — Detect Variation Axes

Identify independent variation dimensions:

```
Axis A: Domain abstraction
Axis B: Implementation mechanism
```

---

### Rule 2 — Create Implementer Interface

Define interface for execution mechanism.

Example structure:

```
interface MessageSender {
    send(message)
}
```

This interface represents **how work is executed**.

---

### Rule 3 — Create Concrete Implementers

Each mechanism becomes its own implementation.

Example:

```
EmailSender
SmsSender
PushSender
```

Each implements the implementer interface.

---

### Rule 4 — Define Abstraction Layer

Create base abstraction containing:

```
reference to Implementer
high-level operation methods
```

Example structure:

```
class Notification {
    MessageSender sender

    notify(message) {
        sender.send(message)
    }
}
```

---

### Rule 5 — Extend via Refined Abstractions

Specialize domain behavior through subclassing.

Example:

```
AlertNotification
ReportNotification
SystemNotification
```

These extend the base abstraction.

---

### Rule 6 — Client Composition

Client chooses combinations dynamically.

Example pattern:

```
Notification notification =
    new AlertNotification(new SmsSender())
```

This allows independent mixing of both hierarchies.

---

## 8. Prompt Constraints for AI Code Generation

When instructing AI coding systems, prompts should enforce separation.

### Required Prompt Directives

```
Separate abstraction from implementation.

Create an interface for the implementation side.

The abstraction must delegate execution to the interface.

Avoid conditional logic selecting implementations.

Use dependency injection to supply the implementer.
```

---

### Forbidden Generation Patterns

AI must NOT generate:

1. Implementation logic inside abstraction.

2. Conditional dispatch:

```
if(channel == "email")
```

3. Multiple subclasses representing cross combinations.

Example prohibited:

```
EmailAlertNotification
SmsAlertNotification
SlackAlertNotification
```

---

## 9. Deterministic Refactoring Steps

AI agents must follow these steps when refactoring tightly coupled code.

### Step 1 — Detect Implementation Logic

Locate platform-specific operations inside domain classes.

---

### Step 2 — Extract Implementer Interface

Create interface representing execution behavior.

---

### Step 3 — Move Logic to Concrete Implementers

Extract platform logic into separate classes.

---

### Step 4 — Inject Implementer

Modify abstraction to receive implementer dependency.

---

### Step 5 — Delegate Execution

Replace direct calls with implementer method calls.

---

### Step 6 — Remove Conditional Dispatch

Replace switch statements with polymorphic implementers.

---

## 10. Common AI Generation Errors

### Error 1 — Conditional Transport Logic

```
switch(channel)
```

Indicates missing bridge.

---

### Error 2 — Class Explosion

AI creates:

```
EmailAlert
SmsAlert
PushAlert
```

instead of separating dimensions.

---

### Error 3 — Tight Coupling

Abstraction directly creates implementation.

Example:

```
new EmailSender()
```

inside abstraction.

---

### Error 4 — Implementation Leakage

Infrastructure details appear in domain abstraction.

Examples:

```
SMTP config
HTTP clients
API tokens
```

---

## 11. Verification Checklist

An implementation satisfies Bridge if all conditions are true:

* [ ] Abstraction contains a reference to implementer interface
* [ ] Implementer interface defines primitive operations
* [ ] Concrete implementers encapsulate execution logic
* [ ] Refined abstractions extend abstraction only
* [ ] No conditional logic selects implementations
* [ ] New implementers can be added without modifying abstractions
* [ ] New abstractions can be added without modifying implementers
* [ ] Client composes abstraction + implementer

---

## 12. Minimal Structural Diagram

```
           +----------------------+
           |     Abstraction      |
           |----------------------|
           | implementer: Impl    |
           | operation()          |
           +----------+-----------+
                      |
                      v
              +---------------+
              |  Implementer  |
              |---------------|
              | operationImp()|
              +-------+-------+
                      |
         +------------+------------+
         |                         |
+------------------+      +------------------+
|ConcreteImplA     |      |ConcreteImplB     |
|------------------|      |------------------|
|operationImp()    |      |operationImp()    |
+------------------+      +------------------+


        ^
        |
+----------------------+
| Refined Abstraction  |
|----------------------|
| extended behavior    |
+----------------------+
```

Dependency direction:

```
Client → Abstraction → Implementer → Concrete Implementers
```
