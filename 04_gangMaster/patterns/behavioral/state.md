# State Pattern — Operational Architecture Specification

## 1. Pattern Intent

Encapsulate behavior that varies based on an object's internal state by delegating state-dependent behavior to separate state objects.
Enable the context object to change behavior dynamically at runtime through state transitions without modifying the context class.

Primary goals:

* Eliminate conditional branching (`if`, `switch`) controlling behavior by state.
* Isolate state-specific logic into independent classes.
* Allow runtime behavioral change via state substitution.
* Preserve **Open–Closed Principle (OCP)** and **Single Responsibility Principle (SRP)**.

---

# 2. Recognition Signals

An AI agent should infer the **State Pattern** when the following signals appear in code or requirements:

### Structural Indicators

* A class maintains a **status/state field** (e.g., `status`, `state`, `mode`).
* Multiple methods check this field using conditional logic.

Examples:

```
if (status == DRAFT)
if (status == PUBLISHED)
switch(status)
```

### Behavioral Indicators

* Different behavior is required depending on the object's current condition.
* Valid operations change depending on lifecycle phase.
* State transitions occur after operations.

### Refactoring Signals

Large classes containing:

* many `if/else` blocks
* `switch` on status enums
* behavior tightly coupled with state values

These indicate a **state-dependent behavioral cluster**.

---

# 3. Core Invariant Rule

**The context object must never implement state-specific conditional logic.**

All state-dependent behavior must be delegated to the **current state object**, which determines both:

1. behavior execution
2. valid transitions to other states

Invariant:

```
Context delegates behavior → Current State
State decides → Next State
```

---

# 4. Structural Roles

## Context

The object whose behavior changes based on state.

Responsibilities:

* Hold reference to the current state.
* Delegate state-dependent operations.
* Provide a method allowing states to change the current state.

Constraints:

* Must **not implement conditional state logic**.
* Must **not implement transition rules**.

Example responsibilities:

```
state.publish(this)
state.archive(this)
```

---

## State Interface

Defines the contract for all state behaviors.

Characteristics:

* Declares all operations whose behavior varies by state.
* Must be implemented by every concrete state.

Example structure:

```
interface State {
    publish(Context context)
    archive(Context context)
}
```

---

## Concrete State

Implements behavior for a specific state.

Responsibilities:

* Implement state-specific logic.
* Determine valid transitions.
* Update the context's current state when transitions occur.

Example states:

```
DraftState
PublishedState
ArchivedState
```

Each state controls its own transition logic.

---

# 5. Lifecycle and Transition Constraints

### State Ownership

Context owns exactly **one active state instance**.

```
Context.state ≠ null
```

### Transition Control

Transitions must occur **inside state classes**, never in the context.

Valid pattern:

```
DraftState.publish(context)
    → context.setState(PublishedState)
```

Invalid pattern:

```
if(state == Draft)
    state = Published
```

### Runtime Behavior Mutation

Behavior must change dynamically by replacing the state object.

```
context.state = newState
```

---

# 6. SOLID Alignment

### Single Responsibility Principle (SRP)

Each state class encapsulates behavior specific to one state.

```
DraftState → rules for draft behavior
PublishedState → rules for published behavior
```

### Open–Closed Principle (OCP)

New states can be added without modifying the context.

Extension pattern:

```
class UnderReviewState implements State
```

No changes required in `Context`.

### Dependency Inversion Principle (DIP)

```
Context → depends on State interface
ConcreteState → implements State
```

Context must not depend on concrete states.

---

# 7. Implementation Rules for AI Agents

When generating a **State Pattern implementation**, an AI coding system must enforce:

### Rule 1 — State Interface Creation

Define a single interface representing all state-dependent actions.

Example:

```
State
    operationA()
    operationB()
```

---

### Rule 2 — Concrete State Isolation

Each state must exist as a separate class.

Prohibited:

```
class Context {
   if(state == A) ...
}
```

Required:

```
class StateA implements State
class StateB implements State
```

---

### Rule 3 — Delegation

All context methods must delegate behavior.

Required structure:

```
methodX():
    state.methodX(this)
```

---

### Rule 4 — Transition Ownership

Only state classes perform transitions.

Example:

```
context.setState(newState)
```

inside state implementation.

---

### Rule 5 — Context Minimalism

Context responsibilities are limited to:

* holding state
* delegating actions
* allowing state replacement

No additional state logic allowed.

---

# 8. Prompt Constraints for AI Code Generation

When instructing an AI system to generate this pattern, prompts must explicitly enforce:

```
Create a State interface defining all state-dependent actions.

Implement separate concrete classes for each state.

Ensure the Context class delegates behavior to the current state.

Transitions must be implemented inside state classes.

Avoid conditional logic based on state values.
```

Hard constraints:

* Do not use `switch` or `if` on state enums.
* Do not place behavior logic in the context.

---

# 9. Deterministic Refactoring Steps

When converting naive state logic into the State Pattern:

### Step 1 — Identify State Variable

Example:

```
status
mode
phase
```

---

### Step 2 — Extract State Interface

Move state-dependent methods into a new interface.

---

### Step 3 — Create Concrete States

For each possible state value:

```
StateValue → ConcreteStateClass
```

---

### Step 4 — Move Behavior

Transfer conditional branch logic into corresponding state classes.

Example transformation:

```
if status == Draft → DraftState.publish()
```

---

### Step 5 — Replace Conditionals With Delegation

Convert context methods:

```
publish() {
   state.publish(this)
}
```

---

### Step 6 — Move Transitions

Convert state changes to:

```
context.setState(NewState)
```

inside state classes.

---

# 10. Common AI Generation Errors

### Error 1 — Monolithic Context Class

AI merges all state logic into the context.

Example (invalid):

```
if(state == Draft)
if(state == Published)
```

---

### Error 2 — Enum-Based State Control

AI uses enum states instead of state objects.

Example:

```
enum State { DRAFT, PUBLISHED }
```

This recreates conditional logic.

---

### Error 3 — Missing State Interface

Concrete states exist but lack a shared contract.

---

### Error 4 — Context Handles Transitions

Context manually switches state values.

Invalid:

```
if(state == Draft)
    state = Published
```

---

### Error 5 — Shared Logic Across States

AI merges behaviors into a shared helper rather than state implementations.

---

# 11. Verification Checklist

A valid State Pattern implementation must satisfy all conditions:

* [ ] Context contains a **state reference**
* [ ] Context delegates behavior to the state
* [ ] A **state interface exists**
* [ ] Every state is implemented as a **separate class**
* [ ] No conditional logic exists in the context
* [ ] State classes determine transitions
* [ ] Adding a new state does not modify the context
* [ ] All state behavior is encapsulated inside concrete state classes

If any of these fail, the implementation is not a valid State Pattern.

---

# 12. Minimal Structural Diagram

```
        +------------------+
        |      Context     |
        |------------------|
        | state: State     |
        |------------------|
        | actionA()        |
        | actionB()        |
        +--------+---------+
                 |
                 v
           +-----------+
           |   State   |  (interface)
           +-----------+
           | actionA() |
           | actionB() |
           +-----+-----+
                 |
      -------------------------
      |           |           |
      v           v           v
+-----------+ +-----------+ +-----------+
| StateA    | | StateB    | | StateC    |
+-----------+ +-----------+ +-----------+
| behavior  | | behavior  | | behavior  |
| transition| | transition| | transition|
+-----------+ +-----------+ +-----------+
```

Dependency direction:

```
Context → State Interface
Concrete States → implement State
States → update Context state
```
