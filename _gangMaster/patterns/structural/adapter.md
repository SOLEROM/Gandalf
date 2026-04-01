# Adapter Pattern — Operational Architecture Specification

## 1. Pattern Intent

Enable interoperability between two incompatible interfaces **without modifying either system**.
The pattern introduces a translation layer that converts calls from a **target interface expected by the client** into the **existing interface of a legacy or external component**.

Primary objective: **preserve legacy/external code while allowing integration with modern abstractions.**

Architectural outcome:

* Client depends on **abstraction**, not legacy implementation.
* Translation occurs in a **dedicated adapter component**.
* Legacy system remains **unchanged and encapsulated**.

---

## 2. Recognition Signals

An AI agent should detect Adapter opportunities when the following conditions exist:

1. **Interface mismatch**

   * Client expects method signatures different from those provided by a dependency.
   * Example mismatch types:

     * Method names differ.
     * Parameter structure differs.
     * Return types differ.

2. **Legacy or external dependency**

   * Dependency cannot or should not be modified.

3. **Client directly depends on a concrete incompatible class**

4. **Manual translation logic appears inside client code**

   * Conditional mapping
   * Data conversions
   * Method name workarounds

5. **AI-generated code modifies legacy classes to match client expectations**

6. **Existing abstraction exists but is unused**

Detection heuristic:

```
Client -> Concrete Legacy Class
AND
Client expected interface ≠ Legacy interface
```

This indicates an Adapter Pattern requirement.

---

## 3. Core Invariant Rule

**Clients must depend only on the target abstraction, never on the incompatible legacy implementation.**

All interface translation must occur **exclusively inside the adapter**.

Invariant constraints:

```
Client → Target Interface
Adapter → Target Interface
Adapter → Legacy Implementation
Client ⛔ Legacy Implementation
Legacy Implementation ⛔ Target Interface
```

Legacy code must remain **unchanged**.

---

## 4. Structural Roles

### 4.1 Client

Component requiring functionality via a **target interface**.

Responsibilities:

* Depend only on abstraction.
* Invoke standardized methods.

Restrictions:

* Must not reference legacy implementation classes.

---

### 4.2 Target Interface

The **contract expected by the client**.

Responsibilities:

* Define standardized method signatures.
* Remain stable across implementations.

Examples of responsibilities:

* Notification sending
* Payment processing
* Logging operations

---

### 4.3 Adapter

Translation layer implementing the target interface.

Responsibilities:

* Implement target interface.
* Convert client requests to legacy method calls.
* Translate parameters or return values if necessary.

Constraints:

* Must contain reference to legacy object.
* Must not expose legacy API to clients.

---

### 4.4 Adaptee (Legacy System)

Existing class with incompatible interface.

Characteristics:

* Stable or externally owned.
* Cannot be modified.
* Provides required functionality but through different method signatures.

---

## 5. Lifecycle and Concurrency Constraints

1. **Adapter lifecycle**

   * Usually instantiated alongside client dependency injection.

2. **Legacy instance ownership**

   * Adapter may:

     * Create the legacy instance
     * Receive it via dependency injection

3. **Thread safety**

   * Adapter must preserve thread safety guarantees of the legacy component.

4. **State handling**

   * Adapter must not introduce additional state unless required for translation.

---

## 6. SOLID Alignment

### Open/Closed Principle

Behavior extended through **composition** rather than modification.

```
Legacy System: closed for modification
Adapter: open for extension
```

---

### Dependency Inversion Principle

High-level modules depend on abstractions.

```
Client → Interface
Adapter → Interface
```

---

### Single Responsibility Principle

Adapter has a single responsibility:

```
Interface translation
```

---

### Liskov Substitution Principle

Any adapter implementation must be substitutable for the target interface.

---

## 7. Implementation Rules for AI Agents

1. **Do not modify legacy classes.**

2. **Always introduce a target interface** when:

   * Client expects a different contract
   * Multiple implementations may exist.

3. **Create adapter implementing the target interface.**

4. **Inject legacy dependency into adapter.**

5. **Translate method calls inside adapter methods.**

Example transformation rule:

```
Client expects: sendEmail(message)

Legacy provides: sendMessage(message)

Adapter implementation:

sendEmail(message):
    legacy.sendMessage(message)
```

6. **Clients must receive dependencies via abstraction**

Allowed:

```
Client(NotificationService service)
```

Not allowed:

```
Client(LegacyEmailer emailer)
```

---

## 8. Prompt Constraints for AI Code Generation

AI prompts implementing the adapter pattern must enforce the following constraints:

Required prompt directives:

```
- Do not modify the legacy class.
- Introduce a target interface.
- Implement an adapter that wraps the legacy system.
- The adapter must translate between method signatures.
- Clients must depend only on the interface.
```

Prohibited prompt behavior:

```
- Editing legacy code
- Renaming legacy methods
- Injecting translation logic into client code
- Direct dependency on legacy implementation
```

---

## 9. Deterministic Refactoring Steps

AI refactoring algorithm for introducing an adapter:

### Step 1 — Identify mismatch

Detect client using incompatible concrete dependency.

### Step 2 — Extract abstraction

Create interface representing expected client behavior.

```
interface NotificationService
```

---

### Step 3 — Modify client dependency

Replace:

```
LegacyEmailer
```

With:

```
NotificationService
```

---

### Step 4 — Implement adapter

Create adapter implementing the interface.

```
EmailAdapter implements NotificationService
```

---

### Step 5 — Wrap legacy dependency

Adapter holds reference:

```
LegacyEmailer legacy
```

---

### Step 6 — Translate calls

Map interface methods to legacy methods.

---

### Step 7 — Inject adapter

Provide adapter instance to client.

---

## 10. Common AI Generation Errors

### Error 1 — Modifying Legacy Classes

AI rewrites legacy method names.

Incorrect:

```
class LegacyEmailer {
    sendEmail(...)
}
```

---

### Error 2 — Direct Client Dependency

Client references legacy implementation.

Incorrect dependency:

```
Client → LegacyEmailer
```

---

### Error 3 — Translation Logic Inside Client

Incorrect structure:

```
client.sendEmail():
    legacy.sendMessage()
```

Translation must occur in adapter.

---

### Error 4 — Missing Interface

Adapter created but no abstraction used.

Incorrect structure:

```
Client → Adapter
```

Correct structure:

```
Client → Interface → Adapter
```

---

## 11. Verification Checklist

A generated implementation is valid only if **all conditions are satisfied**:

* [ ] Legacy class remains unchanged
* [ ] Target interface exists
* [ ] Adapter implements the target interface
* [ ] Adapter contains reference to legacy class
* [ ] Adapter translates method calls
* [ ] Client depends only on abstraction
* [ ] Client does not import or reference legacy implementation
* [ ] Adapter encapsulates all translation logic
* [ ] Multiple implementations can replace adapter without client changes

---

## 12. Minimal Structural Diagram

```
        Client
          │
          ▼
   Target Interface
          ▲
          │ implements
       Adapter
          │
          ▼
    Legacy System
```

Dependency direction:

```
Client → Interface → Adapter → Legacy
```
