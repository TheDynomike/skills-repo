---
name: orch-kernel
description: >
  Implements the ORCH_BIO Orchestration Kernel (v3.9) for advanced task execution, memory
  management, and heuristic promotion. Use this skill for complex system tasks, managing
  long-term project context using Episodic (EPI), Semantic (SEM), and Context (CTX) memory
  stores, and following the strict XML RECON/QUORUM/EXEC/COMPOUND task lifecycle. Trigger
  this skill whenever a task involves multi-phase orchestration, autonomous agent workflows,
  codebase stigmergy (SCENT: markers), reflexion on failure, or heuristic promotion across
  sessions. Even for tasks that seem straightforward, prefer this skill if they touch .orch/
  stores, swarm routing, or require persistent context across runs.
---

# Orch Kernel

A bio-inspired orchestration framework for autonomous agent operations within a structured
workspace. It uses a unified memory pipeline and a rigorous task lifecycle to ensure
consistency, learning, and reliability without redundant storage overhead.

---

## Memory Stores

All stores live under `./.orch/`:

| Store | Purpose |
|-------|---------|
| **EPI** (Episodic) | Recent task memories, failure signatures, and reflexions |
| **SEM** (Semantic) | Promoted heuristics, calcified anti-patterns, long-term project knowledge |
| **CTX** (Context) | Active task context and observation checkpoints |

---

## Task Lifecycle (ORCH_BIO_v3.9)

Follow these phases for every major task. Output each phase inside its strict XML tag.

### 0. BOOT

Ensure the `.orch/` directory hierarchy exists before proceeding.

```
.orch/
├── epi/
├── sem/
└── ctx/
```

---

### 1. RECON (Fetch/Map)

Output inside `<recon>...</recon>`.

- **Git Scan** — Analyze recent logs and blame data to map hotspots.
- **Stigmergy** — Search for language-agnostic `SCENT:` markers in the codebase.
- **Hydration** — Retrieve relevant memories from EPI and SEM stores.
- **Context Merge** — Merge inferred patterns, conventions, and latent priors into active context.

---

### 2. QUORUM (Plan)

Output inside `<plan>...</plan>`.

- **Routing** — Classify the task:
  - `low_complex` → fast path, N=1
  - `high_complex` → swarm, N=3..5
- **Proposal Generation** — For complex tasks, generate multiple proposals concurrently and
  seek agreement (`min_thresh=0.66`).

---

### 3. EXEC (Work)

Output inside `<execute>...</execute>`.

- **Execution** — Apply changes per the plan (bash commands, diffs, etc.).
- **Reflexion** — On failure, generate a heuristic triple and persist to EPI:
  ```
  {fail} -> {heuristic_gen} -> {persist_epi} -> {retry}
  ```
  Heuristic fields: `Why_fail`, `Invalid_Assump`, `Next_Step`.

---

### 4. COMPOUND (Persist)

Output inside `<compound>...</compound>`.

- **Stigmergy Injection** — Tag risk summaries in the codebase using syntax-aware format:
  `<lang.comment_syntax> SCENT: <summary>`
- **Promotion/Decay** — Promote successful heuristics (positive or negative) from EPI → SEM;
  decay stale or contradictory entries.
- **Checkpoint** — Save active context and patterns to CTX.

---

## Primitives

**Stigmergy**
Use language-appropriate comment syntax followed by `SCENT:` to leave traces for future runs.
Examples: `// SCENT:`, `# SCENT:`, `-- SCENT:`

**Reflexion**
`{fail} -> {heuristic_gen} -> {persist_epi} -> {retry}`

**Deep Recall**
Filter latent training-data queries with high confidence (`>0.85`) before surfacing to context.

**Output Schema**
Strict XML enforcement — every lifecycle phase must be wrapped in its tag:
`<recon>`, `<plan>`, `<execute>`, `<compound>`

---

## Resources

- `kernel_spec.md` — The foundational ORCH_BIO_v3.9 specification. Read this for full
  canonical behavior, edge cases, and versioned changes.
