# Factory Method Pattern — Operational Architecture Specification

---

# 1. Pattern Intent

Provide a controlled abstraction for object creation by delegating instantiation responsibility to subclasses.
The pattern separates **object creation** from **object usage**, enabling systems to extend supported product types without modifying existing business logic.

The Factory Method ensures that clients depend on **product abstractions** rather than **concrete implementations**, preserving extensibility and enabling adherence to the Open/Closed Principle.

Primary architectural objective:

> Creation logic must be encapsulated in a polymorphic factory hierarchy rather than embedded in client logic.

---

# 2. Recognition Signals

An AI agent should detect the need for the Factory Method pattern when the following structural signals exist:

1. Business logic directly instantiates concrete classes using constructors (`new`).
2. Conditional logic (`if`, `switch`) selects between multiple concrete implementations.
3. Core services depend on concrete implementations rather than interfaces.
4. Adding a new implementation requires editing existing service logic.
5. Creation logic and operational logic are located in the same class.
6. The system supports multiple interchangeable product implementations.

Typical domains:

* Notification channels
* Payment providers
* Document parsers
* UI component creation
* Plugin instantiation

---

# 3. Core Invariant Rule

The client or base creator must **never directly instantiate concrete products**.

All product instantiation must occur through a **factory method implemented by subclasses**.

Invariant constraint:

```
Client → Creator → Factory Method → Concrete Product
```

Creation control must remain exclusively within the factory hierarchy.

---

# 4. Structural Roles

## Product (Interface)

Defines the contract implemented by all concrete products.

Responsibilities:

* Declare common operations used by the client.
* Provide polymorphic interaction point.

Constraints:

* Must contain no creation logic.
* Must remain stable when new product types are introduced.

Example abstraction:

```
Notifier
 └── send(message)
```

---

## Concrete Product

Implements the product interface.

Responsibilities:

* Provide concrete behavior.
* Remain interchangeable through the product interface.

Constraints:

* Must not depend on the creator.
* Must not contain factory logic.

Example:

```
EmailNotifier
SMSNotifier
PushNotifier
```

---

## Creator (Abstract Factory)

Declares the **factory method** responsible for producing product objects.

Responsibilities:

1. Define abstract factory method.
2. Contain business logic that depends on the product interface.
3. Delegate product creation to subclasses.

Constraints:

* Creator may contain shared logic using the product.
* Creator must not instantiate concrete products.

Example:

```
abstract class NotifierCreator
    abstract createNotifier()

    send(message):
        notifier = createNotifier()
        notifier.send(message)
```

---

## Concrete Creator

Implements the factory method and returns a specific product implementation.

Responsibilities:

* Decide which concrete product to instantiate.
* Encapsulate creation logic for that product type.

Example:

```
EmailNotifierCreator → returns EmailNotifier
SMSNotifierCreator → returns SMSNotifier
```

Constraints:

* Only location where concrete product construction occurs.

---

# 5. Lifecycle and Concurrency Constraints

Creation lifecycle rules:

1. A product instance must be created **per invocation of the factory method** unless explicitly documented otherwise.
2. Creator classes must remain stateless unless product configuration requires state.
3. Concrete creators must not share mutable product instances across threads unless thread safety is guaranteed.
4. Factory method invocation must not depend on runtime type checks of products.

Concurrency constraints:

* Creator implementations must be thread-safe if used by concurrent clients.
* No shared mutable state in the creator without synchronization.

---

# 6. SOLID Alignment

### Single Responsibility Principle

Creation logic is isolated within creator classes.

### Open/Closed Principle

New product types are added by introducing new concrete creators without modifying existing logic.

### Liskov Substitution Principle

All concrete products must be substitutable through the product interface.

### Interface Segregation Principle

Product interface should contain only operations used by the creator.

### Dependency Inversion Principle

High-level logic depends on **product abstractions**, not concrete implementations.

---

# 7. Implementation Rules for AI Agents

When implementing the Factory Method pattern, the AI must enforce the following rules:

1. Extract a **product interface** defining the shared behavior.
2. Replace direct constructor calls with a **factory method**.
3. Introduce an **abstract creator class** containing the factory method declaration.
4. Move object creation logic into **concrete creator subclasses**.
5. Ensure the creator contains business logic that operates on the product interface.
6. Eliminate all conditional logic used to select product types.
7. Ensure clients interact only with the creator abstraction.

Correct dependency direction:

```
Client → Creator → Product Interface
Concrete Creator → Concrete Product
```

---

# 8. Prompt Constraints for AI Code Generation

When instructing AI coding systems, prompts must enforce the architectural constraints explicitly.

Required prompt structure:

```
Use the Factory Method pattern.

Define:
1. A product interface.
2. An abstract creator containing a factory method.
3. Concrete creator subclasses implementing the factory method.
4. Concrete products implementing the product interface.

Ensure:
- No direct instantiation of concrete products in business logic.
- Creation occurs only inside concrete creators.
- Business logic depends only on the product interface.
```

Optional enhancement:

```
Implement the creator operation as a template method
that internally invokes the factory method.
```

---

# 9. Deterministic Refactoring Steps

When refactoring code that violates Factory Method principles:

### Step 1 — Identify Instantiation Points

Locate all occurrences of:

```
new ConcreteProduct()
```

inside business logic.

---

### Step 2 — Extract Product Interface

Create a shared interface implemented by all concrete products.

---

### Step 3 — Introduce Creator Abstraction

Create an abstract creator class containing:

```
abstract createProduct()
```

---

### Step 4 — Move Business Logic

Relocate product usage logic into the creator class.

---

### Step 5 — Implement Concrete Creators

Create subclasses that override the factory method.

Example:

```
EmailNotifierCreator
SMSNotifierCreator
```

---

### Step 6 — Remove Conditional Logic

Delete all type-selection `if` or `switch` statements.

---

### Step 7 — Update Client Dependencies

Clients must depend only on the **creator abstraction**.

---

# 10. Common AI Generation Errors

AI systems frequently generate incorrect implementations.

### Error 1 — Conditional Factory

```
if(type == "email")
   return new EmailNotifier()
```

Violation: Creation logic remains centralized.

---

### Error 2 — Creator Instantiates Product Directly

```
send():
   notifier = new EmailNotifier()
```

Violation: Factory method unused.

---

### Error 3 — Client Knows Concrete Products

```
new EmailNotifierCreator()
```

Hard dependency may be acceptable only at composition root.

---

### Error 4 — Product Interface Missing

Concrete classes used directly instead of through abstraction.

---

### Error 5 — Multiple Responsibilities in Creator

Creator performing unrelated business operations.

---

# 11. Verification Checklist

An implementation is valid only if **all conditions pass**.

✔ No `new ConcreteProduct` calls exist in business logic
✔ Creator declares a factory method
✔ Concrete creators override the factory method
✔ Client code depends only on product interfaces
✔ Adding a new product requires **only** a new concrete creator and product class
✔ No `if` or `switch` statements choose product types
✔ Business logic remains unchanged when new products are introduced

---

# 12. Minimal Structural Diagram

```
            Client
              │
              ▼
         Creator (abstract)
         + createProduct()
         + operation()
              │
              ▼
        Product Interface
              ▲
              │
   ┌──────────┴──────────┐
   │                     │
ConcreteCreatorA   ConcreteCreatorB
   │                     │
   ▼                     ▼
ConcreteProductA   ConcreteProductB
```

Dependency direction:

```
Client → Creator → Product Interface
ConcreteCreator → ConcreteProduct
```

Creation flow:

```
operation()
   ↓
createProduct()
   ↓
ConcreteProduct
```
