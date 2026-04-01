# Visitor Pattern — Operational Architecture Specification

## 1. Pattern Intent

Enable adding new operations to a stable object structure **without modifying the classes that define that structure**.

The pattern separates **data ownership (elements)** from **behavior (visitors)**.
Operations are implemented as independent visitor classes that operate on elements through **double dispatch**.

Primary architectural goal:

* Preserve **Open/Closed Principle (OCP)** when operations evolve faster than the object structure.
* Maintain **Single Responsibility Principle (SRP)** by preventing domain models from accumulating unrelated behavior.

---

# 2. Recognition Signals

AI systems should identify the Visitor pattern when the following signals exist:

1. **Stable object hierarchy**

   * A set of domain classes whose structure rarely changes.

2. **Expanding operations**

   * New behaviors frequently added across the entire hierarchy.

3. **Cross-cutting operations**

   * The same operation must run across multiple concrete types.

4. **Type-specific logic**

   * Behavior depends on the concrete type of each element.

5. **Naive implementation symptoms**

   * Domain classes contain unrelated methods (e.g., print, export, validate).
   * Repeated `if/else` or `instanceof` checks to differentiate types.

6. **Architectural requirement**

   * Add operations **without modifying existing model classes**.

---

# 3. Core Invariant Rule

**Visitor pattern correctness depends on double dispatch.**

A valid implementation must satisfy:

```
element.accept(visitor)
      → visitor.visit(concreteElement)
```

Mandatory invariant:

* **Each element must implement `accept(visitor)`**
* **Visitor must define a `visit()` overload for every concrete element type**

If either side is missing, **double dispatch fails and the pattern collapses**.

---

# 4. Structural Roles

### Element (Interface / Abstract Base)

Represents a node in the object structure.

Responsibilities:

* Declare `accept(visitor)` method.
* Allow visitors to perform operations on it.

Rules:

* Must not contain operation logic belonging to visitors.

---

### Concrete Element

Represents specific element types in the hierarchy.

Responsibilities:

* Implement `accept(visitor)`
* Pass `this` to visitor visit method.

Implementation requirement:

```
accept(visitor):
    visitor.visit(this)
```

Concrete elements contain **data only**, not external operations.

---

### Visitor (Interface)

Defines operations applicable to each concrete element.

Responsibilities:

* Declare a `visit()` method for each concrete element type.

Example structure:

```
visit(Circle)
visit(Rectangle)
visit(Triangle)
```

---

### Concrete Visitor

Implements a specific operation across all element types.

Examples:

* PrintVisitor
* JsonExportVisitor
* ValidationVisitor
* RiskCalculationVisitor

Responsibilities:

* Implement element-specific logic for each `visit()` method.

---

# 5. Lifecycle / Concurrency Constraints

1. **Visitors are stateless or operation-scoped**

   * Avoid storing mutable state shared across element traversal.

2. **Traversal control**

   * The traversal of elements is external to the visitor unless explicitly designed otherwise.

3. **Thread safety**

   * Visitors operating on shared structures must avoid shared mutable state.

4. **Visitor lifespan**

   * Typically created per operation execution.

---

# 6. SOLID Alignment

### Single Responsibility Principle

* Elements → hold domain data.
* Visitors → implement operations.

### Open / Closed Principle

* New operations → add new visitors.
* No modification of element classes required.

### Liskov Substitution Principle

* All elements implement the same `accept()` contract.

### Interface Segregation Principle

* Visitor interface defines specific visit methods per type.

### Dependency Inversion Principle

* Element depends on **visitor abstraction**, not concrete visitors.

---

# 7. Implementation Rules for AI Coding Agents

1. Define an **element interface** containing only:

```
accept(visitor)
```

2. Each concrete element must implement:

```
accept(visitor):
    visitor.visit(this)
```

3. Create a **visitor interface** containing:

```
visit(ElementTypeA)
visit(ElementTypeB)
visit(ElementTypeC)
```

4. Each operation must be implemented as **a separate visitor class**.

5. Do NOT place operation logic inside element classes.

6. Maintain **one visit method per concrete element**.

7. Avoid generic visitor methods such as:

```
visit(IShape)
```

because they eliminate type-specific dispatch.

---

# 8. Prompt Constraints for AI Code Generation

When generating Visitor implementations, prompts must enforce:

Required constraints:

```
Use the Visitor pattern with double dispatch.

Elements must implement:
accept(visitor)

accept must call:
visitor.visit(this)

Visitor interface must declare:
visit method for each concrete element type.

Operations must be implemented as separate visitor classes.

Model classes must contain data only and must not implement operations like printing or exporting.
```

Explicit instruction to include:

```
Ensure accept() calls visitor.visit(this).
```

This instruction ensures correct double dispatch generation.

---

# 9. Deterministic Refactoring Steps

Convert naive multi-operation classes into a Visitor pattern using the following deterministic process.

### Step 1 — Identify element hierarchy

Example:

```
Circle
Rectangle
Triangle
```

---

### Step 2 — Remove operations from elements

Example operations:

```
print()
toJson()
validate()
exportXml()
```

These must be extracted.

---

### Step 3 — Create element interface

```
interface Shape {
    accept(ShapeVisitor visitor)
}
```

---

### Step 4 — Implement accept() in each element

```
class Circle implements Shape

accept(visitor):
    visitor.visit(this)
```

---

### Step 5 — Define visitor interface

```
interface ShapeVisitor
    visit(Circle)
    visit(Rectangle)
```

---

### Step 6 — Convert operations into visitors

Example:

```
PrintVisitor
JsonExportVisitor
ValidationVisitor
```

Each implements the visitor interface.

---

### Step 7 — Apply visitor

```
shape.accept(visitor)
```

Traversal logic controls iteration over elements.

---

# 10. Common AI Generation Errors

### Missing accept() method

Incorrect:

```
visitor.visit(shape)
```

Correct:

```
shape.accept(visitor)
```

---

### Generic visit method

Incorrect:

```
visit(IShape shape)
```

Correct:

```
visit(Circle)
visit(Rectangle)
```

---

### Operations inside model classes

Incorrect:

```
class Circle:
    print()
    toJson()
```

Correct:

```
class Circle:
    data only
```

Operations belong in visitors.

---

### Strategy-like structure

Incorrect structure:

```
OperationService.process(shape)
```

This removes double dispatch.

---

### Missing visit overloads

Each element must have a corresponding visitor method.

---

# 11. Verification Checklist

A Visitor implementation is valid only if all conditions pass:

* [ ] Element interface declares `accept(visitor)`
* [ ] All concrete elements implement `accept`
* [ ] `accept()` calls `visitor.visit(this)`
* [ ] Visitor interface defines **one visit method per element type**
* [ ] Operations implemented as **separate visitor classes**
* [ ] Element classes contain **no operation logic**
* [ ] No `instanceof` or `if type` checks exist
* [ ] No generic `visit(IElement)` method
* [ ] New operations require **only adding new visitors**

---

# 12. Minimal Structural Diagram

```
        +----------------+
        |   Visitor      |
        |----------------|
        | visit(Circle)  |
        | visit(Rect)    |
        +--------^-------+
                 |
                 |
     +-----------+------------+
     |                        |
+----+-------+        +-------+------+
|  Circle    |        | Rectangle    |
|------------|        |--------------|
| accept(v)  |        | accept(v)    |
+-----+------+        +------+-------+
      |                      |
      +---- visitor.visit(this)
```

Dependency direction:

```
Elements → Visitor Interface
Visitors → Concrete Elements
```

This dependency layout enables **double dispatch and operation extensibility**.
