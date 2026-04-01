# Decorator Pattern — Architecture Specification

## 1. Pattern Intent

Enable dynamic extension of object behavior **without modifying the original class and without relying on subclass permutations**.

The pattern achieves this by **wrapping a component with one or more decorator objects that implement the same interface** and delegate calls to the wrapped component while optionally executing additional logic before or after delegation.

Primary architectural goal:

* **Additive behaviors must be attachable, removable, and reorderable at runtime through composition.**

---

# 2. Recognition Signals

AI agents should infer the Decorator pattern when the following architectural signals appear:

1. A system requires **optional or combinable behaviors** (logging, caching, validation, authentication, rate limiting).
2. Features must be **enabled in multiple permutations** without creating subclass explosions.
3. Core functionality must remain **unchanged when new behaviors are introduced**.
4. Clients should treat enhanced objects **identically to the base object**.
5. Behaviors should be **stackable in a pipeline-like chain**.
6. Delegation to a wrapped instance is required.

Anti-pattern indicators suggesting the need for Decorator:

* A class accumulating unrelated responsibilities.
* Many subclasses representing behavior combinations.
* Large conditional blocks controlling optional features.
* Repeated pre/post logic across multiple classes.

---

# 3. Core Invariant Rule

All decorators **must implement the same interface as the wrapped component and delegate calls to the wrapped instance**.

Invariant conditions:

* The **component interface is the stable contract**.
* **Decorators wrap components via composition**, never through inheritance of the concrete component.
* **Delegation must always occur** unless intentionally short-circuiting behavior.
* The **base component must remain unmodified** when new decorators are added.

---

# 4. Structural Roles

### Component (Interface)

Defines the contract shared by the base object and all decorators.

Responsibilities:

* Declares operations available to the client.
* Provides polymorphic access to decorated or undecorated implementations.

Example role:

```
Component
 └─ operation()
```

---

### Concrete Component

Implements the **core functionality**.

Responsibilities:

* Contains only the fundamental behavior.
* Must not include optional features like logging, caching, authentication, etc.

Constraints:

* Must remain **SRP-compliant**.
* Must not depend on decorators.

---

### Abstract Decorator

Base decorator class responsible for **holding the wrapped component reference**.

Responsibilities:

* Implements the component interface.
* Stores a reference to another component instance.
* Delegates calls to the wrapped component.

Required structure:

```
class Decorator implements Component
    protected Component inner
```

---

### Concrete Decorators

Add new responsibilities around delegated behavior.

Responsibilities:

* Implement additional logic **before and/or after delegation**.
* Extend the abstract decorator.

Typical responsibilities:

* Logging
* Caching
* Authentication
* Validation
* Rate limiting
* Retry policies

Execution structure:

```
before logic
delegate call
after logic
```

---

# 5. Lifecycle and Concurrency Constraints

### Construction

Decorators must receive the component instance through **constructor injection**.

```
Decorator(Component inner)
```

This guarantees:

* Immutable wrapping structure
* Explicit dependency chain

---

### Execution Flow

Invocation flows **from outermost decorator to innermost component**.

Example order:

```
Client
 → AuthDecorator
   → LoggingDecorator
     → ConcreteComponent
```

Execution sequence:

```
Auth.before
Logging.before
Component.operation
Logging.after
Auth.after
```

---

### Thread Safety

Thread safety depends on the wrapped component.

Rules:

* Decorators must not introduce shared mutable state unless synchronized.
* Stateless decorators are preferred.

---

# 6. SOLID Alignment

### Single Responsibility Principle

Each decorator introduces **exactly one additional responsibility**.

Examples:

* LoggingDecorator → logging only
* CacheDecorator → caching only
* AuthDecorator → authentication only

---

### Open Closed Principle

New behaviors are introduced by **adding decorators instead of modifying existing classes**.

---

### Liskov Substitution Principle

Decorators must remain **fully substitutable** for the component interface.

Clients cannot detect whether the object is decorated.

---

### Dependency Inversion Principle

Clients depend only on the **component interface**, never on concrete implementations.

---

# 7. Implementation Rules for AI Agents

AI code generation systems must enforce the following rules:

### Rule 1 — Always introduce a component interface

```
interface Component
    operation()
```

---

### Rule 2 — Core logic must exist in a concrete component

```
class ConcreteComponent implements Component
```

Responsibilities:

* Contain only essential domain behavior.

---

### Rule 3 — Create an abstract decorator base

Must implement the component interface and store a wrapped instance.

```
abstract class Decorator implements Component
    protected Component inner
```

---

### Rule 4 — All optional behaviors must be concrete decorators

Examples:

```
LoggingDecorator
AuthDecorator
CacheDecorator
RetryDecorator
```

Each decorator:

* Extends the base decorator
* Wraps the component
* Adds behavior

---

### Rule 5 — Decorators must delegate calls

Delegation must always occur unless behavior intentionally terminates the flow.

```
inner.operation()
```

---

### Rule 6 — Composition must replace subclass permutations

Prohibited structure:

```
LoggingAuthHandler
CachingLoggingHandler
AuthCachingHandler
```

Correct structure:

```
new LoggingDecorator(
    new AuthDecorator(
        new ConcreteComponent()
    )
)
```

---

# 8. Prompt Constraints for AI Code Generation

When instructing AI to generate code, enforce these constraints:

Required prompt constraints:

```
Use the Decorator Pattern.

Requirements:
- Define a shared component interface.
- Keep the core component responsible only for primary logic.
- Implement an abstract decorator holding a reference to the component.
- Each optional behavior must be implemented as a concrete decorator.
- Decorators must wrap components and delegate calls.
- Do not modify the core component when adding features.
- Behaviors must be composable and chainable.
```

Prohibited instructions:

* Adding features directly to the base class.
* Implementing behavior combinations using subclasses.
* Using conditional logic to control optional features.

---

# 9. Deterministic Refactoring Steps

Refactor a monolithic class into Decorator architecture using the following deterministic procedure.

### Step 1

Extract a component interface from the existing class.

---

### Step 2

Move the original functionality into a concrete component.

---

### Step 3

Create an abstract decorator that implements the component interface.

Add a field:

```
Component inner
```

---

### Step 4

Extract each optional behavior into a concrete decorator.

Examples:

* Logging
* Authentication
* Caching
* Validation

---

### Step 5

Replace conditional feature logic with decorator composition.

Before:

```
if(logging)
    log()

if(auth)
    authenticate()
```

After:

```
new LoggingDecorator(
    new AuthDecorator(
        new ConcreteComponent()
    )
)
```

---

### Step 6

Ensure client code depends only on the component interface.

---

# 10. Common AI Generation Errors

AI-generated implementations frequently contain the following structural violations:

### Error 1 — God Class

All behaviors inside a single class.

```
RequestHandler
 - log
 - authenticate
 - rateLimit
 - process
```

Violation: SRP + OCP.

---

### Error 2 — Subclass Explosion

Creating subclasses for behavior combinations.

```
LoggingHandler
AuthHandler
LoggingAuthHandler
CachingAuthHandler
```

Violation: scalability and maintainability.

---

### Error 3 — Conditional Feature Logic

Feature flags controlling behavior inside one class.

```
if(enableLogging)
if(enableAuth)
```

Violation: dynamic composition principle.

---

### Error 4 — Decorators Not Delegating

Decorator overrides behavior but does not forward calls.

Violation: chain integrity.

---

### Error 5 — Client Depends on Concrete Classes

Client constructs concrete components directly without interface abstraction.

Violation: dependency inversion.

---

# 11. Verification Checklist

An AI agent must verify the following before accepting a Decorator implementation.

✔ A shared component interface exists
✔ Concrete component implements the interface
✔ An abstract decorator implements the interface
✔ Decorators contain a reference to the component
✔ Decorators delegate calls to the wrapped component
✔ Each decorator introduces exactly one responsibility
✔ Client interacts only with the interface
✔ Behaviors can be stacked in arbitrary order
✔ The base component remains unchanged when adding features

Failure of any condition indicates incorrect implementation.

---

# 12. Minimal Structural Diagram

```
          Client
             │
             ▼
        Component
           ▲  ▲
           │  │
           │  └───────────────┐
           │                  │
ConcreteComponent      AbstractDecorator
                               │
                               ▼
                        ConcreteDecorator
                               │
                               ▼
                           Component
```

Dependency direction:

```
Client → Component Interface
Decorator → Component Interface
ConcreteComponent → Component Interface
```
