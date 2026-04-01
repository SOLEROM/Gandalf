# Command Pattern — Operational Architecture Specification

## 1. Pattern Intent

Encapsulate a request as an object so that actions become first-class units that can be executed, queued, logged, retried, undone, or composed without coupling the caller to the execution logic.

The pattern separates **action triggering** from **action execution** by representing operations as command objects.

Primary architectural goal:

**Decouple the invoker of an operation from the object that performs it.**

---

## 2. Recognition Signals

An AI system should detect or recommend the Command Pattern when the following structural conditions appear:

* A controller or service contains **large `if/else` or `switch` statements selecting operations**
* Multiple user actions trigger **different behaviors on the same service**
* Operations must support:

  * undo/redo
  * retry
  * logging
  * queuing
  * delayed execution
* A system must **store or replay actions**
* UI or API layers directly call business logic methods
* There is tight coupling between **controllers/UI and business services**
* New operations require **editing existing logic blocks**

Typical smell:

```
Controller
   └─ switch(actionType)
        ├─ service.placeOrder()
        ├─ service.cancelOrder()
        └─ service.refundOrder()
```

This indicates **centralized procedural decision logic**, which the Command Pattern eliminates.

---

## 3. Core Invariant Rule

**Every executable action must be represented by a command object implementing a common command interface.**

Execution flow must always follow:

```
Invoker → Command Interface → Concrete Command → Receiver
```

Key invariants:

1. The **Invoker must depend only on the Command interface**
2. **Concrete Commands encapsulate the receiver and method invocation**
3. The **Receiver contains all business logic**
4. The **Client assembles command objects and assigns them to the invoker**

Violation examples:

* Invoker calling receiver methods directly
* Controller containing business logic
* Conditional branching selecting operations

---

## 4. Structural Roles

### Command Interface

Defines the contract for executing commands.

Responsibilities:

* Declare `execute()` method
* Optionally define `undo()` for reversible commands

Constraints:

* Must contain **no business logic**
* Must be implemented by all commands

Example contract:

```
interface Command {
    execute()
}
```

---

### Concrete Command

Encapsulates a specific action.

Responsibilities:

* Hold reference to a receiver
* Implement `execute()` by invoking receiver behavior

Constraints:

* Must contain **only orchestration logic**
* Must not implement business rules
* One class per action

Example structure:

```
class PlaceOrderCommand implements Command
    receiver: OrderService

    execute()
        receiver.placeOrder()
```

---

### Receiver

Contains the actual business logic.

Responsibilities:

* Perform domain operations
* Remain independent from command execution structure

Constraints:

* Must not reference command classes
* Must not know the invoker

Example:

```
class OrderService
    placeOrder()
    cancelOrder()
    refundOrder()
```

---

### Invoker

Triggers command execution.

Responsibilities:

* Hold a reference to a `Command`
* Call `execute()` without knowing implementation

Constraints:

* Must depend only on `Command` interface
* Must not reference receivers

Example:

```
class OrderInvoker
    command: Command

    setCommand(cmd)
    execute()
        command.execute()
```

---

### Client

Responsible for wiring the system.

Responsibilities:

* Instantiate receivers
* Create concrete commands
* Assign commands to invokers

Example:

```
service = OrderService()
cmd = PlaceOrderCommand(service)
invoker.setCommand(cmd)
invoker.execute()
```

---

## 5. Lifecycle / Concurrency Constraints

### Execution Decoupling

Commands must be executable independently of their creator.

### Queue Compatibility

Command objects must be **serializable or transferable** if used in task queues.

### Idempotency Considerations

Commands intended for retries must ensure:

* Safe re-execution
* Side-effect control

### Undo/Redo Support (Optional Extension)

Commands supporting reversal must include:

```
execute()
undo()
```

Undo operations must restore system state using stored command state.

### Command History

Undo/redo systems require:

```
Stack<Command> history
```

---

## 6. SOLID Alignment

### Single Responsibility Principle

* Commands encapsulate **one operation**
* Receivers encapsulate **business logic**

### Open/Closed Principle

New operations are added by **creating new command classes**, not modifying existing ones.

### Dependency Inversion Principle

Invoker depends on **Command abstraction**, not concrete implementations.

### Interface Segregation

Commands expose minimal contract (`execute`).

---

## 7. Implementation Rules for AI Agents

AI systems generating this pattern must follow these deterministic rules:

1. Always create a **Command interface**
2. Each operation must become a **separate command class**
3. Commands must contain:

   * reference to receiver
   * implementation of `execute`
4. Receivers contain **all business logic**
5. Invoker triggers commands using only the interface
6. Client code performs wiring
7. Remove all procedural operation selection (`switch`, `if`, enums)

Required structure:

```
Command Interface
Concrete Commands
Receiver
Invoker
Client Wiring
```

---

## 8. Prompt Constraints for AI Code Generation

To enforce correct generation, prompts must include the following constraints:

Required instructions:

* “Implement using the Command Pattern”
* “Create a Command interface with execute()”
* “Encapsulate each action in a concrete command”
* “Include a receiver class containing business logic”
* “Invoker must depend only on the Command interface”
* “Do not use switch statements or if/else action dispatch”

Example prompt constraint:

```
Generate code using the Command Pattern with:

- Command interface
- Concrete command classes
- Receiver containing business logic
- Invoker triggering commands
- No procedural dispatch logic
```

---

## 9. Deterministic Refactoring Steps

Convert procedural action logic into the Command Pattern using the following sequence:

### Step 1 — Identify Operations

Locate switch/if blocks selecting actions.

```
switch(action)
   placeOrder()
   cancelOrder()
```

---

### Step 2 — Extract Receiver

Move business logic into a dedicated service class.

```
OrderService
   placeOrder()
   cancelOrder()
```

---

### Step 3 — Create Command Interface

```
interface Command
    execute()
```

---

### Step 4 — Create Concrete Commands

```
PlaceOrderCommand
CancelOrderCommand
RefundOrderCommand
```

Each command holds the receiver.

---

### Step 5 — Introduce Invoker

```
class OrderInvoker
    command: Command
    execute()
```

---

### Step 6 — Move Dispatch Logic to Client

Client decides which command to instantiate.

---

### Step 7 — Remove Conditional Logic

Delete switch statements and procedural controllers.

---

## 10. Common AI Generation Errors

### Procedural Controller

AI outputs:

```
switch(actionType)
```

Correction:

* Replace with concrete command classes.

---

### Missing Command Interface

AI creates classes but no shared interface.

Correction:

* Introduce `Command` abstraction.

---

### Business Logic in Command

Commands contain domain logic.

Correction:

* Move logic to receiver.

---

### Invoker Coupled to Concrete Commands

Invoker references specific command classes.

Correction:

* Depend on the `Command` interface only.

---

### Receiver Awareness

Receiver referencing command classes.

Correction:

* Receivers must remain unaware of command structure.

---

## 11. Verification Checklist

A valid implementation must satisfy all checks:

* [ ] A `Command` interface exists
* [ ] Every action is a concrete command class
* [ ] Commands implement `execute()`
* [ ] Commands hold a receiver reference
* [ ] Business logic resides only in receivers
* [ ] Invoker depends only on the `Command` interface
* [ ] Client wires commands to invokers
* [ ] No switch or if/else dispatch exists
* [ ] New actions require adding new command classes only
* [ ] Commands can be queued or stored

---

## 12. Minimal Structural Diagram

```
            Client
              │
              ▼
        +-----------+
        |  Invoker  |
        +-----------+
              │
              ▼
        +-----------+
        |  Command  | (interface)
        +-----------+
           ▲      ▲
           │      │
   +--------------+--------------+
   |                             |
+----------------+     +----------------+
| PlaceCommand   |     | CancelCommand  |
+----------------+     +----------------+
           │
           ▼
      +-----------+
      | Receiver  |
      | (Service) |
      +-----------+
```

Dependency direction:

```
Invoker → Command Interface
Command → Receiver
Client → Concrete Commands
```
