# Cleanup Plan: ECC ver1 — Keep Only General-Purpose SW Dev Assets

## What We're Doing
Delete all language/framework-specific files from `/data/proj/agents/gandalf/30_ecc/ver1/`.
Keep only items general enough for any software development process.
Move this plan file to the working dir. Write README.md.

---

## AGENTS — DELETE 18, KEEP 10

**Keep** (10):
`architect.md`, `code-reviewer.md`, `docs-lookup.md`, `doc-updater.md`, `e2e-runner.md`, `loop-operator.md`, `planner.md`, `refactor-cleaner.md`, `security-reviewer.md`, `tdd-guide.md`

**Delete** (18):
```
agents/build-error-resolver.md      # TS-specific
agents/chief-of-staff.md            # email/comms, not dev process
agents/cpp-build-resolver.md
agents/cpp-reviewer.md
agents/database-reviewer.md         # PostgreSQL-specific
agents/flutter-reviewer.md
agents/go-build-resolver.md
agents/go-reviewer.md
agents/harness-optimizer.md
agents/java-build-resolver.md
agents/java-reviewer.md
agents/kotlin-build-resolver.md
agents/kotlin-reviewer.md
agents/python-reviewer.md
agents/pytorch-build-resolver.md
agents/rust-build-resolver.md
agents/rust-reviewer.md
agents/typescript-reviewer.md
```

---

## COMMANDS — DELETE 16, KEEP 47

**Delete** (16 language-specific or harness-specific):
```
commands/cpp-build.md
commands/cpp-review.md
commands/cpp-test.md
commands/go-build.md
commands/go-review.md
commands/go-test.md
commands/gradle-build.md
commands/kotlin-build.md
commands/kotlin-review.md
commands/kotlin-test.md
commands/python-review.md
commands/rust-build.md
commands/rust-review.md
commands/rust-test.md
commands/claw.md          # NanoClaw REPL, harness-specific
commands/pm2.md           # Node.js process manager
```

**Keep** (47): everything else — plan, code-review, tdd, verify, quality-gate, checkpoint, build-fix, e2e, test-coverage, eval, refactor-clean, prune, docs, update-docs, evolve, orchestrate, devfleet, multi-plan, multi-execute, multi-workflow, multi-backend, multi-frontend, aside, sessions, save-session, resume-session, loop-start, loop-status, context-budget, prompt-optimize, model-route, rules-distill, update-codemaps, learn, learn-eval, instinct-export, instinct-import, instinct-status, skill-create, skill-health, harness-audit, projects, setup-pm, promote, verify, quality-gate

---

## RULES — DELETE 11 language dirs, KEEP common/ + README

**Keep**:
```
rules/README.md
rules/common/   (9 files: agents, coding-style, development-workflow, git-workflow, hooks, patterns, performance, security, testing)
```

**Delete** (11 language directories, 55 files total):
```
rules/cpp/
rules/csharp/
rules/golang/
rules/java/
rules/kotlin/
rules/perl/
rules/php/
rules/python/
rules/rust/
rules/swift/
rules/typescript/
```

---

## SKILLS — DELETE 30 dirs, KEEP 18

**Keep** (18 directories):
```
skills/ai-regression-testing/
skills/api-design/
skills/backend-patterns/
skills/coding-standards/
skills/configure-ecc/
skills/continuous-learning/          (+ config.json, evaluate-session.sh)
skills/continuous-learning-v2/       (+ agents/, hooks/, scripts/ subdirs)
skills/e2e-testing/
skills/eval-harness/
skills/frontend-patterns/
skills/iterative-retrieval/
skills/mcp-server-patterns/
skills/plankton-code-quality/
skills/project-guidelines-example/
skills/skill-stocktake/              (+ scripts/ subdir)
skills/strategic-compact/            (+ suggest-compact.sh)
skills/tdd-workflow/
skills/verification-loop/
```

**Delete** (30 directories):
```
skills/android-clean-architecture/
skills/compose-multiplatform-patterns/
skills/cpp-coding-standards/
skills/cpp-testing/
skills/django-patterns/
skills/django-tdd/
skills/django-verification/
skills/frontend-slides/
skills/golang-patterns/
skills/golang-testing/
skills/java-coding-standards/
skills/kotlin-coroutines-flows/
skills/kotlin-exposed-patterns/
skills/kotlin-ktor-patterns/
skills/kotlin-patterns/
skills/kotlin-testing/
skills/laravel-patterns/
skills/laravel-tdd/
skills/laravel-verification/
skills/learned/
skills/perl-patterns/
skills/perl-testing/
skills/python-patterns/
skills/python-testing/
skills/rust-patterns/
skills/rust-testing/
skills/springboot-patterns/
skills/springboot-tdd/
skills/springboot-verification/
```

---

## ADDITIONAL STEPS

1. Move `/home/vlad/.claude/plans/humble-meandering-sutton.md` → `/data/proj/agents/gandalf/30_ecc/ver1/CURATION.md`
2. Write `/data/proj/agents/gandalf/30_ecc/ver1/README.md` explaining what's here and why

---

## TOTALS AFTER CLEANUP

| Category | Before | After | Removed |
|---|---|---|---|
| Agents | 28 | 10 | 18 |
| Commands | 63 | 47 | 16 |
| Rules dirs | 12 lang + common | common only | 11 dirs (55 files) |
| Skills | 48 dirs | 18 dirs | 30 dirs |
| **Total files** | ~218 | ~90 | ~128 |
