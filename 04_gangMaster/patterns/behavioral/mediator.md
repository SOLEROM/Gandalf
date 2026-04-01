# Mediator Pattern — Architecture Specification

## 1. Pattern Intent

Centralize communication between interacting objects to eliminate direct dependencies between them.
All interaction logic is delegated to a mediator component, allowing participating objects to remain independent and focused on their own responsibilities.

The pattern reduces coupling, simplifies coordination logic, and improves maintainability and extensibility of systems with many interacting components.

---

## 2. Recognition Signals

An AI agent should recognize the Mediator pattern when the following signals appear in a system:

* Multiple objects interact with each other through direct references.
* Interaction logic is scattered across many classes.
* Objects contain logic that manipulates or triggers behavior in other objects.
* Adding a new participant requires modifying several existing classes.
* Event-handling logic is embedded inside UI components or service objects.
* A centralized coordinator can logically control message routing or workflow steps.

Typical domains:

* UI component coordination
* Chat or messaging systems
* Workflow orchestration
* Service coordination layers
* Event-driven interaction between modules

---

## 3. Core Invariant Rule

Objects participating in the system **must never communicate directly with each other**.

All interaction must flow through the mediator.

```
Colleague → Mediator → Colleague
```

The mediator is the only component allowed to know about multiple colleagues simultaneously.

---

## 4. Structural Roles

### Mediator (Interface)

Defines the communication contract used by colleagues to notify events.

Responsibilities:

* Declare notification or coordination methods
* Abstract communication rules
* Decouple colleagues from implementation details

Example responsibilities:

* `Notify(sender, event)`
* `Send(message, sender)`
* `Coordinate(eventType, source)`

---

### ConcreteMediator

Implements the mediator interface and contains the coordination logic.

Responsibilities:

* Maintain references to participating colleagues
* Implement routing or orchestration logic
* Execute actions based on notifications from colleagues

Constraints:

* Must contain **interaction logic only**
* Must not contain business logic unrelated to coordination

---

### Colleague (Abstract or Base Component)

Represents participants that interact through the mediator.

Responsibilities:

* Maintain a reference to the mediator
* Notify mediator when events occur
* Execute actions requested by mediator

Constraints:

* Must never reference other colleagues directly
* Must delegate coordination decisions to the mediator

---

### ConcreteColleague

Specific system component that participates in the collaboration.

Examples:

* UI components (button, textbox)
* chat participants
* workflow services

Responsibilities:

* Trigger events
* Perform internal operations
* Notify mediator about changes

---

## 5. Lifecycle and Interaction Constraints

### Initialization

1. Mediator is created.
2. Colleagues are created.
3. Colleagues receive mediator reference via constructor or setter.
4. Mediator stores references to colleagues if coordination requires it.

---

### Interaction Flow

```
1. Colleague triggers internal event
2. Colleague calls mediator.Notify(...)
3. Mediator evaluates event
4. Mediator invokes actions on other colleagues
```

---

### Dependency Direction

```
Colleague → Mediator Interface
ConcreteMediator → Colleagues
```

Colleagues must depend only on the **mediator abstraction**, not its implementation.

---

## 6. SOLID Alignment

### Single Responsibility Principle

* Colleagues handle their own behavior.
* Mediator handles interaction orchestration.

### Open/Closed Principle

* New colleagues can be introduced without modifying existing colleagues.

### Dependency Inversion Principle

* Colleagues depend on mediator abstraction.

### Interface Segregation Principle

* Mediator interfaces should contain only coordination-related operations.

---

## 7. Implementation Rules for AI Agents

1. Always create a **Mediator interface**.
2. Implement a **ConcreteMediator** containing coordination logic.
3. Each colleague must:

   * store a mediator reference
   * notify mediator on events
4. Remove all direct colleague-to-colleague references.
5. Place communication decisions inside the mediator.
6. Avoid embedding orchestration logic inside colleagues.
7. Mediator may maintain references to colleagues if routing requires it.
8. Event notification methods should include sender identification.

Example notification signature:

```
Notify(Colleague sender, string eventType)
```

---

## 8. Prompt Constraints for AI Code Generation

When instructing AI systems to generate this pattern, the prompt must enforce:

* Create a mediator interface
* Separate mediator implementation class
* Colleagues communicate only through mediator
* Event notification pattern must be used
* No direct colleague references
* Coordination logic must exist only in mediator

Recommended naming conventions:

```
IMediator
ConcreteMediator

Colleague (base)
ConcreteColleagueA
ConcreteColleagueB
```

Domain-specific example naming:

```
IFormMediator
FormMediator
ButtonComponent
TextboxComponent
```

---

## 9. Deterministic Refactoring Steps

When converting tightly coupled components into a mediator architecture:

1. Identify direct object-to-object interactions.
2. Extract interaction logic from participating classes.
3. Create a mediator interface describing coordination operations.
4. Implement a concrete mediator class.
5. Inject mediator reference into each colleague.
6. Replace direct calls with mediator notifications.
7. Move coordination logic into mediator.
8. Remove all cross-references between colleagues.
9. Validate that colleagues depend only on mediator abstraction.

---

## 10. Common AI Generation Errors

### 1. Direct Colleague References

AI generates components that call each other directly.

Violation:

```
Button → TextBox
```

Correct:

```
Button → Mediator → TextBox
```

---

### 2. Missing Mediator Interface

AI creates only a concrete mediator class.

Consequence:

* Violates dependency inversion
* Reduces flexibility

---

### 3. Business Logic Inside Colleagues

AI embeds workflow or coordination logic inside components.

Correct rule:

* Coordination belongs only in mediator.

---

### 4. Mediator Without State

AI generates mediator without references to colleagues when coordination requires them.

Mediator must store references if it orchestrates interactions.

---

### 5. Event Logic Embedded in UI Classes

UI components perform routing logic themselves.

Correct design:
UI components only **notify mediator**.

---

## 11. Verification Checklist

An implementation is valid if the following conditions hold:

* [ ] No colleague references another colleague directly
* [ ] All interaction passes through mediator
* [ ] Mediator interface exists
* [ ] Concrete mediator implements the interface
* [ ] Colleagues contain mediator reference
* [ ] Coordination logic exists only in mediator
* [ ] Adding a new colleague does not require modifying existing colleagues
* [ ] Dependencies point toward mediator abstraction

---

## 12. Minimal Structural Diagram

```
          +------------------+
          |     Mediator     |
          |    (Interface)   |
          +---------+--------+
                    ^
                    |
          +---------+---------+
          |   ConcreteMediator |
          +---------+---------+
                    |
      ---------------------------------
      |               |               |
+-----------+   +-----------+   +-----------+
| Colleague |   | Colleague |   | Colleague |
|     A     |   |     B     |   |     C     |
+-----------+   +-----------+   +-----------+
      |               |               |
      -------- Notify Mediator -------
```

Dependency direction:

```
Colleagues → Mediator Interface
ConcreteMediator → Colleagues
```
