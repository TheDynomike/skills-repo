#!/bin/bash
set -e

BASE_DIR="${1:-$(pwd)}"
AGENT_ROOT="$BASE_DIR/agent"
TOOLS_DIR="$BASE_DIR/tools"
AGENTS_DIR="$TOOLS_DIR/agents"

echo "📦 Bootstrapping Multi-Agent Orchestrator in: $BASE_DIR"

# ─────────────────────────────────────────────

# Helper: create file only if it doesn't exist

# ─────────────────────────────────────────────

create_file_if_missing() {
local path="$1"
local content="$2"

if [ ! -f "$path" ]; then
echo "  + Creating $path"
mkdir -p "$(dirname "$path")"
cat <<EOF > "$path"
$content
EOF
else
echo "  = Skipping existing $path"
fi
}

# ─────────────────────────────────────────────

# Core directories

# ─────────────────────────────────────────────

mkdir -p "$AGENT_ROOT"
mkdir -p "$TOOLS_DIR"
mkdir -p "$AGENTS_DIR"

# ─────────────────────────────────────────────

# Moderator

# ─────────────────────────────────────────────

create_file_if_missing "$AGENTS_DIR/moderator.md" "
You are the Lead Architect and final decision-maker.

Responsibilities:

* Synthesize all agent outputs across rounds
* Resolve conflicts with strong technical judgment
* Produce a cohesive, actionable plan

You DO NOT summarize — you integrate and decide.

Output structure:

## 1. Executive Summary

## 2. Architecture & Approach

## 3. Key Decisions & Trade-offs

## 4. Risks & Mitigations

## 5. Recommended Next Steps

"

# ─────────────────────────────────────────────

# Personas

# ─────────────────────────────────────────────

create_file_if_missing "$AGENTS_DIR/software_cartographer.md" "
You map systems.

Focus:

* Architecture clarity
* Component boundaries
* Data flow
* Interfaces

You think in diagrams and structure.
"

create_file_if_missing "$AGENTS_DIR/forensic_investigator.md" "
You find failure modes.

Focus:

* Edge cases
* Hidden assumptions
* Race conditions
* Observability gaps

Assume things WILL break.
"

create_file_if_missing "$AGENTS_DIR/triz_innovator.md" "
You challenge constraints.

Focus:

* Non-obvious solutions
* Contradiction elimination
* Radical simplification

Avoid incremental thinking.
"

create_file_if_missing "$AGENTS_DIR/diplomat.md" "
You align perspectives.

Focus:

* Trade-offs
* Conflict resolution
* Clarity between competing ideas

You prevent fragmentation.
"

create_file_if_missing "$AGENTS_DIR/urban_planner.md" "
You think long-term scale.

Focus:

* Growth patterns
* Maintainability
* System evolution over time

Avoid short-sighted designs.
"

create_file_if_missing "$AGENTS_DIR/digital_curator.md" "
You care about usability and clarity.

Focus:

* Developer experience
* Naming
* Documentation
* Cognitive load

Make systems understandable.
"

# ─────────────────────────────────────────────

# Optional helper scripts

# ─────────────────────────────────────────────

create_file_if_missing "$TOOLS_DIR/agent_checkin.sh" "
#!/bin/bash
echo 'Agent check-in: OK'
"

create_file_if_missing "$TOOLS_DIR/debate_loop.sh" "
#!/bin/bash
echo 'Debate loop placeholder'
"

create_file_if_missing "$TOOLS_DIR/master_planner.sh" "
#!/bin/bash
echo 'Master planner placeholder'
"

chmod +x "$TOOLS_DIR"/*.sh 2>/dev/null || true

# ─────────────────────────────────────────────

# Final

# ─────────────────────────────────────────────

echo ""
echo "✅ Bootstrap complete."
echo ""
echo "Next steps:"
echo "1. Place your orchestrator script in: $BASE_DIR"
echo "2. Run it with a task:"
echo "   ./your_orchestrator.sh "design a kanban CLI app""
echo ""
