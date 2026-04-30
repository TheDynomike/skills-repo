# Create planner tool master_planner.sh (in [your .pi dir]/tools/) (make sure chmod +x [your .pi dir]/tools/master_planner.sh)
```
#!/bin/bash
# =====================================================================
# Parallel Multi-Agent Planner Orchestrator
# Features: Parallel execution, Strict Marker Consensus, Dynamic Synthesis
# =====================================================================

TASK="${*:-$1}"

if [ -z "$TASK" ]; then
  echo "ERROR: No task provided." >&2
  exit 1
fi

# Ensure the pi CLI is available
if ! command -v pi &> /dev/null; then
    echo "ERROR: 'pi' command not found. Ensure the pi CLI is installed." >&2
    exit 1
fi

# Setup portable paths
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DIR="$BASE_DIR/agents"
STATE_DIR="/tmp/pi_debate_$$_$(date +%s)"
mkdir -p "$STATE_DIR"

if [ ! -d "$AGENTS_DIR" ]; then
    echo "ERROR: Agents directory not found at $AGENTS_DIR. Run the setup script first." >&2
    exit 1
fi

MODERATOR_PROMPT=$(cat "$AGENTS_DIR/moderator.md")
PLAN_FILE="$STATE_DIR/plan_of_action.md"
FINAL_PLAN="$STATE_DIR/final_plan_of_action.md"

ROUND=1
MAX_ROUNDS=5

# ══════════════════  PHASE 1: INITIAL PLAN ══════════════════
echo "[Phase 0] MODERATOR: Creating initial master plan..."

plan=$(pi --system-prompt "$MODERATOR_PROMPT" "
## MODERATOR ROLE
Create a structured architectural and execution plan for: $TASK

Use this structure:
## 1. Overview
## 2. High-Level Architecture
## 3. Execution Steps
## 4. Key Engineering Decisions
## 5. Potential Risks & Mitigations
")

echo "$plan" > "$PLAN_FILE"

# ═══════════════════════  PARALLEL DEBATE LOOP ════════════════════

while [ $ROUND -le $MAX_ROUNDS ]; do
  echo "━━━━━━━━━━━━━━━━ ROUND $ROUND / $MAX_ROUNDS ━━━━━━━━━━━━━━━━"
  
  PIDS=()
  PERSONAS=()

  # Launch an independent evaluation for every persona in the agents folder (except moderator)
  for persona_file in "$AGENTS_DIR"/*.md; do
      persona_name=$(basename "$persona_file" .md)
      if [ "$persona_name" == "moderator" ]; then continue; fi

      system_prompt=$(cat "$persona_file")
      response_file="$STATE_DIR/${persona_name}_response.md"
      
      echo "[Round $ROUND] $persona_name reviewing independently..."
      
      # Run in background
      pi --system-prompt "$system_prompt" "
### Context
Task: $TASK

Current Proposed Plan:
$plan

### Instructions
Critique the plan strictly from your specific persona's perspective. Do you agree that the plan safely and completely addresses your domain's concerns?
If modifications are needed, detail them explicitly.

At the VERY END of your response, you MUST include exactly ONE of these markers on its own line:
RESULT: CONSENSUS
RESULT: DISAGREE
" > "$response_file" &
      
      PIDS+=($!)
      PERSONAS+=("$persona_name")
  done

  # Wait for all parallel agent calls to finish
  wait "${PIDS[@]}"

  # --- Check for Absolute Consensus ---
  CONSENSUS_COUNT=0
  TOTAL_AGENTS=${#PERSONAS[@]}
  DISAGREEMENT_FEEDBACK=""

  for persona_name in "${PERSONAS[@]}"; do
      response_file="$STATE_DIR/${persona_name}_response.md"
      
      if grep -q "RESULT: CONSENSUS" "$response_file"; then
          ((CONSENSUS_COUNT++))
      else
          # If they disagreed (or failed to output a valid marker), capture their feedback
          DISAGREEMENT_FEEDBACK+="### Feedback from ${persona_name}:\n$(cat "$response_file")\n\n"
      fi
  done

  if [ "$CONSENSUS_COUNT" -eq "$TOTAL_AGENTS" ]; then
    echo ">>> ABSOLUTE CONSENSUS REACHED in round $ROUND ($CONSENSUS_COUNT/$TOTAL_AGENTS agents)."
    cp "$PLAN_FILE" "$FINAL_PLAN"
    break
  else
    echo ">>> $CONSENSUS_COUNT/$TOTAL_AGENTS agents agreed. Consensus failed."
  fi

  # --- No Consensus: Moderator Synthesizes Feedback ---
  echo "[Round $ROUND] Moderator synthesizing feedback from dissenting agents..."

  plan=$(pi --system-prompt "$MODERATOR_PROMPT" "
## MODERATOR UPDATE (Round $ROUND)
You are the Lead Architect refining the master plan. Consensus was not reached. 
You must incorporate the following independent feedback from dissenting engineering personas into a more robust plan. 
If their technical constraints conflict, resolve them logically to create a unified strategy.

Task: $TASK

### Current Plan:
$plan

### Dissenting Feedback:
$DISAGREEMENT_FEEDBACK

Output the FULLY REWRITTEN and UPDATED Markdown plan now. Do not include meta-commentary, just the new plan.
")
  
  echo "$plan" > "$PLAN_FILE"
  ((ROUND++))
done

# ═══════════════════════  FINAL OUTPUT ════════════════════

if [ $ROUND -gt $MAX_ROUNDS ]; then
  echo "!! Max rounds reached. Finalizing with latest iteration."
  cp "$PLAN_FILE" "$FINAL_PLAN"
fi

echo -e "\n==== FINAL PLAN OF ACTION ====\n"
cat "$FINAL_PLAN"

echo -e "\n💾 Temporary working files left in $STATE_DIR for debugging."
```


# Create the agents for the tool-call (in pi [your .pi dir]/tools/agents)
```
mkdir -p agents

cat << 'EOF' > agents/forensic_investigator.md
You are the Forensic Investigator. Your primary function is to resolve complex bugs, race conditions, and system failures. You prioritize the preservation of the "scene of failure" to ensure volatile memory and network logs are not lost. Utilize abductive reasoning to trace symptoms back to their true origins. Demand rigorous Root Cause Analysis and refuse short-term patches that worsen fundamental problems.
EOF

cat << 'EOF' > agents/software_cartographer.md
You are the Software Cartographer. Your role is to describe the software system at a higher level of abstraction and ensure the mental map of the system remains perfectly in sync with the actual code. You focus on spatial location awareness, highlighting domain relationships, execution contexts, and cross-service dependencies.
EOF

cat << 'EOF' > agents/diplomat.md
You are the Diplomat. You act as a mediator in technical decision-making and architectural debates. You sit between the "craftspeople" and the "hustlers". You constantly ask: "What is the real problem we are trying to solve?". Your primary metric is how easily the system can be understood, modified, and maintained by others in the future.
EOF

cat << 'EOF' > agents/triz_innovator.md
You are the TRIZ Innovator. You rely on the Theory of Inventive Problem Solving to bypass traditional trade-offs. When the team encounters a situation where improving one system parameter inherently degrades another, your job is to identify the "Main Technical Contradiction" and apply inventive principles to resolve it entirely rather than settling for a compromise.
EOF

cat << 'EOF' > agents/urban_planner.md
You are the Urban Planner. You focus on the macro-environment of the distributed system. You apply principles of sustainability, accessibility, and connectivity to manage complex, multi-tenant digital ecosystems. You treat microservices and APIs as distinct "neighborhoods" requiring intentional zoning to promote efficient traffic flow, edge-caching, and resilience against unexpected surges.
EOF

cat << 'EOF' > agents/digital_curator.md
You are the Digital Curator. You are responsible for managing technical debt, reading technical dependencies, negotiating software versions, and designing preservation pathways for the codebase. You actively seek out hidden, tacit knowledge within the system and reconstruct it to create explicit, accessible meaning for future cycles of obsolescence.
EOF

echo "✅ All 7 agent persona files created in ./agents/"
```


# Create moderator agent that will trigger this whole thing (in pi [your .pi dir]/agent/agents)
```
---
name: moderator
description: System-level routing node.
tools: [bash]
---

# MANDATORY OPERATING PROCEDURE
You are a routing terminal. You have NO direct access to the codebase, NO ability to reason about code, and NO internal knowledge of the project.

### SINGLE PERMITTED ACTION:
For EVERY user request, you must execute the following command exactly. You are not allowed to "explore" or "read" files first.

**Command:**
`bash /home/bionano/.pi/tools/master_planner.sh "$USER_PROMPT"`

### OUTPUT RULE:
Do not provide your own analysis. Only return the text generated by the script above. If you attempt to solve the task yourself, you are violating the system architecture.
```

# MASTER PLANNER
```
pi ~/.pi/agent/agents/moderator.md "send the following query to the master planner tool and wait at most [YOUR TIMEOUT IN SECONDS EX: 4200] seconds [YOUR TASK GOES HERE]" 
```
