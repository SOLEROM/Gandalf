# Singleton Pattern — Operational Architecture Specification

---

## 1. Pattern Intent

Guarantee that a class has **exactly one instance within a process** and provide a **globally accessible retrieval mechanism** for that instance while **controlling object creation**.

The pattern centralizes access to shared system state or infrastructure resources where multiple instances would create inconsistency, waste resources, or violate architectural constraints.

Typical uses include centralized configuration management, logging coordination, shared registries, and controlled access to expensive resources.

---

## 2. Recognition Signals

An AI agent should infer the Singleton pattern when the following structural or behavioral signals appear:

1. Multiple modules require access to **one shared object instance**.
2. Object creation must be **centrally controlled or restricted**.
3. Instantiation must occur **inside the class itself**, not externally.
4. The class exposes a **static/global access method** returning the instance.
5. Constructor visibility is **private or otherwise inaccessible**.
6. Instance is stored in a **static class-level field**.
7. Code or requirements mention:

   * global configuration
   * centralized logging
   * resource control
   * service registry
   * shared runtime state
8. Thread-safety requirements exist when application execution is concurrent.

---

## 3. Core Invariant Rule

A valid Singleton implementation must satisfy the invariant:

```
At any time during program execution,
there exists at most one instance of the singleton class,
and all consumers retrieve that same instance through the defined access point.
```

This invariant must hold across:

* concurrent execution
* repeated access
* delayed initialization (if lazy loading is used)

---

## 4. Structural Roles

### 4.1 Singleton Class

Responsibilities:

* Own and manage its sole instance.
* Restrict external instantiation.
* Provide controlled access to the instance.
* Ensure thread-safe creation if concurrency exists.

Key structural elements:

```
private static instance
private constructor
public static access method
```

### 4.2 Clients

Consumers that retrieve the instance via the global access method.

Clients must **never instantiate** the class directly.

---

## 5. Lifecycle and Concurrency Constraints

### Instance Lifecycle

Two supported lifecycle strategies:

**Eager Initialization**

* Instance created at class load time.
* Runtime guarantees single initialization.

**Lazy Initialization**

* Instance created only when first accessed.
* Requires synchronization safeguards.

---

### Thread Safety Requirement

If the environment allows concurrent access, the implementation must ensure:

```
Concurrent access must not produce multiple instances.
```

Acceptable mechanisms include:

1. Double-checked locking
2. Runtime static initialization guarantees
3. Language-provided lazy initialization constructs

---

### Double-Checked Locking Constraint

Creation logic must follow this structure:

```
if instance == null
    acquire lock
        if instance == null
            create instance
```

This ensures:

* Locking only occurs during first initialization
* Post-initialization access remains fast

---

## 6. SOLID Alignment

### Single Responsibility Principle (SRP)

The Singleton class must **only manage instance lifecycle and its core domain responsibility**.

Prohibited:

* Mixing unrelated logic (e.g., logging + configuration + persistence)
* Embedding business workflows.

Allowed:

* Managing the shared domain object itself (e.g., configuration storage).

---

### Dependency Inversion Consideration

Singleton usage may introduce hidden dependencies. Prefer dependency injection when:

* instance uniqueness is not strictly required
* testing isolation is critical
* multiple implementations may exist.

---

## 7. Implementation Rules for AI Coding Agents

When generating Singleton implementations, enforce the following rules.

### Rule 1 — Constructor Restriction

```
constructor visibility = private
```

No external instantiation allowed.

---

### Rule 2 — Static Instance Field

Declare exactly one static instance holder.

```
private static Singleton instance
```

---

### Rule 3 — Central Access Method

Provide a public static retrieval method.

Typical naming:

```
GetInstance()
Instance
```

---

### Rule 4 — Lazy Initialization (Optional)

If lazy loading is required:

```
instance created only when first requested
```

Creation must be guarded by synchronization.

---

### Rule 5 — Thread-Safe Creation

One of the following must be implemented:

**Option A — Double Checked Locking**

```
lock object required
second null check required
```

**Option B — Static Initialization**

Instance created during class load.

**Option C — Language Lazy Wrapper**

Use runtime-provided lazy constructs.

---

### Rule 6 — No Additional Responsibilities

Singleton must **not include unrelated services or workflows**.

The class manages only:

```
shared state or resource
```

---

### Rule 7 — Instance Creation Must Be Internal

Creation logic must reside **inside the singleton class only**.

External factories must not create it.

---

## 8. Prompt Constraints for AI Code Generation

When requesting Singleton generation, the prompt must specify architectural constraints explicitly.

Required prompt components:

```
1. Ensure thread-safe singleton implementation
2. Use lazy initialization
3. Prevent external instantiation
4. Maintain single responsibility principle
5. Provide global access method
6. Avoid mixing unrelated logic
```

Example instruction structure:

```
Generate a thread-safe singleton with lazy initialization using
double-checked locking. The constructor must be private and the class
must only manage its core resource without additional responsibilities.
```

---

## 9. Deterministic Refactoring Steps

If an existing implementation violates Singleton constraints, refactor using the following steps.

### Step 1 — Restrict Construction

Convert public constructors to private.

---

### Step 2 — Introduce Static Instance

Add:

```
private static instance field
```

---

### Step 3 — Implement Access Method

Add static retrieval method returning the instance.

---

### Step 4 — Add Lazy Initialization

Create instance inside the access method if not yet initialized.

---

### Step 5 — Enforce Thread Safety

Add either:

* double-checked locking
* static initialization
* runtime lazy wrapper.

---

### Step 6 — Remove External Instantiations

Replace all occurrences of:

```
new Singleton()
```

with:

```
Singleton.GetInstance()
```

---

### Step 7 — Isolate Responsibilities

Extract unrelated logic into separate classes if present.

---

## 10. Common AI Generation Errors

AI-generated Singleton implementations frequently contain the following violations:

### Missing Thread Safety

```
if (instance == null)
    instance = new Singleton()
```

Without locking, multiple instances may be created.

---

### Public Constructor

Allows external instantiation, breaking Singleton invariant.

---

### Missing Second Null Check

Lock used but missing internal null validation.

---

### Mixing Responsibilities

Singleton class also performing unrelated services.

---

### Eager Creation When Lazy Required

Instance created statically despite requirement for deferred initialization.

---

### Multiple Access Points

Providing multiple ways to create or retrieve instances.

---

## 11. Verification Checklist

An AI-generated implementation is valid only if all checks pass.

| Verification Rule                           | Required |
| ------------------------------------------- | -------- |
| Constructor is private                      | ✓        |
| Static instance field exists                | ✓        |
| Single global access method exists          | ✓        |
| Direct external instantiation impossible    | ✓        |
| Thread-safe creation guaranteed             | ✓        |
| Lazy initialization implemented if required | ✓        |
| No unrelated responsibilities inside class  | ✓        |
| All clients use access method               | ✓        |

---

## 12. Minimal Structural Diagram

```
        +----------------------+
        |      Client A        |
        +----------+-----------+
                   |
                   v
        +----------------------+
        |      Singleton       |
        |----------------------|
        | - static instance    |
        | - private ctor       |
        | + GetInstance()      |
        +----------+-----------+
                   ^
                   |
        +----------+-----------+
        |      Client B        |
        +----------------------+
```

Dependency direction:

```
Clients → Singleton
```

Singleton controls its own instantiation.
