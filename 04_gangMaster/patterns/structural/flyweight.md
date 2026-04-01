# Flyweight Pattern — Architecture Specification for AI Coding Agents

---

## 1. Pattern Intent

Reduce memory consumption when a system must manage **large numbers of similar objects** by **sharing immutable state across instances** while externalizing unique state.

The pattern achieves memory efficiency by **separating object state into intrinsic (shared) and extrinsic (unique) components** without altering observable behavior.

The system guarantees that:

* Shared state is **stored once and reused**
* Unique state is **supplied at runtime by the client**
* Object identity is replaced with **shared instances retrieved via a factory cache**

Primary goal: **minimize memory footprint while preserving functional behavior.**

---

## 2. Recognition Signals

AI agents should recognize the Flyweight pattern opportunity when the following conditions appear:

1. The system instantiates **thousands or millions of similar objects**.
2. Large portions of object fields contain **identical repeated values**.
3. Memory usage grows **linearly with object count due to duplicated state**.
4. Object behavior **does not require internal mutation of shared fields**.
5. Many objects differ **only in a small subset of fields**.

Typical domains:

* text rendering (glyphs)
* UI icons
* map markers
* particle systems
* tiles in rendering engines
* repeated graphical elements

Red flag pattern:

```
for each item in largeDataset:
    new Object(sharedValueA, sharedValueB, sharedValueC, uniqueValue)
```

---

## 3. Core Invariant Rule

A valid Flyweight implementation **must enforce the following invariant**:

```
Shared (intrinsic) state MUST be immutable and stored in reusable flyweight objects.
Unique (extrinsic) state MUST NOT be stored inside the flyweight and MUST be supplied by the client at runtime.
```

Violation examples:

* storing extrinsic state inside flyweight
* creating new flyweights instead of retrieving cached ones
* mutable shared state

---

## 4. Structural Roles

### 4.1 Flyweight Interface

Defines the contract used by clients.

Responsibilities:

* declares operations that accept **extrinsic state parameters**
* ensures the flyweight does not internally depend on unique state

Constraints:

* must not contain extrinsic state fields
* operations must receive external data as arguments

---

### 4.2 Concrete Flyweight

Stores **intrinsic shared state only**.

Responsibilities:

* hold immutable shared data
* implement Flyweight interface behavior

Constraints:

* intrinsic state must be immutable
* no client-specific data stored
* instances must be shareable across many clients

---

### 4.3 Flyweight Factory

Centralized manager responsible for **instance reuse**.

Responsibilities:

* maintain a **cache of flyweight objects**
* return existing instances when intrinsic state matches
* create new flyweight only when no matching instance exists

Constraints:

* caching must be **keyed by intrinsic state**
* factory must prevent duplicate flyweights for identical intrinsic state

Typical structure:

```
Map<IntrinsicKey, Flyweight>
```

---

### 4.4 Client

Maintains **extrinsic state** and interacts with flyweights.

Responsibilities:

* store unique data
* request shared flyweights from factory
* pass extrinsic state during operations

Constraints:

* client must not instantiate flyweights directly
* client must supply extrinsic data during method invocation

---

## 5. Lifecycle and Concurrency Constraints

### Instance Lifecycle

1. Client requests flyweight from factory.
2. Factory checks cache for existing intrinsic state.
3. If present → return cached instance.
4. If absent → create flyweight and cache it.
5. Client stores extrinsic state separately.

### Concurrency Rules

If used in multithreaded systems:

* factory cache must be **thread-safe**
* flyweights must be **immutable**
* duplicate creation must be prevented under race conditions

Acceptable solutions:

* concurrent maps
* synchronized access
* double-checked caching

---

## 6. SOLID Alignment

**Single Responsibility Principle**

* Flyweight stores intrinsic data only.
* Client owns extrinsic state.
* Factory manages instance reuse.

**Open/Closed Principle**

* new flyweight types can be added without modifying clients.

**Liskov Substitution Principle**

* all concrete flyweights must conform to flyweight interface.

**Interface Segregation Principle**

* interface must expose only operations that depend on extrinsic input.

**Dependency Inversion Principle**

* clients depend on flyweight abstraction rather than concrete implementations.

---

## 7. Implementation Rules for AI Agents

Before generating code, the AI agent must perform the following analysis:

### Step 1 — State Classification

Produce a table:

```
Intrinsic State (shared, immutable)
Extrinsic State (unique, runtime supplied)
```

Example structure:

```
Intrinsic:
- style
- icon
- color

Extrinsic:
- coordinates
- position
- runtime context
```

---

### Step 2 — Extract Flyweight

Create a dedicated class containing only intrinsic fields.

Constraints:

* immutable
* reusable
* no runtime-specific data

---

### Step 3 — Create Flyweight Factory

Factory must:

* maintain cache
* key instances by intrinsic attributes
* reuse existing objects

Example structure:

```
class FlyweightFactory
    Map<Key, Flyweight> cache
```

---

### Step 4 — Refactor Client Objects

Client objects must:

* store extrinsic state
* reference flyweight instance

Client structure:

```
ClientObject
    Flyweight sharedState
    ExtrinsicState uniqueState
```

---

### Step 5 — Runtime Operation

Behavior must accept extrinsic data:

```
flyweight.operation(extrinsicState)
```

---

## 8. Prompt Constraints for AI Code Generation

When requesting Flyweight implementations, prompts must enforce architectural structure.

Required prompt components:

1. **List intrinsic vs extrinsic state**
2. **Extract intrinsic state into flyweight class**
3. **Create a flyweight factory with caching**
4. **Ensure client supplies extrinsic state at runtime**
5. **Demonstrate cache reuse behavior**

Example prompt template:

```
Identify intrinsic and extrinsic state.

Extract intrinsic state into a Flyweight class.

Implement a FlyweightFactory that caches instances by intrinsic state key.

Ensure client objects store only extrinsic state and reference shared flyweights.
```

---

## 9. Deterministic Refactoring Steps

When converting naive implementations:

### Step 1 — Detect duplication

Locate classes where repeated fields appear across thousands of instances.

### Step 2 — Separate state

Split fields into:

```
shared immutable fields
unique instance fields
```

### Step 3 — Extract shared state class

Create flyweight class for shared fields.

### Step 4 — Introduce factory cache

Add centralized factory returning shared instances.

### Step 5 — Replace duplicated fields

Original object now references flyweight instead of storing intrinsic fields.

### Step 6 — Move behavior parameters

Methods must receive extrinsic state externally.

---

## 10. Common AI Generation Errors

AI coding systems frequently generate incorrect flyweight implementations.

Typical failures:

### 1. Mixed State Objects

```
class Marker
    color
    icon
    size
    latitude
    longitude
```

No separation between intrinsic and extrinsic state.

---

### 2. Missing Factory

Flyweight objects instantiated directly rather than cached.

---

### 3. No Caching Mechanism

Factory creates new instance every request.

---

### 4. Mutable Shared State

Flyweight fields modified after creation.

---

### 5. Misleading Comments

Code labeled as “flyweight” while still duplicating state.

---

## 11. Verification Checklist

A correct Flyweight implementation must satisfy:

* [ ] intrinsic and extrinsic states clearly separated
* [ ] intrinsic state stored in flyweight object
* [ ] intrinsic state immutable
* [ ] extrinsic state not stored in flyweight
* [ ] flyweight instances reused via factory
* [ ] factory uses cache keyed by intrinsic attributes
* [ ] client requests flyweight from factory
* [ ] behavior receives extrinsic state at runtime
* [ ] no duplicate intrinsic objects created
* [ ] memory footprint reduced relative to naive implementation

---

## 12. Minimal Structural Diagram

```
             +--------------------+
             |     Flyweight      |
             |  (interface)       |
             +----------+---------+
                        |
                        v
             +--------------------+
             |  ConcreteFlyweight |
             |  intrinsic state   |
             +----------+---------+
                        ^
                        |
             +--------------------+
             |  FlyweightFactory  |
             |  cache: Map<Key,F> |
             +----------+---------+
                        ^
                        |
             +--------------------+
             |       Client       |
             | extrinsic state    |
             | holds Flyweight    |
             +--------------------+
```

Dependency direction:

```
Client → FlyweightFactory → Flyweight
Client → Flyweight (operations with extrinsic state)
```
