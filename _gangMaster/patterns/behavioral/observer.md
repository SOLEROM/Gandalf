# Observer Pattern —  Architecture Specification


# Pattern Intent

Define a one-to-many dependency in which a single state owner publishes change notifications to multiple subscribers through abstractions, without depending on subscriber implementations.

Use this pattern when:

* one component is the source of truth for state,
* multiple independent components must react to state changes,
* subscribers must be addable or removable without modifying publisher logic,
* polling or manually sequenced callbacks would create coupling.

# Recognition Signals

Recognize the Observer pattern when the transcript or code exhibits these signals:

* one object owns mutable state and emits change events,
* many downstream components react to the same change,
* publisher behavior must remain unchanged as new reactions are added,
* dynamic subscription and unsubscription are required,
* direct calls such as `display.show()`, `logger.log()`, `sms.send()` inside the state owner are identified as a design smell,
* event-driven, reactive, notification, publish-subscribe, or model-update language is present,
* the desired dependency direction is from concrete subscribers to a subject contract, not from publisher to subscriber implementations.

# Core Invariant Rule

The subject must know only observer abstractions and must never encode concrete reaction logic. All subscriber-specific behavior must reside exclusively in observer implementations, while state change and notification orchestration remain exclusively in the subject.

# Structural Roles

**Subject**

* Owns the authoritative state.
* Exposes subscription management operations.
* Triggers notification after relevant state transitions.
* Depends only on the observer interface.

**Observer**

* Defines the notification contract.
* Receives updates from the subject.
* Must not require the subject to know observer-specific behavior.

**ConcreteSubject**

* Stores the observer collection.
* Updates internal state.
* Executes notification dispatch when state changes.
* May expose state snapshot or event payload required by observers.

**ConcreteObserver**

* Implements reaction logic independently.
* May update UI, log, send alerts, trigger workflows, or record analytics.
* Must remain substitutable with any other observer implementation.

**Subscription Registry**

* Internal collection owned by the subject.
* Supports attach and detach operations.
* Must not expose internal mutation in a way that breaks notification integrity.

**Notification Payload**

* Either the subject instance or an immutable event/state snapshot.
* Must provide enough information for observers to react without creating reverse coupling.

# Lifecycle or Concurrency Constraints

* Subscription must be runtime-extensible. Observers can be added or removed without subject modification.
* `attach` and `detach` are mandatory operations unless the environment provides equivalent lifecycle hooks.
* Notification timing must be deterministic relative to state mutation. The architecture must define whether notification occurs:

  * immediately after mutation,
  * after transaction commit,
  * after debounce/batching,
  * or through queued dispatch.
* Default synchronous notification is acceptable only when blocking behavior is acceptable and explicitly understood.
* If observer latency or failure must not block the publisher, dispatch must be asynchronous or buffered.
* When asynchronous notification is used, ordering, retry, and delivery semantics must be explicit.
* Subject iteration over observers must tolerate observer removal or failure without corrupting the registry.
* Observer side effects must not mutate subject internals in uncontrolled recursive loops unless re-entrancy is explicitly designed.
* Infinite update cycles between subjects/observers must be prevented by guards, idempotency, change detection, or event partitioning.
* A notification should occur only on meaningful state change, not on every setter call unless required by the domain.

# SOLID Alignment

**SRP**

* Subject handles state ownership and notification orchestration only.
* Observers handle reaction logic only.

**OCP**

* New observer behavior is added by introducing new observer implementations, not by editing the subject.

**LSP**

* Any concrete observer must be substitutable through the observer interface without requiring subject changes.

**ISP**

* Observer contract should remain minimal, typically a single update operation or narrowly scoped event-specific methods.

**DIP**

* Subject depends on observer abstraction, never on concrete listeners.

# Implementation Rules for AI Agents

1. Create separate `Observer` and `Subject` abstractions before implementing concrete classes.
2. The subject must maintain a collection of observers typed to the observer interface only.
3. The subject must expose explicit `attach(observer)` and `detach(observer)` operations.
4. The subject must expose or internally invoke `notify()` as part of its state-change workflow.
5. Concrete observers must contain all subscriber-specific behavior.
6. The subject must not import or instantiate concrete observers.
7. The subject must not manually sequence named reactions such as display, logger, analytics, or notifier calls.
8. State mutation and notification must be adjacent in the subject lifecycle so change propagation is reliable.
9. Prefer passing an event payload or immutable snapshot when observers do not need full subject access.
10. If passing the subject reference, observers must use only exposed read APIs, not subject internals.
11. Support duplicate-subscription prevention or define whether duplicates are allowed.
12. Define failure isolation semantics:

    * fail-fast for strict consistency, or
    * continue notifying remaining observers while capturing errors.
13. For production-oriented code, avoid registry corruption during iteration by iterating over a snapshot or using safe concurrent collection semantics.
14. Do not merge observer logic into the subject even if there are only one or two initial subscribers.
15. Do not replace the pattern with polling loops, callback lists without abstraction, or hard-coded procedural pipelines.

# Prompt Constraints for AI Code Generation

Use these constraints when directing a coding model:

* “Implement using the Observer pattern.”
* “Create separate Subject and Observer interfaces.”
* “Keep the subject decoupled from concrete observers.”
* “Support runtime subscribe and unsubscribe.”
* “The subject may notify many observers from a single state change.”
* “Do not hard-code concrete listeners into the publisher.”
* “Do not merge reaction behavior into the subject.”
* “Model one source of truth with many independent subscribers.”
* “Make it extensible so new observers can be added without changing subject code.”
* “Specify whether notification is synchronous or asynchronous.”
* “Preserve OCP and SRP.”
* “Use abstractions for dependency direction.”

# Deterministic Refactoring Steps

1. Identify the current publisher class that owns the changing state.
2. Locate all direct downstream calls embedded in that class.
3. Extract a minimal `Observer` interface representing a single notification contract.
4. Extract a `Subject` interface exposing `attach`, `detach`, and notification behavior.
5. Replace direct references to concrete listeners with an observer collection stored in the subject.
6. Move each direct reaction block into its own concrete observer implementation.
7. Modify the publisher so state-change methods update state first and then trigger notification.
8. Remove all publisher imports or knowledge of concrete observer classes.
9. Introduce registration composition at application setup time.
10. Add tests proving that new observers can be added without subject modification.
11. Add tests for detachment, notification ordering, and non-notification when state is unchanged if required by domain rules.
12. If blocking is a risk, refactor notification dispatch behind an asynchronous dispatcher while preserving the subject-observer contract.

# Common AI Generation Errors

* Hard-coding concrete observers inside the subject.
* Recreating naive direct-callback design with renamed classes.
* Omitting `attach` and `detach`, producing a static subscriber set.
* Merging subject responsibilities with observer behavior.
* Allowing the subject to instantiate observers directly.
* Using polling instead of push-based notification.
* Exposing mutable subject internals to observers.
* Triggering notifications before state is committed.
* Ignoring slow observer impact in synchronous loops.
* Failing to define behavior when one observer throws an exception.
* Allowing modification of the observer collection during iteration without protection.
* Coupling observers to each other.
* Treating “event bus” as an excuse to skip the core subject-observer abstractions in local object design.

# Verification Checklist

* [ ] A distinct subject abstraction exists.
* [ ] A distinct observer abstraction exists.
* [ ] The subject depends only on the observer abstraction.
* [ ] The subject owns the authoritative state.
* [ ] The subject supports dynamic attach and detach.
* [ ] The subject contains no concrete subscriber behavior.
* [ ] Each observer encapsulates its own reaction logic.
* [ ] New observers can be introduced without modifying the subject.
* [ ] State change triggers notification through the subject workflow.
* [ ] Notification payload/reference is sufficient and intentionally designed.
* [ ] Notification timing is explicitly defined.
* [ ] Blocking/failure behavior of observers is explicitly defined.
* [ ] The implementation avoids registry corruption during notification.
* [ ] The design satisfies SRP and OCP.
* [ ] The final code is push-based, not polling-based.

# Minimal ASCII Structural Diagram

```text
+-------------------+
|   ConcreteSubject |
|-------------------|
| state             |
| observers[]       |
| attach()          |
| detach()          |
| notify()          |
+---------+---------+
          |
          | depends on
          v
+-------------------+
|     Observer      |
|-------------------|
| update(payload)   |
+----+----------+---+
     ^          ^
     | implements
     |          |
+----+---+  +---+----+
| Obs A  |  | Obs B  |
+--------+  +--------+
```
