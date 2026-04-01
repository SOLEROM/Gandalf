# Strategy Pattern — Architecture Specification

---

## 1. Pattern Intent

Encapsulate interchangeable algorithms behind a common interface so that the **behavior of a system can vary independently from the context that uses it**.

The pattern isolates algorithmic variability into separate units while keeping the controlling workflow stable.

Primary objectives:

* Remove conditional logic used to select behavior.
* Enable runtime or configuration-based algorithm substitution.
* Preserve **Open/Closed Principle (OCP)** by allowing new behaviors without modifying the context.
* Ensure algorithms are independently testable.

---

## 2. Recognition Signals

An AI system should detect the need for Strategy Pattern when the following signals appear:

1. A class contains **multiple conditional branches (`if/else`, `switch`) selecting algorithm variants**.
2. A method performs **two responsibilities simultaneously**:

   * selecting which behavior to run
   * implementing the behavior itself.
3. Multiple behaviors share:

   * the same **goal**
   * different **implementation logic**.
4. Business rules frequently introduce **new behavior variants**.
5. Algorithms must be **independently testable**.
6. The system must support **runtime algorithm substitution**.

Typical domains:

* payment processing
* discount engines
* scoring systems
* compression engines
* shipping cost calculation
* routing or decision engines
* algorithm selection frameworks

---

## 3. Core Invariant Rule

**The context must depend only on the strategy interface and must never contain conditional logic that selects algorithm implementations.**

All behavioral variation must exist exclusively inside concrete strategy classes implementing the same interface.

---

## 4. Structural Roles

### 1. Context

Responsibilities:

* Owns the operational workflow.
* Holds a reference to a strategy interface.
* Delegates algorithm execution to the strategy.

Constraints:

* Must not implement algorithm logic.
* Must not contain branching logic for algorithm selection.

Example responsibility:

```
result = strategy.execute(input)
```

---

### 2. Strategy Interface

Responsibilities:

* Defines the **contract for the algorithm family**.

Constraints:

* Must expose a single cohesive behavior contract.
* Must not contain implementation logic.

Example interface:

```
Strategy.execute(input) -> result
```

---

### 3. Concrete Strategies

Responsibilities:

* Implement a specific algorithm variant.

Constraints:

* Must implement the strategy interface.
* Must contain **only algorithm logic**, not routing logic.
* Must remain independently testable.

Examples:

```
StandardShippingStrategy
ExpressShippingStrategy
OvernightShippingStrategy
```

---

## 5. Lifecycle / Concurrency Constraints

Strategy objects may be:

### Injected

The preferred approach.

```
Context(strategy)
```

Dependency injection enables runtime selection.

### Configured

Strategy chosen via configuration or factory outside the context.

### Runtime Switched

Context allows changing strategies dynamically.

Thread safety considerations:

* Strategies should be **stateless when possible**.
* If stateful, lifecycle must be controlled externally.

---

## 6. SOLID Alignment

**Single Responsibility Principle**

* Each strategy encapsulates one algorithm.

**Open/Closed Principle**

* New behaviors are added as new strategies.

**Liskov Substitution Principle**

* All strategies must behave interchangeably via the interface.

**Interface Segregation Principle**

* Strategy interface must contain only the required algorithm contract.

**Dependency Inversion Principle**

* Context depends on abstraction (Strategy interface), not implementations.

---

## 7. Implementation Rules for AI Agents

AI-generated implementations must enforce the following rules:

1. Define a **strategy interface** representing the algorithm contract.
2. Implement **one class per algorithm variant**.
3. Ensure **each concrete strategy implements the interface**.
4. The context must **receive the strategy via constructor or setter**.
5. Context methods must **delegate execution to the strategy**.
6. The context must contain **zero algorithm branches**.
7. Each strategy must contain **only algorithm logic**.
8. Strategies must be **unit-testable in isolation**.
9. Algorithm selection must occur **outside the context** (factory, configuration, DI container).

---

## 8. Prompt Constraints for AI Code Generation

When instructing AI systems to generate this pattern, enforce the following constraints:

**Required constraints**

* "Create a strategy interface representing the algorithm."
* "Implement each algorithm as a separate class."
* "The context must depend only on the interface."
* "No `if/else` or `switch` statements inside the context."
* "Each strategy must be independently testable."
* "Use delegation from context to strategy."

**Example prompt constraint**

```
Implement using the Strategy Pattern.

Requirements:
- Define a strategy interface.
- Each algorithm must be implemented in a separate class.
- The context must contain no conditionals.
- The context must delegate execution to the strategy.
```

---

## 9. Deterministic Refactoring Steps

When converting conditional logic into Strategy Pattern:

### Step 1 — Identify the Algorithm Variants

Locate conditional logic selecting behavior.

Example:

```
if (shippingType == EXPRESS)
if (shippingType == STANDARD)
```

---

### Step 2 — Extract Algorithm Contract

Create a strategy interface.

```
interface ShippingStrategy
    calculate(order)
```

---

### Step 3 — Extract Concrete Strategies

Move each algorithm implementation into a separate class.

```
StandardShippingStrategy
ExpressShippingStrategy
OvernightShippingStrategy
```

---

### Step 4 — Remove Conditional Logic

Delete branching logic from the original class.

---

### Step 5 — Introduce Strategy Dependency

Inject the strategy into the context.

```
ShippingService(strategy)
```

---

### Step 6 — Delegate Execution

Context delegates algorithm execution.

```
strategy.calculate(order)
```

---

### Step 7 — Externalize Strategy Selection

Move algorithm selection to:

* configuration
* factory
* dependency injection

---

## 10. Common AI Generation Errors

### 1. Fake Strategy Implementation

AI names classes `Strategy` but still includes conditional logic.

Invalid pattern signal:

```
switch(strategyType)
```

---

### 2. Missing Interface

AI generates concrete classes without a shared interface.

Result:

* polymorphism is lost
* pattern collapses.

---

### 3. Algorithm Inside Context

Context still contains the algorithm implementation.

Violation:

* breaks SRP
* prevents extensibility.

---

### 4. Context Selecting Strategy

Context decides which strategy to use.

Example violation:

```
if(type == EXPRESS)
    strategy = new ExpressStrategy()
```

Strategy selection must occur outside the context.

---

### 5. Monolithic Strategy Class

AI creates one class with multiple algorithms.

Example violation:

```
class ShippingStrategy
   calculate(type)
```

This recreates conditional complexity.

---

## 11. Verification Checklist

An implementation satisfies the Strategy Pattern only if all checks pass.

* [ ] A strategy interface defines the algorithm contract.
* [ ] Multiple concrete strategies implement the interface.
* [ ] Each strategy encapsulates exactly one algorithm.
* [ ] Context depends only on the strategy interface.
* [ ] Context contains no conditional logic selecting algorithms.
* [ ] Strategy selection occurs outside the context.
* [ ] Strategies can be tested independently.
* [ ] Adding a new algorithm requires **only adding a new strategy class**.

---

## 12. Minimal Structural Diagram

```
                +-------------------+
                |      Context      |
                |-------------------|
                | - strategy        |
                |-------------------|
                | execute()         |
                +---------+---------+
                          |
                          v
                +-------------------+
                |     Strategy      |
                |-------------------|
                | execute(data)     |
                +---------+---------+
                          ^
          ----------------|----------------
          |               |               |
          v               v               v
+----------------+ +----------------+ +----------------+
| ConcreteStratA | | ConcreteStratB | | ConcreteStratC |
|----------------| |----------------| |----------------|
| execute(data)  | | execute(data)  | | execute(data)  |
+----------------+ +----------------+ +----------------+
```
