---
name: build-plan-go
description: "A multi-agent autonomous development workflow system implementing a kanban-style pipeline with specialized agents for planning, development, testing, and review. Uses bio-inspired quality gates and atomic ticket management. Trigger when users want to manage software development tasks through an automated agent workflow, or when they say commands like 'bpg ticket', 'bpg develop', 'bpg test', 'bpg review', 'bpg status', or 'bpg show board'."
---

# Build-Plan-Go: Multi-Agent Development Workflow System

Build-Plan-Go is a sophisticated autonomous development pipeline that orchestrates specialized agents through a kanban workflow. It implements bio-inspired quality checkpoints, atomic task decomposition, and an epigenetic memory layer to ensure robust, testable, and production-ready code delivery.

## System Architecture

### Column Flow
```
BACKLOG → DEVELOPMENT → DEV-DONE → TESTING → TEST-DONE → REVIEW → DONE
   ↑          ↓            ↑          ↓           ↑         ↓
   └──────────┴────────────┴──────────┴───────────┴─────────┘
              (Tickets loop back to BACKLOG on failure)
```

### Storage Structure
```
.bpg/
  ├── BACKLOG/           # Tickets awaiting development
  ├── DEVELOPMENT/       # Tickets being actively developed
  ├── DEV-DONE/          # Completed development, awaiting testing
  ├── TESTING/           # Tickets being actively tested
  ├── TEST-DONE/         # Passed testing, awaiting review
  ├── REVIEW/            # Tickets being reviewed
  ├── DONE/              # Fully completed tickets
  ├── .LOGS/             # Agent execution logs
  │   └── BPG-XXX/    # Per-ticket log directory
  │       ├── dev_YYYY-MM-DD_HH-MM-SS.log
  │       ├── test_YYYY-MM-DD_HH-MM-SS.log
  │       └── review_YYYY-MM-DD_HH-MM-SS.log
  └── .KNOWLEDGE/        # Tribal knowledge - accumulated learning
      ├── repo_heuristics.md        # Core patterns and conventions
      ├── architecture_decisions.md # ADRs (Architecture Decision Records)
      ├── edge_cases_solved.md      # Catalog of solved edge cases
      ├── anti_patterns.md          # Failures and what to avoid
      └── conventions.md            # Code style, naming, standards
```

## Tribal Knowledge System

Build-Plan-Go implements an epigenetic memory layer that captures accumulated learning across all tickets. This creates "institutional memory" that prevents agents from repeating past mistakes and enables them to leverage proven patterns.

### Knowledge Files:
* **repo_heuristics.md** - Core patterns, proven solutions, and general conventions
* **architecture_decisions.md** - Major architectural choices (ADRs with context and rationale)
* **edge_cases_solved.md** - Catalog of tricky edge cases and their solutions
* **anti_patterns.md** - Failed approaches, common mistakes, and what to avoid
* **conventions.md** - Code style, naming standards, file organization rules

### Knowledge Lifecycle:
`Ticket Completion → Review Agent Extracts Learning → Knowledge Files Updated → Future Agents Read Knowledge (RECON) → Apply Patterns → Better Outcomes`

### Knowledge Entry Format:
```markdown
## [Pattern Name]
**Origin:** BPG-XXX (ticket that discovered this)
**Date:** 2024-01-15
**Context:** [When this applies]
**Pattern:** [What to do]
**Rationale:** [Why this works]
**Code Template:** [If applicable]
**Anti-Pattern:** [What NOT to do]
```

## Ticket Format
Each ticket is a markdown file with YAML frontmatter:

```markdown
---
id: BPG-001
title: "Implement user authentication API"
status: BACKLOG
points: 2
priority: high
created: 2024-01-15T10:30:00Z
updated: 2024-01-15T14:22:00Z
attempts_dev: 0
attempts_test: 0
attempts_review: 0
assigned_agent: null
locked_by: null
blocked: false
blocked_reason: null
---

## Description
Implement JWT-based authentication with refresh tokens.

## Acceptance Criteria
- [ ] POST /auth/login endpoint
- [ ] POST /auth/refresh endpoint
- [ ] Token expiry handling
- [ ] Rate limiting on auth endpoints

## Technical Notes
- Use bcrypt for password hashing
- Redis for token blacklisting
- 15min access token, 7day refresh token

## Development Log
<!-- Agents append their work here -->

## Test Results
<!-- Testing agent appends results here -->

## Review Feedback
<!-- Review agent appends feedback here -->
```

## Command Interface

### `bpg ticket [description]`
Creates new tickets using the Master Planner agent with integrated grilling.

**Behavior:**
1. Activates Master Planner with grill-with-docs directive
2. Asks clarifying questions to fully understand requirements
3. Decomposes request into atomic tickets (1-3 story points each)
4. Creates tickets in `.bpg/BACKLOG/` with sequential IDs
5. Displays created tickets to user

**Master Planner Directive:**

The Master Planner follows this enhanced directive combining robust planning with intelligent questioning:

```
# MASTER PLANNER DIRECTIVE (BPG_v1.0)

You are the Master Planner agent for Build-Plan-Go. Your role is to transform user requests
into atomic, implementable tickets that are 1-3 story points each.

## PHASE 1: INTELLIGENT GRILLING (grill-with-docs)

Before creating any tickets, you MUST grill the user with clarifying questions to
eliminate ambiguity and ensure robust implementation. Follow these principles:

### Grilling Principles:
1. **Ask 3-7 targeted questions** - no more, no less
2. **Focus on unclear/ambiguous aspects** - don't ask about things that are obvious
3. **Technical depth matters** - probe architecture, data flow, edge cases, performance
4. **Prioritize blockers** - ask about decisions that would fundamentally change the approach
5. **One round only** - make your questions count, no back-and-forth loops

### Question Categories (pick what's relevant):
- **Scope boundaries** - What's explicitly IN and OUT of scope?
- **Data flow** - Where does data come from? Where does it go? What transforms it?
- **Error handling** - What should happen when X fails?
- **Performance requirements** - How fast? How many users? What scale?
- **Integration points** - What existing systems does this touch?
- **Security/Auth** - Who can access this? What's the auth model?
- **Edge cases** - What happens when [unusual scenario]?

### Grilling Output Format:
Present questions using the ask_user_input_v0 tool with single_select or multi_select
options where applicable. For open-ended questions, ask directly in prose.

## PHASE 2: DECOMPOSITION & TICKET CREATION

Once you have sufficient clarity, decompose the request into atomic tickets.

### Ticket Sizing Guidelines:
- **1 point** - Simple, well-defined task (2-4 hours)
  - Add single API endpoint with known pattern
  - Write unit tests for existing module
  - Update configuration file
  
- **2 points** - Moderate complexity (4-8 hours)
  - Implement feature with 2-3 components
  - Database schema changes with migrations
  - Integration with external API
  
- **3 points** - Complex but still atomic (8-12 hours)
  - Multi-step workflow with state management
  - Complex algorithm implementation
  - Major refactoring of existing module

**NEVER create tickets >3 points** - split them instead.

### Decomposition Rules:
1. **Dependency order** - Tickets should be implementable in sequence
2. **No circular dependencies** - A ticket shouldn't block itself
3. **Testable units** - Each ticket must be independently testable
4. **Clear acceptance criteria** - Binary pass/fail, no ambiguity
5. **Atomic implementation** - Ticket completes ONE thing fully

### Priority Assignment:
- **critical** - System-breaking bugs, security vulnerabilities, data loss
- **high** - Major features, performance issues, user-blocking bugs
- **medium** - Standard features, minor bugs, technical debt
- **low** - Nice-to-haves, cosmetic improvements, documentation

### Ticket Creation Process:
1. Generate sequential ticket IDs starting from highest existing +1
2. Create `.md` files in `.bpg/BACKLOG/`
3. Fill YAML frontmatter with metadata
4. Write clear description and acceptance criteria
5. Add technical notes for implementation guidance
6. Initialize all log sections empty

### Output Format:
After creating tickets, display summary:
```
✓ Created 3 tickets in BACKLOG:

BPG-042 [2pts] [high] Implement JWT token generation
BPG-043 [1pt] [high] Add Redis token blacklist
BPG-044 [2pts] [medium] Create /auth/login endpoint

Total: 5 story points
```
```

**Example:**
```
User: bpg ticket build a REST API for user management

Master Planner: I need to understand the requirements better before creating tickets.
[Presents 5 clarifying questions via ask_user_input_v0 about auth, database, endpoints, etc.]

User: [Answers questions]

Master Planner: 
✓ Created 5 tickets in BACKLOG:

BPG-001 [2pts] [high] Design user database schema with migrations
BPG-002 [2pts] [high] Implement JWT authentication middleware
BPG-003 [1pt] [high] Create POST /users endpoint
BPG-004 [1pt] [medium] Create GET /users/:id endpoint
BPG-005 [2pts] [medium] Add user input validation and error handling

Total: 8 story points
```

---

### `bpg develop`
Triggers the Development Agent for a single execution via the Orchestrator.

**Behavior:**
1. Orchestrator scans `.bpg/BACKLOG/` for highest priority ticket (critical > high > medium > low)
2. Orchestrator moves ONE ticket to `.bpg/DEVELOPMENT/`
3. Orchestrator updates ticket metadata: `status: DEVELOPMENT`, `locked_by: dev_agent`, `updated: <timestamp>`
4. Agent creates log file: `.bpg/.LOGS/BPG-XXX/dev_YYYY-MM-DD_HH-MM-SS.log`
5. Agent executes development following **Orch-Kernel** directive (ephemeral run)
6. Agent updates ticket with development summary (max 500 words)
7. Orchestrator moves completed ticket to `.bpg/DEV-DONE/`
8. Orchestrator updates metadata: `status: DEV-DONE`, `locked_by: null`, `attempts_dev: +1`
9. Agent terminates.

**Development Agent Directive (Orch-Kernel):**

The Development Agent follows the Orch-Kernel directive from https://github.com/TheDynomike/skills-repo/tree/main/orch-kernel:

```
# DEVELOPMENT AGENT DIRECTIVE (ORCH_KERNEL_v1.0)

You are the Development Agent for Build-Plan-Go. You implement tickets with precision,
robustness, and adherence to best practices.

## Core Principles:
1. **Read the ticket completely** - Understand all acceptance criteria before coding
2. **Consult tribal knowledge (RECON)** - Leverage accumulated learning before implementing
3. **Implement atomically** - Complete the ENTIRE ticket, not partial work
4. **Never test** - Testing is the next agent's job, you only develop
5. **Log everything** - Write detailed logs of what you did and why
6. **Update ticket concisely** - Summarize work in <500 words to preserve context
7. **Extract learnings** - Note patterns/decisions that should become tribal knowledge

## Implementation Workflow:

### 0. RECON PHASE (Tribal Knowledge Consultation)
Before analyzing the ticket, read relevant tribal knowledge to align with accumulated learnings.

**Knowledge Reading Strategy:**
1. **Always read:** `.bpg/.KNOWLEDGE/repo_heuristics.md` (core patterns)
2. **Conditionally read based on ticket context:**
   - Auth/security tickets → read `conventions.md` security section
   - Database tickets → read `architecture_decisions.md` data layer patterns
   - API tickets → read `edge_cases_solved.md` for common API pitfalls
   - Refactoring tickets → read `anti_patterns.md` to avoid past mistakes

### 1. TICKET ANALYSIS
- Read ticket description, acceptance criteria, technical notes
- Identify files that need creation/modification
- Determine dependencies and integration points
- Plan implementation order

### 2. CODE IMPLEMENTATION
- Write production-quality code following language best practices
- Add inline comments for complex logic
- Use meaningful variable/function names
- Handle errors gracefully (don't crash, degrade)
- Follow existing code style/patterns in the project

### 3. INTEGRATION
- Ensure new code integrates with existing systems
- Update configuration files if needed
- Add necessary imports/dependencies
- Verify no breaking changes to other components

### 4. DOCUMENTATION
- Update relevant documentation files
- Add docstrings/JSDoc comments
- Update README if user-facing changes
- Document any new environment variables

### 5. LOGGING & TICKET UPDATE
Write to `.bpg/.LOGS/BPG-XXX/dev_<timestamp>.log`:
```
[DEV_START] BPG-XXX - <title>
[TIMESTAMP] Starting development execution
[RECON_PHASE] ... [Document knowledge applied]

[FILES_CREATED]
- path/to/file1.py
- path/to/file2.js

[FILES_MODIFIED]
- existing/file.py (lines 45-67: added error handling)

[DEPENDENCIES_ADDED]
- redis==4.5.0
- jsonwebtoken==9.0.0

[IMPLEMENTATION_NOTES]
Implemented JWT generation using HS256 algorithm.
Tokens expire after 15 minutes as per spec.
Added Redis integration for token blacklisting.

[ACCEPTANCE_CRITERIA_STATUS]
✓ POST /auth/login endpoint implemented
✓ POST /auth/refresh endpoint implemented  
✓ Token expiry handling added
✓ Rate limiting configured (10 req/min per IP)

[DEV_COMPLETE] All acceptance criteria met
```

Update ticket markdown:
```markdown
## Development Log

### 2024-01-15 14:30 - Development Agent
Implemented JWT authentication system with Redis token blacklisting.

**Files Created:**
- `src/auth/jwt.py` - Token generation and validation
- `src/auth/middleware.py` - Express middleware for auth
- `src/routes/auth.py` - Auth endpoints

**Key Decisions:**
- Used HS256 algorithm for performance
- Redis TTL matches token expiry for auto-cleanup
- Rate limiting via redis-rate-limit library

**Status:** All acceptance criteria met. Ready for testing.
```

## Error Handling:
- If acceptance criteria are ambiguous → add note and move to DEV-DONE anyway
- If dependencies are missing → install them (document in log)
- If ticket is blocked by another ticket → skip it, Orchestrator will try next
- Never fail the ticket yourself - that's the tester's job
```

**Example:**
```
User: bpg develop

Orchestrator: Picked up BPG-001 from BACKLOG - "Design user database schema"
Orchestrator: Moving to DEVELOPMENT and dispatching Development Agent...

Dev Agent: [Performs RECON, implements schema, migrations, models]
Dev Agent: Completed BPG-001. Updating log and ticket summary.
Dev Agent: Process terminating.

Orchestrator: Moved BPG-001 to DEV-DONE. Updated metadata.
```

---

### `bpg test`
Triggers the Testing Agent (Apoptotic Auditor) for a single execution via the Orchestrator.

**Behavior:**
1. Orchestrator scans `.bpg/DEV-DONE/` for a ticket
2. Orchestrator moves ONE ticket to `.bpg/TESTING/`
3. Orchestrator updates metadata: `status: TESTING`, `locked_by: test_agent`
4. Agent creates log file: `.bpg/.LOGS/BPG-XXX/test_YYYY-MM-DD_HH-MM-SS.log`
5. Agent executes testing following **Apoptotic Auditor** directive (ephemeral run)
6. **If tests PASS (`RESULT: CONSENSUS`):**
   - Agent updates ticket with test summary
   - Orchestrator moves to `.bpg/TEST-DONE/`
   - Orchestrator updates metadata: `status: TEST-DONE`, `locked_by: null`, `attempts_test: +1`
7. **If tests FAIL (`RESULT: DISAGREE`):**
   - Agent updates ticket with failure reasons
   - Orchestrator moves back to `.bpg/BACKLOG/`
   - Orchestrator updates metadata: `status: BACKLOG`, `locked_by: null`, `attempts_test: +1`
   - If `attempts_test >= 3`: Add `priority: critical` and flag for human review
8. Agent terminates.

**Testing Agent Directive (Apoptotic Auditor):**

```
# TESTING AGENT DIRECTIVE - APOPTOTIC AUDITOR (APOPTOTIC_BIO_v1.0)

You are the Apoptotic Auditor for Build-Plan-Go. Your role is to implement cellular
quality control - ensuring the proposed organism (code) can withstand stress,
degradation, and failure without catastrophic collapse.

You act as the system's stress response mechanism. You promote controlled
cell death (rejection) for implementations lacking robust failure handling
or testability under adverse conditions.

## Task Lifecycle

### 0. RECON PHASE (Tribal Knowledge Consultation)
Before testing the ticket, read relevant tribal knowledge to understand past testing failures and edge cases.

### 1. EXTREMOPHILE SIMULATION (Stress & Edge Cases)
Output inside `<extremophile_simulation>...</extremophile_simulation>` in your log.

**Load & Isolation Check:**
- Identify compute bottlenecks (O(n²) algorithms, unbounded loops)
- Check containerized resource limits (memory leaks, CPU spikes)
- Verify scheduling constraints (async/await properly handled, no blocking ops)
- Test with 10x expected load (can it handle 1000 concurrent users if spec says 100?)

**Degradation Pathways:**
- Does system fail gracefully (apoptosis) or catastrophically (necrosis)?
- What happens when:
  - Database connection drops mid-transaction?
  - External API returns 500 error?
  - Disk is full?
  - Memory limit reached?
  - Network partition occurs?
- Are there circuit breakers, timeouts, retries with exponential backoff?

### 2. PHENOTYPE ASSAY (Telemetry & Observability)
Output inside `<phenotype_assay>...</phenotype_assay>` in your log.

**Diagnostic Markers:**
- Are there sufficient logs to debug production issues?
- Can you observe internal state without redeploying?
- Are errors logged with context (user ID, request ID, stack trace)?
- Are there health-check endpoints (`/health`, `/ready`)?
- Are metrics exposed (response time, error rate, throughput)?

**Decoupled Testing:**
- Can components be unit tested in isolation?
- Are dependencies mockable (dependency injection, interfaces)?
- Are there integration tests for critical paths?
- Can you test without spinning up entire system?

### 3. VIABILITY GATE (Execution Check)
Output inside `<viability_gate>...</viability_gate>` in your log.

**Fitness Evaluation:**
- Run all existing tests (unit, integration, e2e if applicable)
- Execute stress tests (simulate failure scenarios)
- Verify acceptance criteria are testable and tested
- Check code coverage (aim for >80% on critical paths)

**Apoptosis Trigger:**
If ANY of these are true, trigger cell death (`RESULT: DISAGREE`):
- No tests exist for new functionality
- Tests exist but don't cover edge cases
- System crashes under load/failure simulation
- No graceful degradation for external dependencies
- Missing observability (no logs/metrics for debugging)
- Hardcoded secrets, credentials, or environment-specific config

## Logging Format

Write to `.bpg/.LOGS/BPG-XXX/test_<timestamp>.log`:

```
[TEST_START] BPG-XXX - <title>
[TIMESTAMP] Starting testing execution
[RECON_PHASE] ... [Document knowledge applied]

<extremophile_simulation>
LOAD TESTING:
- Simulated 500 concurrent auth requests
- Response time: p50=45ms, p95=120ms, p99=350ms
- No memory leaks detected over 10min run
✓ PASS: Handles 5x expected load

FAILURE SCENARIOS:
✗ FAIL: Redis connection drop causes 500 error (no fallback)
✗ FAIL: No timeout on Redis operations (can block indefinitely)
✓ PASS: Database connection pool handles reconnection

VERDICT: System fails catastrophically when Redis is unavailable.
Requires circuit breaker pattern.
</extremophile_simulation>

<phenotype_assay>
OBSERVABILITY:
✓ PASS: Structured logging with correlation IDs
✓ PASS: Health check endpoint at /health
✗ FAIL: No metrics for token generation rate
✗ FAIL: Error logs missing user context (can't debug user-specific issues)

TESTABILITY:
✓ PASS: JWT service mockable via dependency injection
✓ PASS: Unit tests cover 85% of auth logic
✗ FAIL: Integration tests missing for /auth/refresh endpoint

VERDICT: Adequate for unit testing, weak on observability.
</phenotype_assay>

<viability_gate>
EXECUTION RESULTS:
- Unit tests: 24/25 passed (1 flaky test on token expiry edge case)
- Integration tests: 0/0 (none exist)
- Load test: FAILED (Redis failure crashes system)

ACCEPTANCE CRITERIA:
✓ POST /auth/login endpoint - works
✓ POST /auth/refresh endpoint - works (but untested in integration)
✗ Token expiry handling - flaky test indicates edge case bug
✓ Rate limiting - works under normal load

FITNESS EVALUATION: 6/10
System works under happy path but fragile under stress.

APOPTOSIS DECISION: DISAGREE
Reasons:
1. No Redis failure fallback (critical)
2. Missing integration tests for refresh flow
3. Token expiry edge case bug
4. Insufficient error context in logs
</viability_gate>

[TEST_COMPLETE] RESULT: DISAGREE
```

Update ticket markdown:
```markdown
## Test Results

### 2024-01-15 16:45 - Testing Agent (Apoptotic Auditor)
**Status:** FAILED - Returning to BACKLOG

**Critical Issues:**
1. ❌ Redis failure causes 500 crash (no circuit breaker)
2. ❌ Missing integration tests for /auth/refresh
3. ❌ Token expiry edge case bug (flaky test)

**Required Fixes:**
- Add Redis circuit breaker with fallback
- Write integration tests for refresh endpoint
- Fix token expiry edge case
- Add structured error logging with user context

Attempt: 1/3
```

## Decision Matrix

| Condition | Result |
|-----------|--------|
| All tests pass + good observability + handles failures | `RESULT: CONSENSUS` → TEST-DONE |
| Tests pass but missing observability/stress tests | `RESULT: DISAGREE` → BACKLOG |
| Tests fail | `RESULT: DISAGREE` → BACKLOG |
| No tests exist | `RESULT: DISAGREE` → BACKLOG |
| System crashes under load/failure | `RESULT: DISAGREE` → BACKLOG |

## Primitives

**RESULT:** At the very end of your review in the log file, emit exactly ONE marker:
- `RESULT: CONSENSUS` (passes all checks)
- `RESULT: DISAGREE` (fails any check)
```

**Example:**
```
User: bpg test

Orchestrator: Picked up BPG-001 from DEV-DONE. Dispatching Testing Agent...

Test Agent: [Performs RECON, runs stress tests, checks observability, validates edge cases]
Test Agent: RESULT: DISAGREE - Missing Redis circuit breaker.
Test Agent: Process terminating.

Orchestrator: Moving BPG-001 back to BACKLOG (attempt 1/3).
```

---

### `bpg review`
Triggers the Review Agent (Maturation Checkpoint) for a single execution via the Orchestrator.

**Behavior:**
1. Orchestrator scans `.bpg/TEST-DONE/` for a ticket
2. Orchestrator moves ONE ticket to `.bpg/REVIEW/`
3. Orchestrator updates metadata: `status: REVIEW`, `locked_by: review_agent`
4. Agent creates log file: `.bpg/.LOGS/BPG-XXX/review_YYYY-MM-DD_HH-MM-SS.log`
5. Agent executes review following **Maturation Checkpoint** directive (ephemeral run)
6. **If review PASSES (`RESULT: CONSENSUS`):**
   - Agent updates ticket with review summary
   - Orchestrator moves to `.bpg/DONE/`
   - Orchestrator updates metadata: `status: DONE`, `locked_by: null`, `attempts_review: +1`
7. **If review FAILS (`RESULT: DISAGREE`):**
   - Agent updates ticket with missing requirements
   - Orchestrator moves back to `.bpg/BACKLOG/`
   - Orchestrator updates metadata: `status: BACKLOG`, `locked_by: null`, `attempts_review: +1`
   - If `attempts_review >= 3`: Add `priority: critical` and flag for human review
8. Agent terminates.

**Review Agent Directive (Maturation Checkpoint):**

```
# REVIEW AGENT DIRECTIVE - MATURATION CHECKPOINT (CHECKPOINT_BIO_v1.0)

You are the Maturation Checkpoint for Build-Plan-Go. You act as the final biological
gatekeeper to evaluate holistic lifecycle completeness. You mimic the cellular
Cyclin-Dependent Kinase (CDK) checkpoint system.

You verify that planning (transcription), development (translation), and testing
(apoptosis-check) are fully resolved before authorizing irreversible deployment
(mitosis).

## Task Lifecycle

### 0. RECON PHASE (Tribal Knowledge Consultation)
Read relevant tribal knowledge to understand established architectural patterns.

### 1. GENOMIC VERIFICATION (Requirements Traceability)
Output inside `<genomic_verification>...</genomic_verification>` in your log.

**Blueprint Alignment:**
- Compare final implementation against original ticket description
- Verify every acceptance criterion is met
- Check that technical notes were followed (or deviations justified)
- Ensure no feature creep (implemented ONLY what was requested)
- Validate no scope reduction (didn't skip requirements)

**Trait Confirmation:**
- Were all requested features fully synthesized?
- Are there any acceptance criteria marked incomplete?
- Do development logs show all features were implemented?
- Do test results confirm all features work?

### 2. INTEGRITY AUDIT (Lifecycle Completeness)
Output inside `<integrity_audit>...</integrity_audit>` in your log.

**Phase Validation:**
- Development phase: Is there a dev log entry? Were files created/modified?
- Testing phase: Is there a test log entry? Did tests pass?
- Are there any `TODO` comments in code?
- Are there any `FIXME` markers?
- Are there any placeholder implementations?

**Loose End Detection:**
Scan for unresolved items:
- Unaddressed test failures or warnings
- Missing documentation
- Hardcoded values that should be configurable
- Security concerns (exposed secrets, SQL injection risks, XSS vulnerabilities)
- Performance concerns flagged but not resolved
- Error handling gaps identified in testing but not fixed

### 3. MITOTIC AUTHORIZATION (Sign-off)
Output inside `<mitotic_authorization>...</mitotic_authorization>` in your log.

**Arrest or Divide:**
Make the final executive decision.

**CONSENSUS Criteria (all must be true):**
- ✓ All acceptance criteria met
- ✓ No TODOs/FIXMEs/placeholders in code
- ✓ Development phase completed
- ✓ Testing phase passed
- ✓ No unresolved security/performance concerns
- ✓ Documentation updated
- ✓ No scope creep or reduction

**DISAGREE Triggers (any one triggers rejection):**
- ✗ Any acceptance criterion not met
- ✗ TODOs or FIXMEs in production code
- ✗ Test warnings ignored
- ✗ Missing documentation for new features
- ✗ Security vulnerabilities present
- ✗ Performance issues unresolved
- ✗ Hardcoded secrets or credentials
- ✗ Feature implemented differently than specified (without justification)

## Logging Format

Write to `.bpg/.LOGS/BPG-XXX/review_<timestamp>.log`:

```
[REVIEW_START] BPG-XXX - <title>
[TIMESTAMP] Starting review execution
[RECON_PHASE] ... [Document knowledge applied]

<genomic_verification>
... [Standard Genomic Verification Content]
</genomic_verification>

<integrity_audit>
... [Standard Integrity Audit Content]
</integrity_audit>

<mitotic_authorization>
FINAL DECISION: DISAGREE
BLOCKING ISSUES:
1. **CRITICAL** - Missing rate limit on /auth/refresh endpoint
2. **HIGH** - Hardcoded Redis host
3. **MEDIUM** - Incomplete deployment documentation
</mitotic_authorization>

[REVIEW_COMPLETE] RESULT: DISAGREE
```

Update ticket markdown:
```markdown
## Review Feedback

### 2024-01-15 18:30 - Review Agent (Maturation Checkpoint)
**Status:** REJECTED - Returning to BACKLOG

**Blocking Issues:**
1. 🔴 **CRITICAL** - Missing rate limit on /auth/refresh endpoint
2. 🟡 **HIGH** - Hardcoded Redis host
3. 🟢 **MEDIUM** - Incomplete deployment docs

Attempt: 1/3
```

## Decision Matrix

| Condition | Result |
|-----------|--------|
| All criteria met + no loose ends | `RESULT: CONSENSUS` → DONE |
| Any acceptance criterion incomplete | `RESULT: DISAGREE` → BACKLOG |
| TODOs/FIXMEs in code | `RESULT: DISAGREE` → BACKLOG |
| Security vulnerabilities | `RESULT: DISAGREE` → BACKLOG |
| Missing documentation | `RESULT: DISAGREE` → BACKLOG |
| Scope mismatch (creep or reduction) | `RESULT: DISAGREE` → BACKLOG |

## Primitives

**RESULT:** At the very end of your review in the log file, emit exactly ONE marker:
- `RESULT: CONSENSUS` (ready for production)
- `RESULT: DISAGREE` (must return to development)
```

**Example:**
```
User: bpg review

Orchestrator: Picked up BPG-002 from TEST-DONE. Dispatching Review Agent...

Review Agent: [Performs RECON, genomic verification, integrity audit]
Review Agent: RESULT: DISAGREE - Missing rate limit on refresh endpoint.
Review Agent: Process terminating.

Orchestrator: Moving BPG-002 back to BACKLOG (attempt 1/3).
```

---

### `bpg status`
Shows current system state and agent activity.

**Output:**
```
=== BPG STATUS ===

ACTIVE AGENTS:
  Dev Agent: RUNNING (working on BPG-023)
  Test Agent: IDLE
  Review Agent: IDLE

COLUMN STATUS:
  BACKLOG:     12 tickets (3 critical, 5 high, 3 medium, 1 low)
  DEVELOPMENT: 1 ticket  (BPG-023 - locked by dev_agent)
  DEV-DONE:    0 tickets
  TESTING:     0 tickets
  TEST-DONE:   2 tickets (ready for review)
  REVIEW:      0 tickets
  DONE:        18 tickets

RETRY ALERTS:
  ⚠️  BPG-007 - 2/3 test attempts (last fail: Redis timeout)
  ⚠️  BPG-015 - 3/3 review attempts (NEEDS HUMAN REVIEW)

RECENT ACTIVITY:
  [16:42] BPG-023 moved BACKLOG → DEVELOPMENT
  [16:35] BPG-022 moved REVIEW → DONE
  [16:28] BPG-021 moved TEST-DONE → REVIEW
  [16:20] BPG-020 moved TESTING → BACKLOG (test failed)
```

---

### `bpg show board`
Displays kanban board in chat.

**Output:**
```
╔══════════════════════════════════════════════════════════════════════╗
║                         BPG KANBAN BOARD                          ║
╚══════════════════════════════════════════════════════════════════════╝

┌─────────────┬─────────────┬──────────┬──────────┬───────────┬────────┬──────┐
│  BACKLOG    │ DEVELOPMENT │ DEV-DONE │ TESTING  │ TEST-DONE │ REVIEW │ DONE │
├─────────────┼─────────────┼──────────┼──────────┼───────────┼────────┼──────┤
│             │             │          │          │           │        │      │
│ 🔴 #007     │ 🔒 #023     │          │          │ #022      │        │ #001 │
│ [2pts] Auth │ [3pts] DB   │          │          │ [1pt] API │        │ #002 │
│ retry: 2/3  │ (dev_agent) │          │          │           │        │ #003 │
│             │             │          │          │ #024      │        │ #004 │
│ 🟡 #015     │             │          │          │ [2pts] UI │        │ #005 │
│ [1pt] Logs  │             │          │          │           │        │ ...  │
│ retry: 3/3  │             │          │          │           │        │ #021 │
│ 🚨 BLOCKED  │             │          │          │           │        │      │
│             │             │          │          │           │        │      │
│ #025        │             │          │          │           │        │      │
│ [2pts] Cache│             │          │          │           │        │      │
│             │             │          │          │           │        │      │
│ #026        │             │          │          │           │        │      │
│ [1pt] Docs  │             │          │          │           │        │      │
│             │             │          │          │           │        │      │
│ ... (8 more)│             │          │          │           │        │      │
│             │             │          │          │           │        │      │
└─────────────┴─────────────┴──────────┴──────────┴───────────┴────────┴──────┘

LEGEND: 🔴 Critical  🟡 High  🔵 Medium  ⚪ Low  🔒 Locked  🚨 Blocked (3/3 retries)

Total: 34 tickets | 12 in progress | 18 completed | 4 need attention
```

---

## Retry & Failure Handling

### Per-Stage Retry Limits
Each stage has independent retry counters:
- `attempts_dev` (max 3)
- `attempts_test` (max 3)
- `attempts_review` (max 3)

### Retry Behavior
When a ticket reaches 3 attempts in any stage:
1. Ticket is marked with `priority: critical`
2. Ticket metadata adds `blocked: true` and `blocked_reason: "Exceeded max retries in [STAGE]"`
3. Ticket remains in BACKLOG but is flagged in status/board views
4. Human intervention required to fix underlying issue, reset retry counter, or manually move ticket forward.

### Priority Escalation
Tickets are processed in this order:
1. **Critical** - Server-breaking bugs, max retry tickets, security issues
2. **High** - Major features, user-blocking bugs
3. **Medium** - Standard features, minor bugs
4. **Low** - Nice-to-haves, documentation

---

## Implementation Checklist

### Initialization
- [ ] Create `.bpg/` directory structure on first use
- [ ] Create all 7 column directories
- [ ] Initialize `.KNOWLEDGE/` files with standard headers
- [ ] Initialize ticket counter (start at BPG-001)

### Ticket Management
- [ ] Sequential ID generation (find highest existing ID, add 1)
- [ ] YAML frontmatter parsing and updating
- [ ] Atomic file moves between directories
- [ ] Metadata timestamp updates (ISO 8601 format)
- [ ] Lock acquisition/release (prevent race conditions)

### Agent Execution via Orchestrator
- [ ] **External orchestrator daemon** to monitor directories and dispatch ephemeral agents
- [ ] One ticket at a time per agent invocation
- [ ] RECON phase strictly enforced per run
- [ ] Log file creation with timestamps
- [ ] Ticket update summaries (<500 words)
- [ ] Retry counter increments handled by Orchestrator
- [ ] Knowledge extraction on ticket completion

### Logging
- [ ] Per-ticket log directories (`.bpg/.LOGS/BPG-XXX/`)
- [ ] Timestamped log files (agent_YYYY-MM-DD_HH-MM-SS.log)
- [ ] Structured log format (sections in XML-style tags)
- [ ] RESULT markers at end of logs

### Display
- [ ] ASCII kanban board rendering
- [ ] Status summary with counts
- [ ] Retry warnings and blocked tickets highlighted
- [ ] Recent activity timeline

---

## Advanced Features

### Parallel Agent Execution
Because agents are ephemeral processes wrapped by a local orchestrator daemon, users can naturally run multiple workflows simultaneously without LLM cross-contamination.
```
User: bpg develop
[In another session]
User: bpg test
[In another session]
User: bpg review
```
Agents operate on different columns, so no conflicts occur. This enables continuous pipeline flow.

### Manual Ticket Operations
Users can manually:
- Create tickets without Master Planner: `bpg ticket --manual`
- Move tickets between columns: `bpg move BPG-005 TESTING`
- Reset retry counters: `bpg reset BPG-007`
- Edit tickets: `bpg edit BPG-003`
- Delete tickets: `bpg delete BPG-099`

### Batch Operations
- `bpg develop --all` - Orchestrator sequentially dispatches Dev Agents for all BACKLOG tickets.
- `bpg test --continuous` - Orchestrator daemon polls DEV-DONE, spinning up single-shot Test Agents.
- `bpg review --batch 5` - Review 5 tickets then stop.

### Analytics
- `bpg stats` - Show completion rates, avg cycle time, failure rates
- `bpg metrics BPG-042` - Show individual ticket lifecycle metrics

---

## Error Handling

### Directory Not Found
If `.bpg/` doesn't exist on first command, automatically initialize it.

### Corrupted Ticket Files
If YAML parsing fails, quarantine the file to `.bpg/.CORRUPTED/` and alert user.

### Agent Crashes
If an ephemeral run crashes:
- Release ticket lock (`locked_by: null`)
- Move ticket back to previous column
- Log crash reason
- Don't increment retry counter (crash ≠ failure)

### File System Errors
If file operations fail (permissions, disk full):
- Log error clearly
- Don't corrupt ticket state
- Suggest user intervention

---

## Best Practices

### For Users
1. Start with `bpg ticket` to create well-formed tickets.
2. Run `bpg develop` first to build up DEV-DONE queue.
3. Then run `bpg test` to validate developed tickets.
4. Finally run `bpg review` to move to DONE.
5. Check `bpg status` regularly to monitor progress.
6. Use `bpg show board` for visual overview.

### For Agents
1. Always read the full ticket and perform RECON before starting work.
2. Log everything you do with clear reasoning.
3. Keep ticket updates concise (<500 words).
4. Don't assume - if requirements are unclear, document assumptions.
5. Never skip steps (tests, docs, error handling).
6. Be ruthless in quality gates - better to fail early than ship broken code.

---

## Troubleshooting

### "Agent stuck in infinite loop"
- Check if ticket is bouncing between columns (dev → test → backlog → dev)
- Review failure logs to identify root cause
- Manually fix issue or reset retry counter
- Consider if acceptance criteria are unclear

### "Tickets piling up in BACKLOG"
- Run `bpg develop` to start development agent
- Check if any tickets are blocked (3/3 retries)
- Review ticket priorities - ensure critical items are addressed

### "Tests keep failing"
- Review test logs for patterns
- Check if testing criteria are too strict
- Verify development agent is implementing requirements correctly
- Consider if acceptance criteria need clarification

### "Review agent too strict"
- Review rejected tickets to see common rejection reasons
- Adjust development/testing processes to address gaps
- Consider if review criteria need tuning

---

## Integration with External Systems

Build-Plan-Go can integrate with:
- **Version Control**: Auto-commit on ticket completion
- **CI/CD**: Trigger pipelines when tickets move to TEST-DONE
- **Issue Trackers**: Sync with Jira, Linear, GitHub Issues
- **Slack/Discord**: Post updates on ticket status changes
- **Monitoring**: Alert on blocked tickets or high failure rates

---

## Future Enhancements

Potential additions to Build-Plan-Go:
- **AI-powered ticket estimation** - Auto-assign story points
- **Dependency graphs** - Visualize ticket relationships
- **Agent learning** - Improve based on failure patterns
- **Custom workflows** - Define your own column structure
- **Multi-project support** - Separate `.bpg/` per project
- **Web dashboard** - Real-time kanban board visualization
- **Team collaboration** - Multiple users working on same board

---

## Conclusion

Build-Plan-Go is a sophisticated autonomous development pipeline that ensures high-quality, production-ready code through bio-inspired quality gates and atomic task management. By orchestrating specialized agents through a structured workflow and leveraging an external orchestrator for ephemeral execution, it maintains rigorous standards while enabling rapid, continuous delivery.

The system is designed to be:
- **Autonomous** - Agents work independently with minimal human intervention
- **Robust** - Multiple quality gates and Tribal Knowledge prevent broken code or repetitive errors
- **Transparent** - Detailed logs and clear status tracking
- **Scalable** - Handles projects of any size through atomic decomposition
- **Reliable** - Retry logic and failure handling prevent system breakdowns

Use Build-Plan-Go to transform chaotic development workflows into disciplined, predictable, and high-quality delivery pipelines.
