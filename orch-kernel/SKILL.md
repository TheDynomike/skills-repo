---
name: orch-kernel
description: Implements the ORCH_BIO Orchestration Kernel (v3.4) for advanced task execution, memory management, and heuristic promotion. Use this for complex system tasks, managing long-term project context using Episodic (EPI), Semantic (SEM), Scars, and Context (CTX) stores, and following the RECON/QUORUM/EXEC/COMPOUND lifecycle.
---

# Orch Kernel

The Orch Kernel is a bio-inspired orchestration framework designed for autonomous agent operations within a structured workspace. It utilizes a multi-layered memory system and a rigorous task lifecycle to ensure consistency, learning, and reliability.

## Memory Stores

This skill interfaces with the following stores located in `./.orch/`:

- **EPI (Episodic)**: Recent task memories and reflexions.
- **SEM (Semantic)**: Promoted heuristics and long-term project knowledge.
- **SCARS**: Records of repeat failure zones and mitigation strategies.
- **CTX (Context)**: Active task context and observation checkpoints.

## Task Lifecycle (ORCH_BIO_v3.4)

Follow these phases for every major task:

### 1. RECON (Fetch/Map)
- **Git Scan**: Analyze recent logs and blame data to map hotspots.
- **Stigmergy**: Search for `//SCENT:` tags in the codebase.
- **Hydration**: Retrieve relevant memories from EPI and SEM stores.
- **Context Merge**: Merge inferred patterns, conventions, and priors into the active context.

### 2. QUORUM (Plan)
- **Routing**: Determine if the task is `low_complex` (fast path) or `high_complex` (swarm).
- **Proposal Generation**: For complex tasks, generate multiple proposals and seek agreement (min_thresh=0.66).

### 3. EXEC (Work)
- **Execution**: Apply changes according to the plan.
- **Reflexion**: On failure, generate heuristics (`Why_fail, Invalid_Assump, Next_Step`) and persist to EPI.

### 4. COMPOUND (Persist/Scar)
- **Stigmergy Injection**: Tag risk summaries in the codebase using `//SCENT:`.
- **Promotion/Decay**: Promote successful heuristics from EPI to SEM; decay stale or contradictory data.
- **Scarring**: Create SCARS for repeat failure zones.
- **Checkpoint**: Save active context and patterns to CTX.

## Primitives

- **Stigmergy**: Use `//SCENT:` to leave traces in the environment for future runs.
- **Reflexion**: `{fail}->{heuristic_gen}->{persist_epi}->{retry}`.
- **Deep Recall**: Filter latent queries with high confidence (>0.85).

## Resources

- **[kernel_spec.md](references/kernel_spec.md)**: The foundational ORCH_BIO_v3.4 specification.
