# EZ-MODE
Skip everything below and just follow this:
```bash
# download the SKILL file and put it in this directory
# activate your agent (pi, gemini, etc.)
# ask your agent: install this skill globally: ./build-plan-go-SKILL.md
# ask your agent: bpg ticket make simple web app that serves hello world home page && bpg run pipeline
```

---

# Build-Plan-Go (BPG)

Build-Plan-Go is a multi-agent autonomous development workflow system that implements a bio-inspired, Kanban-style pipeline. It orchestrates specialized agents to handle planning, development, testing, and review with atomic precision and accumulated "tribal knowledge."

## 🚀 Key Features

- **Kanban Pipeline:** Tickets move through structured stages: `BACKLOG` → `DEVELOPMENT` → `DEV-DONE` → `TESTING` → `TEST-DONE` → `REVIEW` → `DONE`.
- **Specialized Agents:** 
  - **Master Planner:** Decomposes requests into atomic 1-3 point tickets.
  - **Development Agent:** Implements features with precision.
  - **Testing Agent (Apoptotic Auditor):** Rigorously stress-tests and audits code.
  - **Review Agent (Maturation Checkpoint):** Final gatekeeper for production readiness.
- **Tribal Knowledge:** An epigenetic memory layer (`.bpg/.KNOWLEDGE/`) that captures patterns, ADRs, and edge cases to prevent repeating past mistakes.
- **Quality Gates:** Built-in retry limits and failure handling to ensure only robust code reaches the `DONE` state.

## 📥 Installation

```bash
# Download the SKILL file and put it in this directory
# Activate your agent (pi, gemini, etc.)
install this skill globally: ./build-plan-go-SKILL.md
```

## 🛠️ Quick Start

1. **Create Tickets:** Use the Master Planner to turn your ideas into a backlog.
   ```bash
   bpg ticket Implement a REST API for user management
   ```
2. **Manual Progression:** Alternatively, run stages individually:
   ```bash
   bpg develop  # Pick up the highest priority ticket
   bpg test     # Audit the completed work
   bpg review   # Final sign-off
   ```
3. **Run Pipeline:** Execute a task through the entire backlog, development, testing, and review process in one go.
   ```bash
   bpg ticket make simple web app that serves hello world home page && bpg run pipeline
   ```
4. **Monitor Progress:**
   ```bash
   bpg status      # See active agents and column counts
   bpg show board  # View the visual Kanban board
   ```

## 📁 Directory Structure

BPG maintains state in a local `.bpg/` directory:

- `BACKLOG/`, `DEVELOPMENT/`, etc.: Ticket storage for each stage.
- `.LOGS/`: Detailed execution logs for every agent run.
- `.KNOWLEDGE/`: The system's "long-term memory" including heuristics and anti-patterns.

## 📖 Further Reading

For full technical specifications, agent directives, and advanced configuration, refer to [build-plan-go-SKILL.md](./build-plan-go-SKILL.md).
