#!/bin/bash
# =====================================================================
# Sequential Multi-Agent Planner Orchestrator
# Features: Sequential execution, Strict Marker Consensus, Dynamic Synthesis
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

# ═══════════════════════  SEQUENTIAL DEBATE LOOP ════════════════════

while [ $ROUND -le $MAX_ROUNDS ]; do
  echo "━━━━━━━━━━━━━━━━ ROUND $ROUND / $MAX_ROUNDS ━━━━━━━━━━━━━━━━"
  
  PERSONAS=()

  # Launch an independent evaluation for every persona in the agents folder sequentially
  for persona_file in "$AGENTS_DIR"/*.md; do
      persona_name=$(basename "$persona_file" .md)
      if [ "$persona_name" == "moderator" ]; then continue; fi

      system_prompt=$(cat "$persona_file")
      response_file="$STATE_DIR/${persona_name}_response.md"
      
      echo "[Round $ROUND] $persona_name reviewing independently..."
      
      # Run synchronously (removed the trailing '&')
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
" > "$response_file"
      
      PERSONAS+=("$persona_name")
  done

  # (Removed the 'wait "${PIDS[@]}"' since jobs are no longer running in the background)

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
