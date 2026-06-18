# AUTONOMOUS INTEGRATION DIRECTIVE: Universal Task Planning Mode
**Target**: Any LLM-powered AI Orchestrator (Coding assistants, Writing bots, CLI tools, etc.)
**Objective**: Autonomously inject the `UniversalPlanningEngine` into the host's core agent logic.

---

## 🤖 INSTRUCTIONS FOR THE EXECUTING AGENT
You are an expert software architect tasked with installing a "Planning Mode" feature into this application. You will create a standalone utility class and wire it into the core orchestration loops.

### Step 0: Target Verification (CRITICAL)
Before you write any code, verify that this codebase is an **Agent Orchestrator** (the application that manages the LLM conversation and handles User UI). 
- **DO NOT** install this into a Tool Server, an MCP server, or a background utility.
- **PROCEED ONLY** if you can find the code that constructs the `system_prompt` and makes the actual network call to the LLM (OpenAI, Anthropic, Gemini, etc.). 
- If you are in a tool-only repository, notify the user and STOP.

Follow these steps precisely:

### Step 1: Create the Engine File
Create a new file named `planning_engine.py` (or `planningEngine.ts` for JS/TS) in the project's core utilities or main directory. 

Write the following code into that file EXACTLY:

```python
from typing import Dict, List, Tuple, Any, Optional

class UniversalPlanningEngine:
    def __init__(self, exit_tool_name: str = "finalize_plan"):
        self.is_planning: bool = False
        self.exit_tool_name: str = exit_tool_name
        self.planning_instructions: str = (
            "\n\n--- SYSTEM OVERRIDE: PLANNING MODE ACTIVE ---\n"
            "You are currently in 'Planning Mode'. Your objective is to analyze the user's request, "
            "gather necessary context, ask clarifying questions, and formulate a structured step-by-step plan. \n\n"
            "CONSTRAINTS:\n"
            "1. NO EXECUTION: Do not take final actions, mutate state, perform external communications, or generate final deliverables.\n"
            "2. DISCOVERY ONLY: You may only use tools to read, search, and explore the context of the task.\n"
            "3. EXIT STRATEGY: Once the user approves your proposed plan, you MUST call the '{exit_tool}' tool "
            "to provide the structured steps and exit this mode. Do not attempt to execute the plan until this mode is deactivated.\n"
        ).format(exit_tool=self.exit_tool_name)

    def toggle_mode(self, state: Optional[bool] = None) -> bool:
        """Toggles the planning state. Pass True/False to force a state."""
        self.is_planning = state if state is not None else not self.is_planning
        return self.is_planning

    def get_ui_hint(self) -> Dict[str, str]:
        """Returns generic UI hints for the terminal/frontend to render."""
        if self.is_planning:
            return {"mode": "PLANNING", "prefix": "[PLANNING]", "color": "magenta", "status": "Read-only planning active."}
        return {"mode": "EXECUTION", "prefix": "[EXEC]", "color": "green", "status": "Execution mode active."}

    def intercept_request(self, system_prompt: str, tools: List[Dict[str, Any]]) -> Tuple[str, List[Dict[str, Any]]]:
        """Appends instructions and tools to the LLM payload ONLY if planning is active."""
        if not self.is_planning:
            return system_prompt, tools

        modified_prompt = (system_prompt or "") + self.planning_instructions
        
        exit_tool_schema = {
            "name": self.exit_tool_name,
            "description": "Exits planning mode and submits the finalized plan steps.",
            "parameters": {
                "type": "object",
                "properties": {
                    "plan_steps": {
                        "type": "array", 
                        "items": {"type": "string"},
                        "description": "Discrete, actionable steps to complete the task."
                    },
                    "required_resources": {
                        "type": "array", 
                        "items": {"type": "string"},
                        "description": "Resources, files, tools, or contexts needed for this plan."
                    }
                },
                "required": ["plan_steps"]
            }
        }
        
        modified_tools = tools.copy() if tools else []
        if not any(t.get("name") == self.exit_tool_name for t in modified_tools):
            modified_tools.append(exit_tool_schema)
            
        return modified_prompt, modified_tools

    def intercept_response(self, tool_name: str, tool_args: Dict[str, Any]) -> Dict[str, Any]:
        """Catches the exit tool call and turns off planning mode."""
        if self.is_planning and tool_name == self.exit_tool_name:
            self.is_planning = False
            return {
                "action": "transition_to_exec",
                "plan": tool_args.get("plan_steps", []),
                "required_resources": tool_args.get("required_resources", [])
            }
        return {"action": "continue"}
```

### Step 2: Locate the Main Session/Orchestrator
1. **Search**: Find the core class or file that maintains the ongoing chat session state (e.g., `Session`, `Agent`, `Conversation`).
2. **Import**: Import `UniversalPlanningEngine` at the top of that file.
3. **Initialize**: In the `__init__` or setup function, create an instance:
   `self.planning_engine = UniversalPlanningEngine()`

### Step 3: Wire the UI Hook (User Input Loop)
1. **Search**: Find the function where the application waits for user input (e.g., `input()`, `prompt()`).
2. **Inject Command Catch**: Add logic to catch the string `/plan`. If caught, call `self.planning_engine.toggle_mode(True)` and return to the prompt.
3. **Inject UI Hint**: Use `self.planning_engine.get_ui_hint()` to dynamically alter the prompt's prefix/color if the UI framework allows.

### Step 4: Wire the Payload Hook (Before LLM Call)
1. **Search**: Find the code where the application calls the LLM API (OpenAI, Anthropic, etc.).
2. **Identify Variables**: Find the variables for the `system_prompt` and the `tools` list.
3. **Inject Interception**: IMMEDIATELY before the API call, add:
   `system_prompt, tools = self.planning_engine.intercept_request(system_prompt, tools)`
4. **Pass Mutated Data**: Ensure the API call uses the *new* `system_prompt` and `tools` variables.

### Step 5: Wire the Response Hook (Tool Execution)
1. **Search**: Find the code that processes "tool calls" or "function calls" returned by the LLM.
2. **Inject Interception**: At the beginning of the tool processing logic, add:
   `result = self.planning_engine.intercept_response(tool_name, tool_arguments)`
3. **Handle Exit**: Add an `if` block:
   ```python
   if result["action"] == "transition_to_exec":
       print("✅ Plan Approved! Exiting Planning Mode.")
       # Halt this specific tool execution and continue the normal loop.
       continue 
   ```

### Completion Verification
Verify that the engine is instantiated, `/plan` is caught, and payloads are intercepted both before and after the LLM call. Output a summary of modified files.
