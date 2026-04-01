# Facade Pattern — Architectural Specification for AI Coding Agents

---

## 1. Pattern Intent

Encapsulate a multi-step workflow that coordinates several subsystem services behind a **single high-level entry point**.

The Facade provides a **stable, intention-driven API** that hides internal orchestration details, sequencing rules, and subsystem dependencies from clients.

Primary architectural goal:

* **Prevent clients (controllers, handlers, jobs, APIs) from orchestrating multiple subsystems directly.**
* Centralize workflow coordination in a dedicated component.

Resulting properties:

* Reduced coupling
* Stable client interfaces
* Contained workflow evolution
* Simplified API consumption
* Centralized cross-cutting control points (logging, retries, caching)

---

## 2. Recognition Signals

An AI system should identify the need for a Facade when the following signals appear:

1. **Client Orchestration**

   * Controllers or handlers call **multiple services sequentially**.

2. **Repeated Workflows**

   * The same sequence of service calls appears across multiple entry points.

3. **Order-Sensitive Operations**

   * Correct behavior depends on **strict ordering of subsystem calls**.

4. **Workflow Leakage**

   * Clients must know configuration, parameters, or ordering details of multiple subsystems.

5. **High Change Impact**

   * Modifying one subsystem requires updates in multiple clients.

Typical anti-pattern structure:

```
Controller
 ├─ AuthService
 ├─ CartService
 ├─ PaymentService
 └─ NotificationService
```

Clients become **accidental workflow engines**.

---

## 3. Core Invariant Rule

**Clients must interact with complex subsystem workflows through exactly one facade entry point.**

Invariant constraints:

* Clients **must not directly coordinate multiple subsystem services**.
* Workflow sequencing **must exist only inside the Facade**.
* Subsystem services remain **independent and unaware of the facade**.

If orchestration logic exists outside the facade, the pattern is violated.

---

## 4. Structural Roles

### 1. Facade

Responsibilities:

* Provide **high-level intention-driven API**
* Orchestrate subsystem calls
* Enforce workflow order
* Centralize cross-cutting policies

Characteristics:

* Stateless or minimally stateful
* Injects subsystem dependencies
* Contains orchestration logic only

Example responsibilities:

```
placeOrder()
sendOrderEmail()
createUserAccount()
processPayment()
```

---

### 2. Subsystem Services

Independent services performing **atomic responsibilities**.

Examples:

* Authentication
* Payment processing
* Notifications
* Storage
* Configuration

Rules:

* Must **not depend on the facade**
* Must **not orchestrate other subsystems**

---

### 3. Client

Examples:

* Controllers
* API handlers
* Scheduled jobs
* CLI commands
* External SDK consumers

Rule:

Clients call **only the facade**, not subsystems.

---

## 5. Lifecycle / Concurrency Constraints

### Construction

Facade dependencies must be **injected**, not instantiated internally.

```
Facade(
  AuthService,
  CartService,
  PaymentService,
  NotificationService
)
```

### Execution

Workflow sequencing occurs strictly inside the facade.

Example workflow:

```
authenticate
retrieve cart
process payment
send notification
```

### Concurrency

Facade may:

* enforce transaction boundaries
* manage retries
* coordinate idempotency

Subsystems remain concurrency-agnostic.

---

## 6. SOLID Alignment

### Single Responsibility Principle

Facade owns **workflow orchestration only**, not subsystem logic.

### Open/Closed Principle

New workflow steps should be added **inside the facade** without changing clients.

### Liskov Substitution Principle

Clients depend on the facade interface rather than subsystem details.

### Interface Segregation Principle

Clients interact with **intention-level methods**, not low-level services.

### Dependency Inversion Principle

Facade depends on **service abstractions**, not concrete implementations.

---

## 7. Implementation Rules for AI Agents

When generating architecture that involves multi-step workflows:

1. Detect sequences of service calls.
2. Extract orchestration into a **dedicated Facade class**.
3. Move ordering logic from controllers into the facade.
4. Inject all subsystem services via constructor.
5. Expose **one high-level method per workflow**.
6. Ensure clients call **only facade methods**.

Correct structure:

```
OrderController
      ↓
OrderFacade
 ├─ AuthService
 ├─ CartService
 ├─ PaymentService
 └─ NotificationService
```

Controller example:

```
orderFacade.placeOrder(request)
```

NOT:

```
authService.authenticate()
cartService.getCart()
paymentService.charge()
notificationService.send()
```

---

## 8. Prompt Constraints for AI Code Generation

When instructing AI to implement workflows, enforce the following prompts:

Required constraints:

```
Encapsulate the workflow in a Facade.
Controllers must not orchestrate services.
Expose a single high-level method.
Inject subsystem services into the facade.
Hide all internal steps from the client.
```

Refactoring prompts:

```
Refactor this workflow using the Facade pattern.
Move orchestration logic from controllers into a facade class.
Expose a single entry point for the client.
```

Avoid prompts like:

```
Generate checkout controller logic
```

which encourages procedural orchestration.

---

## 9. Deterministic Refactoring Steps

When converting existing procedural orchestration to a Facade:

### Step 1 — Detect Workflow

Identify sequential subsystem calls inside clients.

Example pattern:

```
A → B → C → D
```

---

### Step 2 — Create Facade Class

Create a new class representing the workflow domain.

Example:

```
OrderFacade
CheckoutFacade
UserOnboardingFacade
```

---

### Step 3 — Inject Subsystems

Move subsystem dependencies into the facade constructor.

---

### Step 4 — Move Workflow Logic

Transfer the sequential orchestration logic into a single method.

Example:

```
placeOrder()
```

---

### Step 5 — Replace Client Logic

Replace client orchestration with a single facade call.

Before:

```
controller:
  auth()
  getCart()
  processPayment()
  notify()
```

After:

```
controller:
  orderFacade.placeOrder()
```

---

### Step 6 — Remove Duplicate Workflows

Eliminate duplicated orchestration across controllers or modules.

---

## 10. Common AI Generation Errors

### 1. Controller Orchestration

AI generates:

```
Controller
 ├─ ServiceA
 ├─ ServiceB
 └─ ServiceC
```

Violation: workflow outside facade.

---

### 2. Manager / Helper Classes

AI invents vague orchestration containers:

```
WorkflowManager
ProcessHelper
ServiceCoordinator
```

Without enforcing a single API entry point.

---

### 3. Multiple Client Entry Points

Clients call multiple subsystem services even when a facade exists.

---

### 4. Facade Containing Business Logic

Facade starts implementing subsystem responsibilities instead of orchestration.

---

### 5. Instantiating Dependencies

```
paymentService = new PaymentService()
```

Instead of dependency injection.

---

## 11. Verification Checklist

An implementation satisfies the Facade pattern only if:

* [ ] Clients call **exactly one high-level method**
* [ ] Controllers contain **zero orchestration logic**
* [ ] All subsystem calls occur **inside the facade**
* [ ] Subsystems remain independent
* [ ] Workflow ordering exists only in the facade
* [ ] Dependencies are **injected**
* [ ] Client code reduced to **single facade invocation**
* [ ] Subsystem changes do not affect clients

---

## 12. Minimal Structural Diagram

```
        Client
          │
          ▼
       Facade
   (workflow API)
          │
   ┌──────┼─────────┐
   ▼      ▼         ▼
Auth   Payment   Notification
Svc     Svc         Svc
```

Dependency direction:

```
Client → Facade → Subsystems
```

Subsystems do **not depend on the Facade or Client**.

---

**Architectural Outcome**

The Facade pattern transforms **procedural subsystem orchestration into a stable architectural boundary**, ensuring that complex workflows remain centralized, reusable, and resilient to subsystem changes.
