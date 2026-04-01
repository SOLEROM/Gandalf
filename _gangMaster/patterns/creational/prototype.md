# Prototype Pattern — Operational Architecture Specification

## 1. Pattern Intent

Enable efficient object creation by **cloning a fully initialized instance (prototype)** instead of constructing new instances through repeated initialization logic.
The pattern eliminates redundant setup, preserves configuration consistency, and reduces object creation cost when initialization is expensive.

Primary goal: **Reuse initialized state while producing independent instances.**

---

## 2. Recognition Signals

An AI system should identify a candidate for the Prototype Pattern when the following signals exist:

* Object constructors contain **expensive initialization logic** (I/O, configuration loading, template setup, metadata initialization).
* Multiple instances of the same class are created with **mostly identical configuration**.
* Repeated constructor calls trigger **identical initialization sequences**.
* Object creation occurs frequently inside loops or factories with **small variations in state**.
* Performance issues originate from **repeated initialization of similar objects**.
* AI-generated code repeatedly executes complex setup logic for each object creation.
* Initialization logic is **deterministic and reusable** across instances.

---

## 3. Core Invariant Rule

All instances must originate from a **pre-initialized prototype object via cloning**, not from repeated reconstruction.

Invariant conditions:

* Initialization logic executes **exactly once per prototype instance**.
* Cloned objects must be **independent copies**.
* Cloning must replicate **all required state**, including nested structures.
* Client code must **not perform initialization logic directly**.

---

## 4. Structural Roles

### Prototype (Abstract Role)

Defines the cloning contract.

Responsibilities:

* Declare `clone()` operation.
* Guarantee correct copying semantics.

Typical interface:

```
interface Prototype {
    Prototype clone();
}
```

---

### ConcretePrototype

Implements cloning logic and owns the initialization state.

Responsibilities:

* Maintain object configuration and state.
* Implement cloning behavior.
* Handle deep copying of mutable structures.

Example responsibility set:

```
class Document implements Prototype {
    String header
    String footer
    List<Page> pages

    clone()
}
```

---

### Prototype Registry (Optional Role)

Stores reusable prototype instances when multiple prototype templates exist.

Responsibilities:

* Maintain prototype lookup.
* Provide clone requests.

Example interface:

```
registry.get("standardDoc").clone()
```

---

### Client

Requests object creation through cloning.

Responsibilities:

* Obtain prototype reference.
* Invoke `clone()`.

The client must **not perform heavy initialization or reconstruction logic**.

---

## 5. Lifecycle and Concurrency Constraints

Initialization Phase

* Prototype must be **fully initialized before cloning begins**.

Cloning Phase

* Clones must be **structurally identical but state-independent**.

Deep Copy Requirement

* Mutable collections or nested objects must be deep-copied.

Concurrency Safety

* Prototype objects must be **immutable or synchronized** if accessed concurrently.
* Cloning operations must **not mutate the prototype state**.

Mutation Rule

* Post-clone mutations must only affect the clone.

---

## 6. SOLID Alignment

### Single Responsibility Principle

Initialization logic resides in the prototype, while clients focus only on using clones.

### Open/Closed Principle

New prototype variants can be introduced without modifying client logic.

### Liskov Substitution Principle

All concrete prototypes must provide consistent cloning behavior.

### Interface Segregation Principle

Clients depend only on the cloning contract.

### Dependency Inversion Principle

Clients depend on `Prototype` abstraction rather than concrete classes.

---

## 7. Implementation Rules for AI Agents

AI-generated implementations must satisfy the following rules:

1. Classes eligible for cloning must implement a **clone contract**.
2. Heavy initialization must occur **once during prototype construction**.
3. Object creation paths must use **clone operations instead of constructors**.
4. Clone implementation must replicate:

   * primitive fields
   * immutable fields
   * mutable nested structures
5. Collections must be copied using **deep cloning**.
6. Prototype objects must **not be mutated during cloning**.
7. Client code must **never call expensive constructors repeatedly**.
8. Prototype initialization logic must remain **centralized in a single location**.

---

## 8. Prompt Constraints for AI Code Generation

When instructing AI coding systems, enforce the following directives:

Required instructions:

* Implement object creation using **prototype cloning**.
* Provide a `clone()` method within the prototype class.
* Ensure cloning handles **deep copying for nested objects or collections**.
* Avoid repeated heavy initialization inside constructors.
* Maintain **prototype initialization in a single location**.

Prohibited instructions:

* Recreating objects via repeated constructor calls.
* Copying references of mutable collections without duplication.
* Exposing cloning logic to client code.

---

## 9. Deterministic Refactoring Steps

When refactoring existing code that repeatedly constructs expensive objects:

Step 1
Identify classes where constructors perform heavy initialization.

Step 2
Extract the class as a **prototype-capable class** implementing a `clone()` method.

Step 3
Create a **fully initialized base instance** (prototype).

Step 4
Replace constructor calls with:

```
prototype.clone()
```

Step 5
Implement deep copy logic for mutable structures.

Step 6
Move initialization logic exclusively into prototype construction.

Step 7
Ensure client code only modifies cloned instances.

---

## 10. Common AI Generation Errors

AI-generated implementations frequently contain the following defects:

Repeated Constructor Invocation
AI repeatedly constructs objects instead of cloning.

Shallow Copy of Mutable Structures
Lists, maps, or nested objects are copied by reference.

Prototype Mutation
Clone logic modifies the original prototype.

Client-Aware Cloning Logic
Clients perform field copying manually.

Initialization Duplication
Initialization logic appears both in constructor and cloning paths.

State Leakage
Clones share mutable internal structures.

---

## 11. Verification Checklist

An implementation is valid only if all checks pass:

* [ ] Heavy initialization occurs only once in prototype creation.
* [ ] New instances are created using `clone()`.
* [ ] Cloned objects do not share mutable state with the prototype.
* [ ] Clone operation copies nested structures correctly.
* [ ] Client code does not repeat setup logic.
* [ ] Initialization logic exists in a single location.
* [ ] Constructor is not repeatedly invoked for identical configurations.
* [ ] Performance improves relative to repeated reconstruction.

---

## 12. Minimal Structural Diagram

```
        +------------------+
        |     Prototype     |
        |------------------|
        | + clone()        |
        +---------+--------+
                  ^
                  |
        +---------+----------------+
        |      ConcretePrototype    |
        |---------------------------|
        | state / configuration     |
        | heavy initialization      |
        | clone implementation      |
        +-------------+-------------+
                      |
                      v
                +-----------+
                |  Client   |
                |-----------|
                | clone()   |
                +-----------+
```

Dependency Direction

```
Client → Prototype Interface → ConcretePrototype
```
