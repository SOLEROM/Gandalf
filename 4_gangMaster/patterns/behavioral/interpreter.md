# Interpreter Pattern — Operational Architecture Specification

---

# 1. Pattern Intent

Transform rule-heavy conditional logic into a composable expression tree representing a domain-specific language (DSL). Each rule is represented as an expression object capable of interpreting itself against runtime context data. This eliminates large procedural condition chains and enables rule composition, reuse, and independent testing.

Primary goal: represent domain rules as structured expressions rather than embedded branching logic.

---

# 2. Recognition Signals

Apply this pattern when the system exhibits the following characteristics:

* Large chains of `if / else` or `switch` statements implementing business rules.
* Conditional logic that reads like sentences (rule statements).
* Repeated combinations of simple predicates (e.g., AND / OR combinations).
* Business rules that evolve frequently.
* Need to evaluate rule combinations consistently across different parts of the system.

Common domains:

* Discount rule engines
* Approval workflows
* Feature flag conditions
* Search query filters
* Validation pipelines
* Policy evaluation engines

Architectural signal: **rules resemble a grammar composed of predicates and logical operators.**

---

# 3. Core Invariant Rule

Every rule must be represented as an `Expression` object that implements a common `interpret(Context)` operation.

Rule evaluation must occur through **expression tree traversal**, never through centralized procedural branching.

Invariant:

```
Rule evaluation = recursive interpretation of an expression tree
```

---

# 4. Structural Roles

## 4.1 Abstract Expression

Defines the interpretation contract.

Responsibilities:

* Declares `interpret(Context)` method.
* Serves as the base type for all rule expressions.

Constraints:

* Must contain no business rule logic.
* Only defines the interface contract.

Example role:

```
Expression
 └── interpret(context) -> boolean | result
```

---

## 4.2 Terminal Expression

Represents atomic conditions in the rule language.

Examples:

* `TotalGreaterThanExpression`
* `PrimeUserExpression`
* `CountryEqualsExpression`

Responsibilities:

* Evaluate a single condition.
* Read required data from `Context`.

Constraints:

* Must not combine other expressions.
* Must remain deterministic and side-effect free.

---

## 4.3 Non-Terminal Expression

Combines other expressions using logical operators.

Examples:

* `AndExpression`
* `OrExpression`
* `NotExpression`

Responsibilities:

* Contain references to child expressions.
* Delegate evaluation to children.

Constraints:

* Must not contain domain-specific rule logic.
* Must only compose expressions.

---

## 4.4 Context

Carries runtime data required during evaluation.

Examples of fields:

* cart total
* user status
* region
* request attributes

Responsibilities:

* Provide read-only data access during interpretation.

Constraints:

* Expressions must depend only on the context object.
* Expressions must not access domain objects directly.

---

## 4.5 Client

Responsible for constructing the expression tree.

Responsibilities:

* Assemble rule expressions.
* Inject runtime context.
* Trigger interpretation.

Constraints:

* Client builds rule structure.
* Client must not implement rule logic.

---

# 5. Lifecycle and Concurrency Constraints

### Expression Objects

* Must be **stateless**.
* Must be **immutable after creation**.

### Context Object

* Must be **request-scoped** or evaluation-scoped.

### Thread Safety

Safe when:

```
Expressions = immutable
Context = per-evaluation instance
```

Expression trees may be reused across concurrent evaluations.

---

# 6. SOLID Alignment

### Single Responsibility Principle

Each expression evaluates exactly one rule responsibility.

### Open / Closed Principle

New rules are added by creating new expression classes without modifying existing ones.

### Liskov Substitution Principle

All expression types must be interchangeable through the `Expression` interface.

### Interface Segregation

Single minimal interface:

```
interpret(Context)
```

### Dependency Inversion

Clients depend on the `Expression` abstraction rather than concrete rule implementations.

---

# 7. Implementation Rules for AI Agents

AI code generation must obey the following rules:

### Rule 1 — Mandatory Expression Interface

```
interface Expression {
    interpret(Context context)
}
```

No rule logic may exist outside classes implementing this interface.

---

### Rule 2 — Atomic Conditions Must Be Terminal Expressions

Each predicate must be isolated:

Incorrect:

```
if total > 1000 AND user.isPrime
```

Correct:

```
TotalGreaterThanExpression
PrimeUserExpression
```

---

### Rule 3 — Logical Composition Requires Non-Terminal Expressions

Logical operators must be classes:

```
AndExpression(left, right)
OrExpression(left, right)
NotExpression(child)
```

---

### Rule 4 — No Procedural Rule Engine

Forbidden:

* `if/else` rule chains
* centralized rule evaluator methods

Allowed:

* recursive interpretation through expression objects.

---

### Rule 5 — Context Must Be Passed Explicitly

```
interpret(context)
```

Expressions must not:

* access domain entities directly
* access global state.

---

### Rule 6 — Expression Trees Built by Client

Example structure:

```
rule =
    AndExpression(
        TotalGreaterThanExpression(1000),
        PrimeUserExpression()
    )
```

---

# 8. Prompt Constraints for AI Code Generation

When instructing AI systems to generate this pattern, the prompt must include the following constraints:

Required instructions:

```
Do not implement rule logic using if/else chains.

Implement an Expression interface with interpret(Context).

Create terminal expressions for atomic conditions.

Create non-terminal expressions (AND, OR, NOT) that combine expressions.

Interpretation must be recursive through the expression tree.

Context object must carry runtime evaluation data.

Client code must construct the expression tree manually.
```

Optional constraint:

```
Do not implement a DSL parser unless explicitly required.
```

---

# 9. Deterministic Refactoring Steps

Refactor procedural rule code using the following sequence.

### Step 1 — Identify Rule Conditions

Extract individual predicates from branching logic.

Example:

```
total > 1000
user.isPrime
country == "IN"
```

---

### Step 2 — Create Context Object

Encapsulate all rule data.

```
RuleContext
    total
    userStatus
    country
```

---

### Step 3 — Define Expression Interface

```
Expression
    interpret(context)
```

---

### Step 4 — Convert Predicates to Terminal Expressions

Example:

```
TotalGreaterThanExpression
PrimeUserExpression
CountryEqualsExpression
```

---

### Step 5 — Implement Logical Composition

Create:

```
AndExpression
OrExpression
NotExpression
```

---

### Step 6 — Replace Branching with Expression Tree

Replace procedural logic with:

```
rule.interpret(context)
```

---

### Step 7 — Move Rule Construction to Client

Rules must be assembled externally.

---

# 10. Common AI Generation Errors

### Error 1 — Procedural Evaluation

AI generates:

```
if (...) { }
else if (...)
```

Violation: not an expression tree.

---

### Error 2 — Mixing Client and Interpreter

AI places rule construction inside expression classes.

Violation: breaks separation of responsibilities.

---

### Error 3 — Missing Context Object

Expressions directly access domain objects.

Violation: tight coupling and reduced testability.

---

### Error 4 — Monolithic Expression Class

AI creates a single expression class containing all rules.

Violation: eliminates composability.

---

### Error 5 — Premature DSL Parser

AI builds tokenizers, parsers, or grammar engines.

Violation: unnecessary complexity for most production use.

---

# 11. Verification Checklist

Implementation is valid only if all checks pass.

| Check                       | Requirement                             |
| --------------------------- | --------------------------------------- |
| Expression Interface Exists | `interpret(Context)` defined            |
| Terminal Expressions        | Atomic predicates isolated              |
| Non-Terminal Expressions    | Logical combinators implemented         |
| Context Object              | Runtime data encapsulated               |
| Expression Tree             | Rules composed hierarchically           |
| No Procedural Rule Engine   | No centralized if/else rule logic       |
| Stateless Expressions       | Safe reuse across evaluations           |
| Client Builds Rules         | Construction outside expression classes |

---

# 12. Minimal Structural Diagram

```
                 +------------------+
                 |      Client      |
                 +---------+--------+
                           |
                           v
                    builds tree
                           |
                           v
                   +---------------+
                   |  Expression   |
                   | (interface)   |
                   +-------+-------+
                           |
           ---------------------------------
           |                               |
           v                               v
+----------------------+       +----------------------+
| TerminalExpression   |       | NonTerminalExpression|
| (atomic predicate)   |       | (AND / OR / NOT)     |
+----------------------+       +----------+-----------+
                                           |
                                           v
                                 +----------------+
                                 |   Expression   |
                                 |    children    |
                                 +----------------+

Evaluation Flow:
Client → ExpressionTree → interpret(Context)
```

---
