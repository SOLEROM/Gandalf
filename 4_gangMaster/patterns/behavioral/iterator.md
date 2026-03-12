# Iterator Pattern — Architecture Specification

## 1. Pattern Intent

Provide a uniform mechanism to sequentially access elements of a collection **without exposing the collection’s internal representation**.
Traversal logic must be **externalized into iterator objects**, enabling reusable, decoupled iteration across heterogeneous collection types and traversal strategies.

The pattern ensures that **client code depends on an iteration abstraction rather than a concrete data structure**.

---

## 2. Recognition Signals

AI agents should detect the Iterator pattern when the following conditions appear:

* A collection exposes a **method that returns an iterator object**.
* Traversal occurs via **iterator methods** instead of direct indexing or loops.
* Client code interacts with an **iterator interface**, not the underlying container.
* The collection’s **internal storage structure is hidden** from consumers.
* Iteration state (position/index/pointer) is maintained **inside the iterator**, not the client.
* Multiple traversal strategies may exist for the same collection (forward, reverse, filtered, paginated, lazy).

Common naming signals:

* `Iterator`
* `IIterator<T>`
* `CreateIterator()`
* `Next()`
* `HasNext()`

---

## 3. Core Invariant Rule

Traversal logic **must never directly access the collection’s internal structure**.
All sequential access must occur through an **iterator abstraction** that encapsulates traversal state.

---

## 4. Structural Roles

### Iterator (Interface)

Defines the traversal contract.

Required operations:

* `HasNext() -> bool`
* `Next() -> T`

Responsibilities:

* Provide sequential access
* Hide traversal state
* Maintain iteration position

---

### ConcreteIterator

Implements traversal logic for a specific collection type.

Responsibilities:

* Maintain internal position state
* Access collection internals
* Implement traversal algorithm

Properties:

* Holds a reference to the associated collection
* Encapsulates traversal mechanics

---

### Aggregate (Interface)

Defines a method to create an iterator.

Required operation:

* `CreateIterator() -> Iterator<T>`

Responsibilities:

* Provide a uniform entry point for traversal
* Prevent direct exposure of collection structure

---

### ConcreteAggregate

Concrete collection implementation.

Responsibilities:

* Store elements
* Implement `CreateIterator()`
* Provide controlled access for its iterator

Examples:

* list-backed collection
* stack-backed collection
* tree structure
* paginated data source

---

### Client

Consumes elements through the iterator.

Responsibilities:

* Request iterator from collection
* Use iterator methods for traversal
* Remain independent of collection structure

---

## 5. Lifecycle / Concurrency Constraints

Iterator State Ownership

* Each iterator instance maintains its **own traversal state**.
* Multiple iterators over the same collection must operate independently.

Collection Modification

* Modifying the collection during iteration must follow one of these policies:

  * **Fail-fast** (invalidate iterator)
  * **Snapshot iteration**
  * **Concurrent-safe iterator**

Lazy Traversal

* Elements should be produced **on demand**, not precomputed.

Iterator Creation

* Iterators must be created **through the aggregate**, not directly by clients.

---

## 6. SOLID Alignment

### Single Responsibility Principle

* Collections manage **storage**
* Iterators manage **traversal**

### Open/Closed Principle

* New traversal strategies or collection types can be introduced without modifying client code.

### Dependency Inversion Principle

* Clients depend on **Iterator abstraction**, not concrete collections.

### Interface Segregation Principle

* Iterators expose only traversal operations.

---

## 7. Implementation Rules for AI Agents

1. Define a **generic iterator interface**.

Example:

```
interface IIterator<T>
{
    bool HasNext();
    T Next();
}
```

2. Define an **aggregate interface**.

```
interface IAggregate<T>
{
    IIterator<T> CreateIterator();
}
```

3. Implement a **ConcreteAggregate** containing the data structure.

4. Implement a **ConcreteIterator** that:

   * references the aggregate
   * maintains traversal position
   * implements iteration logic

5. The collection must **not expose internal data structures publicly**.

6. Client traversal must follow this pattern:

```
iterator = collection.CreateIterator()

while iterator.HasNext():
    element = iterator.Next()
    process(element)
```

7. Never embed traversal loops inside the collection or client when an iterator abstraction exists.

---

## 8. Prompt Constraints for AI Code Generation

When instructing AI coding systems, enforce the following constraints:

Required Instructions

* "Define a generic `IIterator<T>` interface."
* "Traversal state must be stored inside the iterator."
* "The collection must expose `CreateIterator()`."
* "Client code must not directly access internal storage."

Naming Constraints

* `<Entity>Iterator`
* `<Entity>Collection`
* `IIterator<T>`
* `CreateIterator()`

Prohibited Generation

* Direct `for` or `foreach` loops over internal structures in client code
* Public exposure of the collection’s internal storage
* Traversal logic mixed with business logic

---

## 9. Deterministic Refactoring Steps

Refactor naive traversal into Iterator pattern using the following steps:

1. Identify loops that directly traverse a collection.

Example anti-pattern:

```
for order in ordersList:
    process(order)
```

2. Define `IIterator<T>` interface.

3. Extract traversal logic into `ConcreteIterator`.

4. Move iteration state (index/pointer) into iterator.

5. Add `CreateIterator()` method to collection.

6. Replace loops with iterator usage.

Refactored traversal:

```
iterator = orderCollection.CreateIterator()

while iterator.HasNext():
    order = iterator.Next()
    process(order)
```

7. Ensure the collection’s internal structure is no longer visible.

---

## 10. Common AI Generation Errors

AI coding agents frequently produce these violations:

### Direct Loop Traversal

```
for item in collection.items
```

Violation:

* exposes internal structure

---

### Mixed Responsibilities

```
collection.ProcessOrders()
```

Violation:

* collection contains traversal and processing logic

---

### Iterator Without Encapsulated State

```
Next(index)
```

Violation:

* traversal state controlled externally

---

### Client Accessing Internal Storage

```
collection.orders[i]
```

Violation:

* breaks abstraction boundary

---

## 11. Verification Checklist

A correct implementation must satisfy all conditions:

* [ ] Iterator interface exists (`HasNext`, `Next`)
* [ ] Collection exposes `CreateIterator`
* [ ] Iterator encapsulates traversal state
* [ ] Client never accesses collection internals
* [ ] Traversal logic separated from collection storage
* [ ] Multiple iterators can operate independently
* [ ] Collection type can change without client modification
* [ ] Traversal strategies can be replaced or extended

---

## 12. Minimal Structural Diagram

```
        +-------------------+
        |     Client        |
        +---------+---------+
                  |
                  v
          +---------------+
          |  Iterator<T>  |
          |---------------|
          | HasNext()     |
          | Next()        |
          +-------+-------+
                  ^
                  |
        +---------+-----------+
        |   ConcreteIterator  |
        |---------------------|
        | position            |
        | reference->Aggregate|
        +---------+-----------+
                  |
                  v
        +---------------------+
        |     Aggregate       |
        |---------------------|
        | CreateIterator()    |
        +---------+-----------+
                  ^
                  |
        +----------------------+
        |  ConcreteAggregate   |
        |----------------------|
        | internal collection  |
        +----------------------+
```
