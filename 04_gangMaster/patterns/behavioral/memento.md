# Memento Pattern — Operational Architecture Specification

## Pattern Intent

Provide a mechanism for capturing and restoring an object's internal state without exposing its internal representation.
Enable deterministic **undo, rollback, and checkpoint capabilities** while preserving encapsulation and preventing history management from polluting domain logic.

The pattern separates **state capture**, **state ownership**, and **history management** into distinct roles.

---

# Recognition Signals

An AI agent should detect the need for the Memento Pattern when the following conditions appear:

1. A system requires **undo, rollback, checkpoint, or revert functionality**.
2. The same object undergoes **multiple state transitions over time**.
3. Developers attempt to track previous values with variables like:

   * `previousValue`
   * `lastState`
   * `backup`
4. Undo capability is **embedded directly inside domain classes**.
5. State restoration must occur **without exposing internal object fields**.
6. Multiple levels of history are required (multi-step undo or redo).
7. The system requires **safe experimentation before committing changes**.

Typical domains:

* editors
* design tools
* games (checkpoints)
* forms
* in-memory transaction-like workflows

---

# Core Invariant Rule

**Only the Originator may create and restore its Memento.
External components must never access or modify the internal state stored in the Memento.**

The caretaker **stores snapshots but never interprets or modifies them**.

---

# Structural Roles

## Originator

Responsible for:

* owning the internal state
* creating snapshots
* restoring from snapshots

Capabilities:

* `createMemento()` → returns immutable snapshot
* `restore(memento)` → restores internal state

Constraints:

* Must not store history internally.
* Must not expose internal state structure.

---

## Memento

Represents a **snapshot of Originator state**.

Properties:

* Immutable
* Opaque to external components
* Contains only essential state required for restoration

Constraints:

* No setters
* No external mutation
* No business logic

The Memento may be:

* private nested class
* restricted access object
* immutable data object

---

## Caretaker

Responsible for **history management**.

Responsibilities:

* storing snapshots
* retrieving snapshots
* implementing undo/redo semantics

Typical storage:

* stack
* list
* ring buffer
* checkpoint map

Constraints:

* Cannot inspect or modify snapshot contents
* Cannot create snapshots
* Cannot restore state itself

---

# Lifecycle / Concurrency Constraints

## Snapshot Lifecycle

1. Caretaker requests snapshot from Originator
2. Originator creates immutable Memento
3. Caretaker stores snapshot
4. State modifications occur
5. Undo operation retrieves snapshot
6. Originator restores state

---

## Snapshot Validity

Snapshots must represent **consistent object state**.

Snapshots must not reference **mutable external dependencies** unless they are also captured.

---

## Concurrency Rules

If used in concurrent environments:

* Snapshot creation must be **atomic relative to state mutation**.
* Mementos must be **thread-safe immutable objects**.
* Caretaker history structure must enforce **synchronization if shared**.

---

# SOLID Alignment

## Single Responsibility Principle

Responsibilities are separated:

| Role       | Responsibility                            |
| ---------- | ----------------------------------------- |
| Originator | Business behavior + state capture/restore |
| Memento    | State storage                             |
| Caretaker  | History management                        |

---

## Open/Closed Principle

Undo behavior can expand (redo, branching history) without modifying originator logic.

---

## Encapsulation Preservation

Internal state representation **never leaks outside originator boundaries**.

---

# Implementation Rules for AI Agents

1. **Create three distinct roles**

   * Originator
   * Memento
   * Caretaker

2. **Memento must be immutable**

   * All fields final/read-only
   * No setters

3. **Originator must expose exactly two snapshot operations**

   ```
   createMemento()
   restore(memento)
   ```

4. **Caretaker stores snapshots**

   * stack for undo
   * optional secondary stack for redo

5. **Originator must not maintain history**

6. **Snapshot must capture only required state**
   Avoid cloning the entire object if unnecessary.

7. **Memento must not expose internal state publicly**

8. **History storage must be external to the originator**

9. **Snapshot creation must occur before mutating state**

---

# Prompt Constraints for AI Code Generation

To enforce correct architecture when prompting AI, include constraints:

Required instructions:

```
Implement the Memento Pattern with strict role separation.

Rules:
- Originator creates and restores mementos.
- Memento must be immutable.
- Caretaker manages history storage.
- Caretaker cannot access internal state of memento.
- Originator must not store history.
- Snapshot captures only essential state.
```

Optional constraints for stronger encapsulation:

```
- Implement Memento as a private nested class.
- Disallow setters on snapshot.
- Prevent external modification of stored snapshots.
```

---

# Deterministic Refactoring Steps

When refactoring a naive undo implementation:

### Step 1 — Identify manual state tracking

Locate fields like:

```
previousState
lastValue
backup
```

---

### Step 2 — Remove undo logic from the originator

Delete:

* history arrays
* previous value variables
* undo stacks

---

### Step 3 — Create Memento class

Convert stored state into immutable snapshot structure.

Example structure:

```
class Memento
    stateA
    stateB
```

---

### Step 4 — Add snapshot operations to originator

Add:

```
createMemento()
restore(memento)
```

---

### Step 5 — Introduce Caretaker

Create a history manager:

```
push(snapshot)
pop(snapshot)
```

---

### Step 6 — Move history storage to caretaker

Replace internal history with caretaker-managed stack.

---

### Step 7 — Enforce immutability

Ensure:

* snapshot fields immutable
* no setters

---

# Common AI Generation Errors

## Role Merging

AI often merges caretaker into originator.

Invalid structure:

```
Document {
  historyStack
}
```

Correction:
History must exist in separate caretaker.

---

## Mutable Mementos

Snapshots created with setters or public fields.

Risk:
Undo history becomes corrupted.

Correction:
Make snapshot immutable.

---

## Exposed Internal State

AI exposes fields like:

```
memento.getContent()
```

Risk:
Breaks encapsulation.

Correction:
Only originator should read snapshot data.

---

## Full Object Cloning

AI duplicates entire objects instead of capturing essential state.

Impact:

* memory overhead
* performance degradation

Correction:
Capture only minimal restoration state.

---

## Direct Field Restoration by Caretaker

Caretaker manipulates originator state.

Invalid:

```
originator.content = memento.content
```

Correction:
Caretaker must call originator restore method.

---

# Verification Checklist

AI-generated implementation is valid only if:

* [ ] Originator owns internal state
* [ ] Memento is immutable
* [ ] Caretaker stores snapshots
* [ ] Originator does not store history
* [ ] Caretaker cannot inspect snapshot state
* [ ] Snapshot creation occurs before mutation
* [ ] Restore logic exists only in originator
* [ ] Multiple undo operations are supported
* [ ] Encapsulation is preserved

---

# Minimal Structural Diagram

```
        +----------------+
        |   Caretaker    |
        |  (History)     |
        +--------+-------+
                 |
                 | stores
                 v
            +----+------+
            |  Memento  |
            | (Snapshot)|
            +----+------+
                 ^
                 | create / restore
        +--------+--------+
        |   Originator    |
        |  (State Owner)  |
        +-----------------+
```
