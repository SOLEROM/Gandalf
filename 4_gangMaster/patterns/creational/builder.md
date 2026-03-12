# Builder Pattern — Operational Architecture Specification

## 1. Pattern Intent

Provide a deterministic mechanism for constructing complex objects **step-by-step** while separating **object assembly logic** from the **final representation**.

The pattern ensures that:

* Construction logic is externalized from the product.
* Different representations of the same object can be produced through interchangeable builders.
* Clients are not coupled to internal assembly steps or product representation.

Primary objective: **controlled, modular construction of complex objects with many optional components or configuration permutations.**

---

## 2. Recognition Signals

AI agents should detect a Builder Pattern opportunity when the following structural signals appear:

**Code Smells**

* Constructors containing **>4–5 parameters**.
* Multiple **overloaded constructors** representing configuration permutations.
* Repeated object assembly logic across multiple modules.
* Conditional construction logic (`if/else` chains configuring object state).
* Classes responsible for both **data representation and assembly logic**.

**Architectural Indicators**

* Objects with multiple optional parts.
* Multiple representations of the same conceptual product.
* Construction logic reused across different contexts.

**Refactoring Trigger**

```
If:
  - Constructor parameter count > 5
  OR
  - duplicated object assembly logic exists
  OR
  - configuration logic is mixed with object representation

Then:
  Refactor using Builder Pattern
```

---

## 3. Core Invariant Rule

The **product must never contain its own construction logic**.

Object assembly must be delegated to builder implementations while the product remains a passive representation.

Invariant constraints:

```
Client → Director → Builder Interface → Concrete Builder → Product
```

Rules:

1. Product contains **state only**, not assembly procedures.
2. Builder defines **construction steps**.
3. Concrete builders implement step logic.
4. Director defines **construction order**.
5. Client selects the builder but does not execute construction steps directly.

---

## 4. Structural Roles

### Product

Represents the final constructed object.

Responsibilities:

* Store resulting state
* Provide domain behavior unrelated to construction

Constraints:

* Must not contain construction logic.
* Must not depend on builder classes.

---

### Builder Interface

Defines the contract for constructing parts of the product.

Responsibilities:

* Declare build steps.
* Provide a method to return the constructed product.

Typical step types:

```
buildPartA()
buildPartB()
buildPartC()
getResult()
```

Constraints:

* Must not implement product-specific logic.
* Must remain representation-agnostic.

---

### Concrete Builder

Implements builder interface and constructs a specific representation.

Responsibilities:

* Maintain intermediate construction state
* Implement build steps
* Produce final product instance

Constraints:

* Must encapsulate assembly logic.
* Must not expose partial product state externally.

---

### Director

Controls **construction order**.

Responsibilities:

* Execute builder steps in defined sequence
* Provide standardized construction workflows

Constraints:

* Must depend only on **Builder interface**, never concrete builders.
* Must not contain product representation logic.

---

### Client

Initializes the system.

Responsibilities:

* Choose concrete builder
* Pass builder to director
* Request construction

Constraints:

* Must not execute build steps directly if a director exists.

---

## 5. Lifecycle / Construction Constraints

### Assembly Sequence

The director defines deterministic assembly order.

Example lifecycle:

```
1. Client creates ConcreteBuilder
2. Client injects builder into Director
3. Director invokes ordered build steps
4. Builder constructs internal product state
5. Client retrieves final product from builder
```

### State Control

Builders must maintain **internal mutable assembly state** until construction is complete.

The returned product must be **fully assembled**.

Partial objects must never be exposed.

---

## 6. SOLID Alignment

### Single Responsibility Principle

Responsibilities separated:

| Component | Responsibility        |
| --------- | --------------------- |
| Product   | Representation        |
| Builder   | Construction logic    |
| Director  | Construction sequence |

---

### Open/Closed Principle

New product variants require only:

```
NewConcreteBuilder
```

No modification required in:

* Client
* Director
* Existing builders
* Product interface

---

### Dependency Inversion

Director depends on **Builder abstraction**, not implementations.

```
Director → Builder Interface
```

---

## 7. Implementation Rules for AI Agents

When generating Builder Pattern implementations, enforce the following rules:

### Rule 1 — Extract Construction

Move object assembly logic out of product constructors.

### Rule 2 — Define Builder Contract

Create a builder interface specifying **each construction step**.

Example step categories:

```
buildTitle()
buildHeader()
buildBody()
buildFooter()
```

### Rule 3 — Implement Concrete Builders

Each product representation requires its own builder implementation.

Example:

```
PDFReportBuilder
HTMLReportBuilder
ExcelReportBuilder
```

### Rule 4 — Add Director

Create a director responsible for invoking builder steps in order.

Example method:

```
construct()
```

### Rule 5 — Encapsulate Product Creation

Concrete builders internally manage product creation and state.

### Rule 6 — Return Final Product

Expose a method such as:

```
getResult()
```

Returning the completed object.

---

## 8. Prompt Constraints for AI Code Generation

When instructing AI to implement the Builder Pattern, prompts must enforce architecture.

**Required Prompt Elements**

```
Use Builder Pattern.

Requirements:
1. Define Builder interface specifying construction steps.
2. Implement concrete builders for each product representation.
3. Introduce Director to control assembly sequence.
4. Move all construction logic out of the product class.
5. Ensure builder returns a fully assembled product.
6. Director must depend only on the Builder interface.
```

**Disallowed Prompt Ambiguity**

Avoid prompts like:

```
simplify constructor
clean up object creation
```

They lack architectural direction.

---

## 9. Deterministic Refactoring Steps

When converting legacy code to Builder Pattern:

### Step 1 — Detect Construction Complexity

Identify constructors with excessive parameters or branching logic.

### Step 2 — Extract Product

Remove assembly logic from the class.

Ensure it only contains representation state.

---

### Step 3 — Define Builder Interface

Create step-based contract:

```
Builder
 ├ buildPartA()
 ├ buildPartB()
 ├ buildPartC()
 └ getResult()
```

---

### Step 4 — Implement Concrete Builders

Each builder constructs a specific representation.

---

### Step 5 — Introduce Director

Move assembly sequence logic into director.

---

### Step 6 — Update Client

Client workflow becomes:

```
builder = ConcreteBuilder()
director = Director(builder)
director.construct()
product = builder.getResult()
```

---

## 10. Common AI Generation Errors

### Error 1 — Builder Without Interface

AI directly defines only concrete builders.

Violation: breaks abstraction.

---

### Error 2 — Product Constructs Itself

Product contains complex constructor logic.

Violation: breaks separation of concerns.

---

### Error 3 — Director Coupled to Concrete Builder

Director explicitly references concrete builder types.

Violation: breaks dependency inversion.

---

### Error 4 — Client Executes Build Steps

Client calls builder steps manually.

Violation: bypasses director orchestration.

---

### Error 5 — Returning Partially Built Product

Builder exposes incomplete object during assembly.

Violation: lifecycle integrity.

---

## 11. Verification Checklist

AI systems must verify the following:

| Check                                                | Requirement |
| ---------------------------------------------------- | ----------- |
| Product contains no construction logic               | ✓           |
| Builder interface defines construction steps         | ✓           |
| Concrete builders implement the builder interface    | ✓           |
| Director depends only on builder abstraction         | ✓           |
| Director defines deterministic build order           | ✓           |
| Client selects builder but does not assemble product | ✓           |
| Builder returns fully assembled product              | ✓           |
| New product types require only new builders          | ✓           |

If any condition fails, the implementation is **not compliant with Builder Pattern architecture**.

---

## 12. Minimal Structural Diagram

```
        Client
          │
          ▼
       Director
          │
          ▼
    Builder Interface
          │
    ┌─────┴─────────┐
    ▼               ▼
ConcreteBuilderA  ConcreteBuilderB
    │               │
    └──────┬────────┘
           ▼
        Product
```

Dependency direction:

```
Client → Director → Builder → Product
```

Concrete builders encapsulate product construction and remain interchangeable behind the builder interface.
