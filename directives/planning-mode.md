Here is the fully integrated markdown document incorporating your formalization requirements. It transitions the architecture into a rigorous, computable system design by eliminating arbitrary percentages, enforcing canonical traceability with hidden entries, and explicitly defining the Derived Views Registry and fitness computations.

---

# planning-ascii

**Description:**
Planning skill that builds an Evidence Graph as the canonical artifact and renders it as human-readable views. Use when the user asks to plan, design, architect, or map out an approach before implementation. Scales from a single-frame sketch to a full five-phase scaffold without artifact explosion. Handles large plans, large codebases, and multi-agent handoffs with full traceability. Not for multi-agent orchestration (use operon, build-plan-go, or master-planner) and not for plans simple enough to fit in two sentences.

## Planning Mode — Evidence Graph Protocol

The planning session builds an Evidence Graph and renders it as views. The graph is the canonical artifact. The ASCII scaffolding, ledger, human plan, and handoff are all views derived strictly from it. Nothing exists in a view that is not in the graph, ensuring no drift is possible.

### Architecture & Derived Views Registry

To guarantee consistency, all views are derived via formal rules. The derivation maps are explicit:

* 
**Ledger View**: Source = All graph nodes.


* 
**Transition View**: Source = Graph delta (new edges/nodes).


* 
**Plan View**: Source = `DEC`, `OBS`, and `RSK` nodes.


* 
**Fitness View**: Source = Computed metrics (via defined formulas).


* 
**Handoff View**: Source = Full graph and relationship edges.



All views are rendered on demand from the graph. The graph is updated as new evidence arrives. Views never diverge from it.

---

## 1. Entry Schema & Provenance

Every ledger item is a typed entry; no freeform entries are permitted. Entry IDs are stable. Once assigned, they are never reused. Superseded entries are marked `supersedes: OLD-ID`, never deleted.

**Base Types:**

| Type | Prefix | Meaning |
| --- | --- | --- |
| Observation | `OBS` | Confirmed fact from evidence.

 |
| Assumption | `ASS` | Believed but unconfirmed.

 |
| Constraint | `CON` | Boundary the plan must respect.

 |
| Risk | `RSK` | Potential negative outcome.

 |
| Decision | `DEC` | Chosen approach.

 |
| Option | `OPT` | Alternative considered, not chosen.

 |
| Summary | `*-S` | Compressed group of same-type entries.

 |

### Extended Field Schemas

To ensure strict traceability and remove ambiguity, specific node types require dedicated fields.

**OBS — Observation** (requires Temporal Validity):

```text
OBS-01
Claim:      Config loads from env
Observed:   2026-06-19
Freshness:  STATIC
Source:     FILE
Ref:        config.py:23
Confidence: HIGH

```

**ASS — Assumption** (requires a Basis):

```text
ASS-01
Claim:      Systemd available
Basis:      Deployment spec mentions systemd
Source:     USER
Confidence: MEDIUM
If False:   Fallback init integration required

```

**CON — Constraint**:

```text
CON-01
Claim:      No external dependencies
Source:     FILE
Ref:        requirements.txt
Confidence: HIGH

```

**RSK — Risk** (requires an Owner):

```text
RSK-01
Claim:       Data loss on restart
Owner:       Implementation
Probability: MEDIUM
Impact:      HIGH
Mitigated:   UNMITIGATED  ← must resolve before gate closes

```

**DEC — Decision** (Evidence Strength is strictly computed):

```text
DEC-01
Claim:             Extend existing schema
Supports:          OBS-01, CON-01
Strength:          COMPUTED

```

**OPT — Option (not chosen)**:

```text
OPT-03
Claim:   Rewrite schema from scratch
Blocked: CON-01
Reason:  Violates no-external-dependency constraint

```

### Confidence & Provenance

Every entry declares its source and confidence to determine evidence strength.

* 
**Confidence**: `HIGH` (direct file/test) , `MEDIUM` (corroborated inference or secondary source) , `LOW` (single source, assumption, or weak signal).


* 
**Source**: `FILE` (source file) , `USER` (stated by user) , `TOOL` (returned by tool execution) , `TEST` (confirmed by test output) , `INFERENCE` (derived or inferred).



---

## 2. Graph Relationships

Entries connect as a directed graph. Seven relationship types:

| Relationship | Meaning |
| --- | --- |
| `supports` | A is positive evidence for B.

 |
| `depends_on` | A requires B to be true.

 |
| `blocks` | A prevents B from being chosen.

 |
| `mitigates` | A reduces the probability or impact of B.

 |
| `supersedes` | A replaces B (B is stale).

 |
| `invalidates` | A contradicts B — requires resolution.

 |
| `enables` | A makes B available as an option.

 |

At each phase, the protocol surfaces only the Graph Delta (new edges/nodes since the last phase) to prevent artifact explosion. Full graph available on request.

---

## 3. Computed Evidence Strength & Metrics

Humans lie; protocols shouldn't. Evidence strength and fitness metrics are strictly computed from the graph properties. They are never manually declared or estimated.

### Computed Evidence Strength

Decision quality is derived automatically from its supporting entries.

* 
**STRONG**: Two or more `FILE` or `TEST` entries, all `HIGH` confidence.


* 
**MODERATE**: Mixed sources, majority `MEDIUM` confidence or higher.


* 
**WEAK**: `INFERENCE` or `ASS` sources, one or more `LOW` confidence.



WEAK decisions are flagged in the review gate and must receive additional evidence or be explicitly acknowledged as bets.

### Computable Fitness Formulas

If a metric cannot be computed from the graph, it is a claim, not a metric. Formulas for the View Registry:

$$\text{Evidence Coverage} = \frac{\text{DEC with supports edges}}{\text{Total DEC}}$$

$$\text{Decision Traceability} = \frac{\text{DEC linked to OBS, ASS, or CON}}{\text{Total DEC}}$$

$$\text{Weak Decision Rate} = \frac{\text{WEAK DEC}}{\text{Total DEC}}$$

---

## 4. Progress Tracking (No Fake Percentages)

Counts are verifiable; percentages are often invented. Progress tracking relies strictly on absolute fractions.

**Valid Tracker Example:** 

> Files: 4 / 5 read
> Entries: 16 / 20 expected
> Gate: 7 / 11 checks passed

Percentages are only emitted if mathematically derivable from these explicit fractions. Progress bars that fill without counted steps are strictly forbidden.

---

## 5. Artifact Budget & Compression

If planning artifacts (ledger + graph + views) exceed 2× the implementation plan size, compress before continuing. Compression is lossy for detail but lossless for traceability.

**Compression Options in Order of Preference:**

1. 
**Summarise**: Group related entries of the same type into a `*-S` entry.


2. 
**Collapse**: Replace a fully-resolved subgraph with a single `DEC` node.


3. 
**Hide**: Mark an entry as `[HIDDEN]` when it is fully folded into a `DEC` that references it. Deletion is forbidden to maintain the canonical rule that every claim traces to an entry.



**When to compress:**

* 
`OBS` count > 20 after Phase 1: Group by file/domain into `OBS-S` entries.


* 
`RSK` count > 8 after Phase 2: Group by category into `RSK-S` entries.


* Graph nodes > ~30 after Phase 3: Collapse stable subgraphs.


* Token budget pressure at any point: Summarise lowest-priority entries first.



Entries with unresolved contradictions must never be compressed.

---

## 6. Contradiction Detection

Contradictions appear as `invalidates` edges and cannot be ignored. They must resolve before the review gate closes.

**Resolution paths:**

| Contradiction type | Resolution |
| --- | --- |
| `DEC` violates `CON` | Revise `DEC`, or revise `CON` with user confirmation.

 |
| `ASS` contradicts `OBS` | Observation wins; replace `ASS` with updated `OBS`.

 |
| Two `DEC`s mutually exclusive | Accept one; convert other to `OPT` with `blocks` edge.

 |
| `RSK` unmitigated | Add mitigating `DEC`, or mark risk as explicitly accepted.

 |

Resolution creates a new entry (e.g., `DEC-07b`) with a `supersedes` edge to the original. The original is never deleted.

---

## 7. Workflow

Start minimal and promote if complexity surfaces. The frame consistency (ASCII styling) is locked at Phase 1 and never varies within a session.

### Phase 1: Exploration — Ledger Population

Every finding becomes a typed entry. Open questions are `ASS` entries requiring resolution before the gate closes. Count them and name them; do not defer them.

```text
┌─────────────────────────────────────────────────────┐
│  PHASE 1 / 5  ·  EXPLORATION                        │
│                                                     │
│  Files:    4 / 5 read                               │
│  Entries:  16 / 20 expected                         │
│                                                     │
│  Read: config.py  daemon.py  sink.py  models.py     │
│  Skip: __pycache__/  dist/  (build artefacts)       │
│                                                     │
│  Ledger:   OBS: 9   ASS: 3   CON: 4                 │
│  Open:     2  (ASS-01, ASS-03 — need resolution)    │
│                                                     │
└─────────────────────────────────────────────────────┘

```

### Phase 2: Structure — Decision Mapping

Every decision becomes a `DEC`, alternatives become `OPT`, and relationships become edges. Untraced claims become `ASS` entries.

```text
┌─────────────────────────────────────────────────────┐
│  PHASE 2 / 5  ·  STRUCTURE                          │
│                                                     │
│  ┌─────────────────────────────────────────────┐    │
│  │  Plan: [Title]                              │    │
│  │                                             │    │
│  │  ✓ Goal       [one sentence — traces to DEC]│    │
│  │  ✓ Scope      in: A, B  /  out: C, D        │    │
│  │  ✓ Current    [grounded in OBS entries]     │    │
│  │  ✓ Approach   [grounded in DEC entries]     │    │
│  │                                             │    │
│  │  Changes (dependency order):                │    │
│  │    [ ] 1. src/models.py   lines 42–87       │    │
│  │    [ ] 2. src/sink.py     new function      │    │
│  │    [ ] 3. tests/test_sink.py  new file      │    │
│  │    [ ] 4. docs/API.md     update section 3  │    │
│  │                                             │    │
│  │  ✓ Risks      [grounded in RSK entries]     │    │
│  │  ✓ Verify     [commands / checks]           │    │
│  └─────────────────────────────────────────────┘    │
│                                                     │
│  Ledger:  OBS:9  ASS:3  CON:4  DEC:5  RSK:3  OPT:2  │
│  Graph:   14 nodes · 11 edges · 0 contradictions    │
│                                                     │
└─────────────────────────────────────────────────────┘

```

### Phase 3: Diagrams — Graph Views

Rendered strictly from the graph (e.g., dependency graphs from `depends_on`, data flow from `enables` / `supports`). Show graph delta.

```text
┌─────────────────────────────────────────────────────┐
│  PHASE 3 / 5  ·  DIAGRAMS  ·  GRAPH DELTA           │
│                                                     │
│  OBS-01 ─supports──▶ DEC-01                         │
│  CON-01 ─blocks────▶ OPT-03                         │
│  RSK-01 ─mitigated─▶ DEC-04                         │
│                                                     │
│  Graph: 14 nodes · 13 edges · 0 contradictions      │
│                                                     │
└─────────────────────────────────────────────────────┘

```

### Phase 4: Review Gate + Consistency Audit

Automated consistency checks via the graph. The gate cannot close while any `invalidates` edge exists without a resolution path. Audit Checks include `DEC` vs `CON`, `ASS` vs `OBS`, mutually exclusive `DEC`s, unmitigated `RSK`s, and unacknowledged `WEAK` decisions.

```text
┌─────────────────────────────────────────────────────┐
│  PHASE 4 / 5  ·  REVIEW GATE                        │
│                                                     │
│  ── Consistency Audit ───────────────────────────   │
│                                                     │
│  DEC vs CON:                                        │
│  ✗ DEC-07 (Add Redis) invalidates CON-01            │
│    (No external dependencies)                       │
│    → CONTRADICTION — must resolve                   │
│                                                     │
│  RSK vs Mitigation:                                 │
│  ! RSK-03 (Data loss on restart) — UNMITIGATED      │
│    → Add DEC or accept explicitly                   │
│                                                     │
│  Weak Decisions:                                    │
│  ! DEC-09 — Strength: WEAK                          │
│    → Strengthen evidence or acknowledge as bet      │
│                                                     │
│  Gate:  7 / 11 checks passed                        │
│                                                     │
└─────────────────────────────────────────────────────┘

```

### Phase 5: Delivery — View Rendering

Render all views from the graph via the Registry. Fitness metrics are computed last.

```text
┌─────────────────────────────────────────────────────┐
│  PHASE 5 / 5  ·  PLAN DELIVERED                     │
│                                                     │
│  Gate:  11 / 11 checks passed ✓                     │
│                                                     │
│  ── SCAFFOLDING REMOVED ─────────────────────────   │
│                                                     │
└─────────────────────────────────────────────────────┘

```

*(Delivered immediately alongside final markdown Plan View output and computed Fitness View block).*

---

## 8. Interruption Protocol

If the user interrupts mid-phase: Stop the phase, answer directly, add new evidence as entries, and resume from exactly where paused. Never restart a phase silently.

## 9. Rules

1. 
**Every claim traces to an entry.** Nothing in a view exists without a ledger entry and at least one graph edge.


2. 
**No unresolved contradictions at gate close.** The gate cannot reach 100% while any `invalidates` edge exists without a resolution entry.


3. 
**Artifact budget is a hard limit.** If artifacts exceed 2× plan size, compress before continuing.


4. 
**Fitness metrics are computed, not estimated.** Derive from the graph or do not state them.


5. **Evidence strength is honest.** A `WEAK` decision is labelled `WEAK`. It is either strengthened with evidence or explicitly acknowledged as a bet.


6. 
**Show delta, not full graph.** At each phase, show only new edges.


7. 
**Frame consistency.** Box style locked at Phase 1 (`┌─┐│└─┘`).


8. 
**The frame is a promise.** While the planning frame is visible, no implementation has begun.



## 10. Anti-patterns

| Anti-pattern | What it looks like | Fix |
| --- | --- | --- |
| **Undeclared assumptions** | Prose claims in the plan with no `ASS` entry.

 | Every unconfirmed claim becomes an entry.

 |
| **Decorative graph** | Edges that don't affect any `DEC`.

 | Only add load-bearing edges.

 |
| **Evidence laundering** | <br>`INFERENCE` source relabelled as `FILE`.

 | Source field is auditable. Never falsify provenance.

 |
| **Contradiction avoidance** | <br>`invalidates` edge detected but not surfaced.

 | Contradictions must resolve before gate closes.

 |
| **Fake progress** | Progress bars that fill without counted steps.

 | Count actual steps. Real percentage/fractions only.

 |
| **Artifact explosion** | Full ledger and full graph shown at every phase.

 | Show delta only. Compress when budget exceeded.

 |
| **Unmitigated risk markup** | Mitigated: `DEC-XX` with no actual `DEC` entry.

 | Mitigated requires a real entry to point at.

 |
| **Performing planning** | Five-phase scaffold for a three-file change.

 | Match scaffold to task. Minimal mode exists.

 |
| **Frame bleed** | ASCII boxes in the plan body after delivery.

 | Plan body is delivered outside any frame.

 |
