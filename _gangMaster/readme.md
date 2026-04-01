# GANG MASTER


## use as skill

disable-model-invocation: true
 Claude will not auto-load it; you must call /gang-master



## design

```

            Code Input
                │
                ▼
        ┌───────────────────┐
        │   GANG-MASTER     │
        │   (Pattern Router)│
        └─────────┬─────────┘
                  │
         Pattern detection
                  │
                  ▼
        ┌───────────────────┐
        │ Pattern Selection │
        └─────────┬─────────┘
                  │
                  ▼
        ┌───────────────────┐
        │ Pattern Refactor  │
        │   Agent Loader    │
        └─────────┬─────────┘
                  │
                  ▼
        patterns/<category>/<pattern>.md

```



## Detection Strategy

Detection only requires:
* pattern name
* recognition signals

```
Analyze the following code and detect if any GoF design pattern refactoring is appropriate.

Use the following pattern signals:

<pattern-index.yaml>

Return:

{
  patterns_detected: [],
  confidence: {},
  reasoning: ""
}
```

## Pattern refactor

```
patterns/
    creational/
        factory.md
        abstract_factory.md
        builder.md
    structural/
        bridge.md
        adapter.md
        decorator.md
    behavioral/
        strategy.md
        observer.md
        visitor.md
pattern-index.yaml

```

## master Orchestrator

objective:

```
    1. inspect code
    2. detect relevant GoF patterns
    3. rank and resolve competing candidates
    4. choose routing mode:
        no pattern
        single pattern
        multi-pattern sequence
    5. load only the needed spec file(s)
    6. delegate refactoring
    7. verify the result against pattern invariants
```

layout

```
patterns/

    detection/
        pattern-index.yaml

    creational/
        factory.md
        abstract_factory.md
        builder.md

    structural/
        bridge.md
        adapter.md
        decorator.md

    behavioral/
        strategy.md
        observer.md
        visitor.md

agents/
    gang-master.md

```


flow

```
Input code
  ↓
GANG-MASTER loads pattern-index.yaml
  ↓
Detect candidates
  ↓
Resolve conflict
  ↓
Pick spec_file
  ↓
GANG-MASTER loads selected patterns/<category>/<pattern>.md
  ↓
Refactor code using that spec
  ↓
Verify result against spec checklist
  ↓
Return result

```
