# Abstract Factory Pattern — Operational Architecture Specification

---

# 1. Pattern Intent

Provide an abstraction for creating **families of related or dependent objects** without specifying their concrete classes.

The pattern ensures that all objects created by a factory belong to the **same compatible product family**, preventing mismatched combinations.

Primary architectural objective:

> Systems must produce coordinated sets of objects through a unified factory interface while remaining independent of concrete implementations.

The pattern separates:

* **Object creation (factory layer)**
* **Object usage (client logic)**

and enforces **family consistency across products**.

---

# 2. Recognition Signals

An AI agent should recognize the need for the Abstract Factory pattern when the following conditions exist:

1. The system creates **multiple related product types**.
2. Products must be **compatible within the same family**.
3. Conditional logic selects **environment variants** (e.g., platform, theme, provider).
4. Multiple product objects must be created **together and coordinated**.
5. Object creation is embedded in application logic.
6. Adding a new variant requires modifying existing code.

Typical domains:

* Cross-platform UI systems
* Theme engines
* Payment gateway integrations
* Database provider drivers
* Plugin modules
* Device driver stacks

---

# 3. Core Invariant Rule

A client must obtain **all related objects from the same factory instance**.

This guarantees family compatibility.

Invariant constraint:

```
Client → Abstract Factory → Product Interfaces
Concrete Factory → Concrete Product Family
```

No client logic may instantiate concrete products directly.

---

# 4. Structural Roles

## Abstract Factory

Defines creation methods for each product type in the family.

Responsibilities:

* Declare factory methods for every product category.
* Provide a unified creation interface.
* Enforce product family grouping.

Example structure:

```
IUIFactory
 ├─ createButton()
 └─ createCheckbox()
```

Constraints:

* Contains **no platform-specific logic**
* Only declares contracts for object creation

---

## Concrete Factory

Implements the abstract factory and produces **one specific product family**.

Responsibilities:

* Instantiate concrete products belonging to the same variant.
* Maintain compatibility within the family.

Examples:

```
WindowsUIFactory
MacUIFactory
LinuxUIFactory
```

Constraints:

* Must produce only products belonging to the same family.
* Must not mix implementations from different families.

Example mapping:

```
WindowsUIFactory
 ├─ createButton() → WindowsButton
 └─ createCheckbox() → WindowsCheckbox
```

---

## Abstract Product

Defines the interface for a specific product type.

Each product category has its own abstraction.

Example interfaces:

```
IButton
ICheckbox
IMenu
```

Constraints:

* Must define behavior used by the client.
* Must not depend on factories.

---

## Concrete Product

Implements an abstract product for a specific family.

Examples:

```
WindowsButton
MacButton
WindowsCheckbox
MacCheckbox
```

Constraints:

* Must conform to its product interface.
* Must remain compatible with products from the same factory.

---

## Client

Uses only **abstract factories and abstract products**.

Responsibilities:

* Request products from the factory.
* Operate exclusively on interfaces.

Constraints:

* Must never reference concrete product classes.
* Must never contain environment-selection logic.

Example dependency:

```
Application → IUIFactory
Application → IButton
Application → ICheckbox
```

---

# 5. Lifecycle and Concurrency Constraints

Creation lifecycle rules:

1. A factory instance represents **one product family context**.
2. All products requested from a factory must belong to the same variant.
3. Factories should remain **stateless** unless configuration requires otherwise.
4. Factories may internally reuse product instances only if safe and documented.

Concurrency rules:

* Factory implementations must be thread-safe if shared.
* Products must not assume singleton usage unless explicitly defined.

---

# 6. SOLID Alignment

### Single Responsibility Principle

Factories handle creation; products handle behavior.

---

### Open/Closed Principle

New product families are introduced by adding new concrete factories.

Existing code remains unchanged.

---

### Liskov Substitution Principle

All products must remain substitutable via their interfaces.

---

### Interface Segregation Principle

Each product type has its own interface.

Clients depend only on relevant abstractions.

---

### Dependency Inversion Principle

Client logic depends on:

```
Abstract Factory
Abstract Product Interfaces
```

not concrete implementations.

---

# 7. Implementation Rules for AI Agents

When implementing Abstract Factory, the AI must enforce these constraints:

1. Define **abstract product interfaces** for each product category.
2. Define a **single abstract factory** containing creation methods for all products.
3. Implement **one concrete factory per product family**.
4. Ensure each concrete factory creates only its corresponding product variants.
5. Ensure clients interact only with:

```
AbstractFactory
AbstractProduct
```

6. Remove all conditional platform logic.
7. Ensure product compatibility is enforced through factory selection.

Correct dependency direction:

```
Client → AbstractFactory → AbstractProduct
ConcreteFactory → ConcreteProduct
```

---

# 8. Prompt Constraints for AI Code Generation

Prompts must explicitly specify family relationships.

Required prompt structure:

```
Use the Abstract Factory pattern.

Define:
1. Abstract product interfaces for each product type.
2. An abstract factory interface containing creation methods.
3. Concrete factories for each product family.
4. Concrete products implementing the interfaces.

Ensure:
- Each factory produces only one consistent product family.
- The client depends only on interfaces.
- No conditionals determine product variants.
```

Optional extension instruction:

```
Support adding new product families without modifying existing factories or clients.
```

---

# 9. Deterministic Refactoring Steps

When refactoring code lacking Abstract Factory:

### Step 1 — Identify Variant Logic

Locate conditional structures:

```
if(platform == "Windows")
if(platform == "Mac")
switch(platform)
```

---

### Step 2 — Extract Product Interfaces

Define interfaces for each product category.

Example:

```
IButton
ICheckbox
```

---

### Step 3 — Introduce Abstract Factory

Define a factory interface containing creation methods.

Example:

```
IUIFactory
 ├ createButton()
 └ createCheckbox()
```

---

### Step 4 — Implement Concrete Factories

Create a factory for each platform or family.

```
WindowsUIFactory
MacUIFactory
```

---

### Step 5 — Move Instantiation Logic

Transfer all `new` operations into the corresponding concrete factories.

---

### Step 6 — Remove Conditional Logic

Delete platform selection logic from application classes.

---

### Step 7 — Inject Factory Into Client

Client receives the factory via constructor or configuration.

Example:

```
Application(factory: IUIFactory)
```

---

# 10. Common AI Generation Errors

### Error 1 — Conditional Object Creation

```
if(platform == "Windows")
   new WindowsButton()
```

Violation: Creation logic remains centralized.

---

### Error 2 — Mixed Product Families

```
WindowsButton + MacCheckbox
```

Violation: Family consistency broken.

---

### Error 3 — Client Depends on Concrete Classes

```
Application → WindowsButton
```

Violation: Breaks abstraction boundary.

---

### Error 4 — Separate Factories Per Product

Creating independent factories for each product type rather than family grouping.

---

### Error 5 — Missing Abstract Factory

AI sometimes implements multiple factory methods without grouping them under a common interface.

---

# 11. Verification Checklist

Implementation validity requires all checks to pass.

✔ Client depends only on abstract factory
✔ Client uses only abstract product interfaces
✔ No conditional platform logic exists
✔ Each concrete factory produces one consistent product family
✔ No product mixing occurs between families
✔ Adding a new family requires only a new concrete factory and products
✔ Existing client code remains unchanged

---

# 12. Minimal Structural Diagram

```
                Client
                  │
                  ▼
            AbstractFactory
         ┌────────┴────────┐
         │                 │
   createButton()    createCheckbox()
         │                 │
         ▼                 ▼
     IButton           ICheckbox
         ▲                 ▲
         │                 │
   ┌───────────────┐ ┌───────────────┐
   │               │ │               │
WindowsFactory  MacFactory
   │               │
   ▼               ▼
WindowsButton   MacButton
WindowsCheckbox MacCheckbox
```

Dependency direction:

```
Client → AbstractFactory → AbstractProducts
ConcreteFactory → ConcreteProducts
```

Family constraint:

```
FactoryInstance → One Product Family Only
```

