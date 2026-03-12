# Template Method Pattern — Architecture Specification for AI Coding Systems

---

# 1. Pattern Intent

Define a **fixed algorithm skeleton in a base class** while allowing subclasses to customize specific steps without changing the algorithm structure.

The base class **controls the workflow order and invariant steps**, while subclasses implement only the **variable operations**.

Primary goal:

* Enforce **consistent workflow execution**
* Allow **controlled customization of specific steps**
* Eliminate duplication of shared algorithm structure
* Maintain centralized control of process sequencing

This pattern is used when:

* The **overall process remains constant**
* **Individual steps vary per implementation**

---

# 2. Recognition Signals

An AI system should recognize a Template Method candidate when the following signals exist:

1. Multiple implementations perform **the same ordered workflow**.
2. Most steps are identical across implementations.
3. Only **specific steps differ** between implementations.
4. The sequence of operations **must remain consistent**.
5. Duplicate workflow code appears across subclasses.
6. Variations exist in **one or a few internal steps**, not the overall process.

Common domains:

* Report generation workflows
* Data processing pipelines
* Payment processing flows
* ETL pipelines
* Framework lifecycle hooks
* UI or game rendering loops

Typical workflow shape:

```
Step A → Step B → Step C → Step D
```

Where only one or more steps require specialization.

---

# 3. Core Invariant Rule

**The algorithm skeleton must exist exclusively in the base class and must not be overridden by subclasses.**

Invariant constraints:

1. The base class defines the **template method** containing the full workflow.
2. The **execution order is fixed**.
3. Subclasses may override **only designated extension points**.
4. Shared steps must remain **implemented in the base class**.
5. Subclasses must **never redefine the algorithm structure**.

Violation condition:

If subclasses reimplement the entire workflow method, the pattern is **invalid**.

---

# 4. Structural Roles

### Abstract Template Class

Responsibilities:

* Define the **template method**
* Implement **shared concrete operations**
* Declare **abstract steps for customization**
* Optionally provide **hook methods**

Properties:

```
- Owns algorithm skeleton
- Controls execution order
- Defines extension points
```

---

### Template Method

Characteristics:

* Non-overridable method
* Defines the workflow
* Calls both concrete and abstract operations

Example structure:

```
templateMethod():
    step1()
    step2()
    customizableStep()
    step3()
```

---

### Concrete Operations

Implemented in the base class.

Purpose:

* Shared reusable behavior
* Non-variable steps

Examples:

```
printHeader()
printFooter()
validateInput()
initializeContext()
```

---

### Abstract Operations

Declared in the base class and implemented by subclasses.

Purpose:

* Represent **variable steps**

Examples:

```
processBody()
transformData()
providerAuthentication()
```

---

### Hook Methods (Optional)

Optional override points.

Properties:

* Default implementation provided
* Subclasses may override but are not required to

Used for:

* Optional extensions
* Pre/post processing

---

### Concrete Subclasses

Responsibilities:

* Implement **only abstract operations**
* Provide variant behavior
* Must not alter workflow sequence

Constraints:

* Cannot override the template method
* Cannot duplicate shared steps

---

# 5. Lifecycle and Execution Constraints

### Execution Ownership

The template class owns the workflow lifecycle.

Subclasses **participate only through callbacks**.

---

### Step Execution Order

Order must remain deterministic.

Example:

```
initialize
prepare
executeVariableStep
finalize
cleanup
```

Reordering by subclasses is prohibited.

---

### Extension Point Isolation

Subclass logic must remain isolated to:

```
abstractStep()
optionalHook()
```

---

### Dependency Direction

Dependencies must flow **from base class to extension points**, not vice versa.

Subclasses depend on the base class contract.

---

# 6. SOLID Alignment

### Single Responsibility Principle

* Template class manages workflow structure.
* Subclasses manage step-specific logic.

---

### Open / Closed Principle

The workflow is **closed for modification** but **open for extension** via subclassing.

---

### Liskov Substitution Principle

Subclasses must preserve:

* algorithm structure
* step semantics
* execution guarantees

---

### Dependency Inversion Principle

The algorithm depends on **abstract steps**, not concrete implementations.

---

# 7. Implementation Rules for AI Agents

When generating Template Method implementations:

### Rule 1 — Centralize the Algorithm

The base class must contain a **single method defining the workflow**.

Example pattern:

```
generate():
    header()
    body()
    footer()
```

---

### Rule 2 — Prevent Template Override

The template method must be:

* `final`
* `sealed`
* `non-virtual`
* or otherwise protected against override depending on language.

---

### Rule 3 — Separate Fixed vs Variable Steps

| Step Type      | Location   |
| -------------- | ---------- |
| Fixed workflow | Base class |
| Shared logic   | Base class |
| Variable logic | Subclasses |

---

### Rule 4 — Declare Customizable Steps Explicitly

Use:

* abstract methods
* virtual methods
* protected extension points

---

### Rule 5 — Subclasses Must Be Minimal

Concrete subclasses should contain **only implementation of variable steps**.

---

# 8. Prompt Constraints for AI Code Generation

When instructing an AI coding system, prompts must include:

Required instructions:

```
Define the algorithm skeleton in an abstract base class.

Implement shared steps in the base class.

Declare variable steps as abstract methods.

Subclasses override only the variable steps.

The template method must not be overridden.

Do not duplicate shared steps such as header or footer.
```

Explicit constraints:

```
Subclasses must not implement their own workflow method.
```

---

# 9. Deterministic Refactoring Steps

When converting duplicated workflow implementations into Template Method:

### Step 1 — Detect Workflow Duplication

Identify classes repeating identical sequences.

Example:

```
header()
body()
footer()
```

---

### Step 2 — Extract Common Algorithm

Move the full workflow into an abstract base class.

---

### Step 3 — Define Template Method

Create a single orchestrating method.

```
generate()
```

---

### Step 4 — Convert Variable Steps

Replace varying logic with abstract methods.

Example:

```
abstract printBody()
```

---

### Step 5 — Move Shared Logic

Consolidate repeated operations into base class methods.

---

### Step 6 — Simplify Subclasses

Subclasses implement only abstract steps.

---

# 10. Common AI Generation Errors

### Error 1 — Workflow Reimplemented in Subclasses

Incorrect:

```
SalesReport.generate()
InventoryReport.generate()
```

This breaks the template invariant.

---

### Error 2 — Empty Base Class

Base class contains no workflow logic.

Result:

Inheritance without algorithm enforcement.

---

### Error 3 — Shared Logic Duplicated

Example:

```
header()
footer()
```

implemented in each subclass.

---

### Error 4 — Missing Abstract Methods

Variable steps implemented directly in the template.

Subclasses cannot customize behavior.

---

### Error 5 — Pattern Drift to Strategy

AI replaces inheritance with interfaces and separate strategies.

This changes the pattern semantics.

---

# 11. Verification Checklist

An AI-generated implementation is valid only if:

* [ ] A base class defines the **template method**
* [ ] The workflow sequence exists in **exactly one location**
* [ ] Shared logic exists only in the base class
* [ ] Variable steps are declared **abstract or virtual**
* [ ] Subclasses implement only variable steps
* [ ] Subclasses do **not override the template method**
* [ ] No duplicated workflow exists in subclasses
* [ ] Execution order is deterministic and centralized

---

# 12. Minimal Structural Diagram

```
                +----------------------+
                |   AbstractTemplate   |
                |----------------------|
                | templateMethod()     |
                | step1()              |
                | step3()              |
                | abstract step2()     |
                +----------+-----------+
                           |
                           |
            +--------------+--------------+
            |                             |
+------------------------+   +------------------------+
| ConcreteImplementation |   | ConcreteImplementation |
|------------------------|   |------------------------|
| step2() implementation |   | step2() implementation |
+------------------------+   +------------------------+
```

Dependency direction:

```
ConcreteClasses → AbstractTemplate
TemplateMethod → AbstractStep
```
