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

Download the skill file and put it in the current directory and run:

```bash
# Activate your agent (pi, gemini, etc.)
install this skill globally: ./build-plan-go-SKILL.md
```

## 🛠️ Quick Start

1. **Initialize:** Run any BPG command in your project root to initialize the `.bpg/` directory structure.
2. **Create Tickets:** Use the Master Planner to turn your ideas into a backlog.
   ```bash
   bpg ticket "Implement a REST API for user management"
   ```
3. **Start the Pipeline:**
   ```bash
   bpg develop  # Pick up the highest priority ticket
   bpg test     # Audit the completed work
   bpg review   # Final sign-off
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
