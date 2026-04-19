---
name: master-workers-qa
description: Single-file multi-agent execution with one master, generic workers, and one QA gate.
---

# Master / Workers / QA

## Purpose

Use this skill when a task must be executed through:

- one **master** agent
- up to **max_workers** generic **workers**
- one **QA** agent
- exactly one authoritative **task file**

A task file is mandatory. This skill defines behavior only.

---

# CONFIG

```yaml
CONFIG:
  max_workers: 4
  max_depth: 3
  retry_limit: 3
  enable_log: false
  master_only_writes: true
  qa_checks_final_top_task_only: true
  allow_master_create_new_top_tasks: true
  allow_workers_propose_subtasks: true
  allow_task_reorder: true
  allow_task_rename: true
  allow_dependency_edit: true
  allow_merge_split: true
  scheduling_policy: dependency_ready_then_file_order
  require_explicit_task_file: true
  require_existing_task_file: true
  require_valid_task_file: true
```

---

# Core Invariants

1. There is exactly one authoritative task file.
2. The user supplies the initial file.
3. The master validates it, then rewrites that same file in place into managed format.
4. Optional backups are allowed, but backups are never authoritative.
5. Only the master may write the task file.
6. Workers never write the task file directly.
7. QA only decides final success or final failure.
8. If any task fails `retry_limit` times, the whole run fails.
9. The master must publish a final status summary.

---

# Required Input

The required starting syntax is minimal plain Markdown:

```
[] first task
[] second task
[] third task
```

The master may normalize that file by:

* adding IDs
* adding metadata
* clarifying wording
* fixing typos and grammar
* rewriting vague tasks into clearer executable descriptions
* adding dependencies
* splitting tasks into subtasks
* reordering tasks
* creating new top-level tasks if needed

The master must preserve the original intent.

---

# Managed States

Allowed task states:

* `[]` not started
* `[/]` in progress
* `[>]` expanded into subtasks
* `[v]` completed
* `[x]` terminal failure

Rules:

* `[]` means present but not active
* `[/]` means assigned and active
* `[>]` means parent task with children
* `[v]` means complete from master perspective
* `[x]` means permanently failed

Do not mark intermediate failed attempts as `[x]` until retry limit is reached.

---

# Roles

## Master

The master must:

* validate the input file
* normalize the file into managed format
* keep that same file as the only source of truth
* assign task IDs
* improve wording where needed
* manage dependencies and conflicts
* assign work to workers
* accept or reject proposed task changes
* track retries and failure notes
* retry failed tasks with another worker when possible
* stop the run when retry limit is reached
* send the final top task to QA
* publish the final report

## Workers

Workers must:

* work only on assigned tasks
* never edit the task file directly
* self-check before returning results
* report completion, failure, blockage, or proposed decomposition
* propose subtasks when appropriate
* never declare final success or failure

## QA

QA must:

* review only the final top-level objective
* approve only if the actual goal is satisfied
* reject unsupported completion claims
* explain what is still wrong or missing
* reopen the top task through master-controlled update flow
* be the only authority for final success or final failure

---

# Task IDs and Metadata

The master assigns explicit IDs:

* top-level: `T001`, `T002`
* subtasks: `T001.1`, `T001.2`
* deeper: `T001.2.1`

Example managed entry:

```md
[] [T001] Build parser
    tries: 0
    depends:
    notes:
```

Recommended fields:

* `tries`
* `depends`
* `notes`

Optional fields:

* `owner`
* `last_fail`

---

# Single-File Safety

To avoid race conditions:

* only the master writes the file
* workers only propose updates
* QA feedback is written through the master
* no shadow task file is used
* no worker-local plan is authoritative

The user-supplied file is rewritten in place and remains the only live task file for the run.

---

# Scheduling Rules

The master uses:

1. find dependency-ready tasks
2. remove blocked or conflicting tasks
3. choose tasks in top-to-bottom file order
4. assign up to `max_workers`

A task is runnable only if:

* it is `[]`
* all dependencies are `[v]`
* it is not already assigned
* it does not conflict with active work
* it does not violate parent-child rules

If a task has active child tasks, the parent must be `[>]`.

---

# Decomposition Rules

A worker may decide a task must be split.

Flow:

1. worker receives task
2. worker proposes subtasks to master
3. master validates the proposal
4. master updates the file
5. parent becomes `[>]`
6. child tasks are inserted
7. original assignment ends
8. master later schedules the children

Decomposition must not exceed `max_depth`.

---

# Retry and Failure Policy

On each failed attempt:

1. master increments `tries`
2. master records failure details in notes
3. master returns the task to `[]` unless retry limit is reached
4. retry should go to another worker when possible

If any task reaches `retry_limit` and still fails:

* master marks it as terminal failure candidate
* the run moves toward failure
* QA confirms final failure
* after QA confirms, the run is failed

One task failing 3 times fails the whole run.

---

# Completion Policy

Final success requires all of the following:

* no unresolved required work
* no active `[/]` tasks
* no blocking `[]` tasks
* no terminal failure
* QA approval of the final top task

If QA rejects:

* master reopens the top task to `[]`
* master updates notes with the rejection reason
* orchestration continues

Workers and master may believe work is done, but only QA can finalize the result.

---

# Final Report

At the end, the master must report:

* overall result: success or failure
* top-level task status
* completed tasks
* failed tasks
* unresolved tasks
* retry and failure summary
* whether QA approved or rejected

If `enable_log: true`, a run log may be kept in the same file.
If `enable_log: false`, only minimal task-level failure metadata is required.

---

# Refusal Conditions

Refuse to start if:

* no task file is supplied
* the file does not exist
* the file contains no valid `[]` task entries
* the file is too malformed to normalize safely
* execution would require more than one authoritative task file

---

# Operating Procedure

1. Validate explicit task file path.
2. Validate file exists.
3. Validate at least one raw `[]` task exists.
4. Normalize the file in place.
5. Assign IDs and metadata.
6. Clarify wording and fix typos if needed.
7. Schedule dependency-ready tasks.
8. Collect worker results.
9. Apply approved updates through the master only.
10. Retry failed tasks until success or retry limit.
11. Send final top task to QA.
12. If QA rejects, reopen and continue.
13. If QA approves, finish successfully.
14. If retry limit is exceeded, fail the run.
15. Publish final status summary.


