# Composite Pattern — Operational Architecture Specification

## 1. Pattern Intent

Provide a uniform abstraction for **part–whole hierarchies** so that **individual objects (leaves)** and **groups of objects (composites)** can be treated identically by clients.

The pattern eliminates client-side branching between single objects and collections by shifting structural complexity into a recursive object hierarchy.

Primary goal:
**Enable uniform invocation of behavior across single elements and nested object structures.**

Typical domains:

* Hierarchical UI trees
* File systems
* Menu structures
* Organizational hierarchies
* Nested pricing or product bundles
* Reporting aggregation trees

---

# 2. Recognition Signals

AI agents should infer Composite when the following signals appear:

### Structural Signals

* A **tree-like hierarchy** exists.
* Objects may **contain other objects of the same abstraction**.
* Both **single items and groups expose identical operations**.

### Behavioral Signals

* Operations must **propagate recursively through children**.
* Clients need to treat **individual nodes and containers uniformly**.

### Code Smell Signals

Composite should be introduced when the code contains:

* `if/else` or `switch` branching on types such as:

  * `Item vs Bundle`
  * `File vs Folder`
  * `Leaf vs Container`
* Client logic performing manual recursion.
* Mixed procedural logic handling both collections and single objects.
* Classes containing heterogeneous lists like `List<Object>`.

---

# 3. Core Invariant Rule

A valid Composite implementation must enforce:

**Every object in the hierarchy implements the same component interface, and composite nodes recursively delegate operations to their children through that interface.**

Formal invariant:

```
∀ node ∈ hierarchy:
    node implements Component

∀ composite:
    operation() = aggregate(child.operation() for each child)
```

The client must only depend on **Component**, never on concrete types.

---

# 4. Structural Roles

## Component

Abstract contract shared by both leaf and composite objects.

Responsibilities:

* Defines the common behavior.
* Provides the operation used by the client.

Constraints:

* Must not expose implementation details of leaf/composite differences.

Example operations:

```
getPrice()
render()
delete()
display()
getSalary()
```

---

## Leaf

Represents the **atomic unit** in the hierarchy.

Characteristics:

* Cannot contain children.
* Executes behavior directly.

Constraints:

* Must not manage child collections.
* Must satisfy the same interface contract as Composite.

Example behaviors:

```
return ownPrice
render self
display node
```

---

## Composite

Represents a **container node** that manages child components.

Characteristics:

* Holds a collection of `Component`.
* Delegates work recursively to children.

Responsibilities:

* Manage child collection.
* Aggregate results from children.

Typical operations:

```
add(component)
remove(component)
getChild(index)
```

Operation behavior pattern:

```
operation():
    result = initialValue
    for child in children:
        result += child.operation()
    return result
```

---

## Client

Interacts exclusively with the **Component interface**.

Constraints:

* Must not branch based on leaf/composite type.
* Must not manage recursion.

Example interaction:

```
Component order = rootComposite
total = order.getPrice()
```

---

# 5. Lifecycle / Concurrency Constraints

### Hierarchy Construction

* Composites must only contain **Component instances**.
* Hierarchy must remain **acyclic**.

### Mutation Rules

* Child additions and removals occur only through Composite.

### Recursion Safety

Operations must terminate when reaching leaf nodes.

### Concurrency

If the hierarchy is mutable:

* Child collection must be thread-safe
  OR
* Hierarchy modifications must be externally synchronized.

---

# 6. SOLID Alignment

### Single Responsibility

* Leaf handles atomic behavior.
* Composite handles child coordination.

### Open/Closed

New component types can be introduced without modifying client code.

### Liskov Substitution

Leaf and Composite must be interchangeable via the Component interface.

### Interface Segregation

Component interface should contain only operations applicable to both node types.

### Dependency Inversion

Clients depend on **Component abstraction**, not concrete implementations.

---

# 7. Implementation Rules for AI Coding Agents

1. Define an **abstract component interface**.
2. All nodes must implement this interface.
3. Implement **Leaf classes** for atomic objects.
4. Implement **Composite classes** containing a collection of Components.
5. Composite operations must:

   * Iterate through children
   * Delegate operations recursively
   * Aggregate results if required.
6. Client code must:

   * Depend only on `Component`
   * Never use `instanceof` checks.
7. Avoid storing heterogeneous object types outside the component abstraction.

---

# 8. Prompt Constraints for AI Code Generation

To enforce correct generation, prompts must include explicit architectural constraints.

Required instructions:

```
Use the Composite Pattern.

Define a shared interface for both individual items and groups.

Leaf objects implement the behavior directly.

Composite objects hold a collection of the same interface type.

Operations must propagate recursively through the hierarchy.

The client must interact only with the interface.

Avoid if/else branching based on object types.
```

Disallowed instructions:

* Separate functions for leaf and composite logic.
* Client-side recursion.
* Type-check branching.

---

# 9. Deterministic Refactoring Steps

AI agents should refactor naive hierarchical logic using the following deterministic transformation.

### Step 1 — Identify Hierarchical Types

Detect:

```
Item
Bundle
Folder
Group
```

### Step 2 — Extract Common Behavior

Create a shared interface:

```
Component
```

Example:

```
getPrice()
```

---

### Step 3 — Convert Atomic Classes to Leaf

```
class Product implements Component
```

Leaf executes behavior directly.

---

### Step 4 — Convert Container Classes to Composite

```
class Bundle implements Component
    List<Component> children
```

---

### Step 5 — Move Recursive Logic Inside Composite

Replace external recursion:

```
for item in list:
    if item is bundle:
```

with internal delegation:

```
sum += child.getPrice()
```

---

### Step 6 — Simplify Client

Replace conditional logic with uniform invocation:

```
total = root.getPrice()
```

---

# 10. Common AI Generation Errors

### 1. Type Branching

```
if (component instanceof Bundle)
```

Violation: breaks polymorphism.

---

### 2. Client-Side Recursion

Example:

```
calculateTotal(List<Object>)
```

Violation: hierarchy behavior exists outside objects.

---

### 3. Separate APIs

Example:

```
getProductPrice()
getBundlePrice()
```

Violation: no shared abstraction.

---

### 4. Generic Object Collections

```
List<Object>
```

Violation: destroys structural guarantees.

---

### 5. Business Logic in Client

Example:

```
OrderProcessor calculates totals manually
```

Violation: breaks encapsulation.

---

# 11. Verification Checklist

An AI agent must verify the following before accepting a Composite implementation.

| Rule                                            | Verification |
| ----------------------------------------------- | ------------ |
| Common interface exists                         | ✔            |
| Both leaf and composite implement the interface | ✔            |
| Composite holds children of same interface type | ✔            |
| Operations delegate recursively                 | ✔            |
| Client depends only on abstraction              | ✔            |
| No `instanceof` or type-switch logic            | ✔            |
| Hierarchy supports nested composition           | ✔            |

Failure of any rule indicates incorrect implementation.

---

# 12. Minimal Structural Diagram

```
            Client
              │
              ▼
         +-----------+
         | Component |
         +-----------+
           ▲       ▲
           │       │
      +--------+  +-------------+
      |  Leaf  |  |  Composite  |
      +--------+  +-------------+
                      │
                      ▼
               List<Component>
                      │
             ┌────────┴────────┐
             ▼                 ▼
         Component         Component
```

Dependency Direction:

```
Client → Component
Composite → Component (children)
Leaf → Component
```
