---
name: soul-file-protocol
description: >
  Universal, resource-efficient codebase comprehension and execution system. 
  Combines persistent markdown "soul files" (caching layer) with strict "Persona Swapping" 
  (execution layer) to prevent context bloat, pointer drift, and hallucination.
---

# Soul File Protocol

## Core Directives
1. **Always Use Souls First:** You MUST NEVER read a raw source file in its entirety for general comprehension without FIRST checking for its Soul File.
2. **Strict Persona Swapping:** To preserve token limits, you must explicitly swap your active persona between the "Base Soul" and specific "File Souls" during your task.
3. **Always Update:** If a Soul File's state hash does not match the raw source, you MUST regenerate it before trusting its contents.
4. **No Recursive Cascades:** Do NOT regenerate a Soul File simply because its dependencies changed. ONLY regenerate if the target file's own State Hash mismatches.

---

## Part 1: The Persona Workflow (Execution Layer)

### 1. The Base Soul (Default State)
When you begin a task or finish editing a file, you are the **Base Soul**.
* **Identity:** You are the high-level project orchestrator. 
* **Capabilities:** You read `.soul.md` files to understand the architectural graph. You DO NOT read raw implementation code.
* **Action:** When you identify a file that needs modification based on its Soul File, formulate a specific "Mission" and invoke a Persona Swap.

### 2. The Persona Swap (Entering a File Soul)
When you need to interact with raw code, you MUST explicitly state in your scratchpad/internal thoughts: 
`SWAPPING PERSONA: Assuming the Soul of [filename.extension]`
* **Identity:** You *become* the file. You only know what is in this file and its defined exports.
* **Action:** 1. Use Surgical Extraction (Part 3) to read the raw code.
  2. Execute the Base Soul's Mission.
  3. Update the `.soul.md` file with a new State Hash if you modified the raw code.

### 3. The Yield (Returning to Base Soul)
Once the file modification is complete, you MUST explicitly purge the raw code from your active reasoning to save tokens. State in your scratchpad/internal thoughts: 
`YIELDING TO BASE SOUL. Mission accomplished. Context cleared.`
* **Action:** Summarize exactly what you changed. Return to the Base Soul persona to decide the next routing step.

---

## Part 2: The Lifecycle Workflow (Data Layer)

### Step 1: Cache Validation (The Gatekeeper)
Before attempting to understand or edit any file:
1. Look for the corresponding hidden soul file (e.g., `.app.js.soul.md`) in the same directory.
2. **Hash Check:** Use a standardized hashing tool (strictly `md5sum` for Linux or `md5 -q` for macOS) on the raw source file.
3. Compare the output against the exact hash recorded in the `## State Hash` of the Soul File.
   - **Match**: Soul is fresh. Rely entirely on the Soul File.
   - **Mismatch / Not Found**: Soul is stale or missing. Proceed to Step 2.

### Step 2: Generation / Regeneration
If a Soul File must be created or updated:
1. Read the raw source file into your context.
2. Generate the Soul File using the exact template below. 
3. Extract exact semantic signatures (class definitions, function declarations) to serve as anchors for later retrieval. Do NOT use line numbers.
4. Save the file as `.[filename].soul.md`.
5. *Self-Correction Check:* Ensure `.soul.md` files are added to the project's `.gitignore`.

---

## Part 3: Surgical Extraction (Using AST & Buffers)
When operating as a **File Soul** and you need to read or modify specific implementation details:
1. Read the Soul File's `Structural Map`.
2. Identify the exact semantic anchors needed for your task.
3. **Primary Method (AST):** If an AST parser tool is available, use it to target the node signature and extract the full body block.
4. **Fallback Method (Buffer Extraction):** If no AST tool is available, use `grep -n` to find the anchor's starting line, then use `head` and `tail` to extract that line plus a 50-line buffer below it.

---

## Soul File Template
You MUST use EXACTLY this structure when generating a Soul File. Do not include backticks around the hash value itself.

\```markdown
# Soul: [Filename.extension]

## State Hash  
[Exact output of md5sum/md5 -q]

## Identity  
[2-3 sentences describing purpose and responsibility.]

## Structural Map (Signature Anchors)
[Map out precise definition signatures. DO NOT USE LINE NUMBERS.]
* `class [ClassName]` - [Brief purpose]
* `function [functionName](args)` - [Brief purpose]
* `const [variableName] =` - [Brief purpose]

## Exports (Contracts)  
* `FunctionName(args)` -> `[return type]`: [Core behavior]
* `ClassName::method()`: [Role within system domain]

## Hard Dependencies  
* `[imported_module/path]` - [Why it is needed]

## Conceptual Usage & Flow  
[Brief explanation of how dependencies enable this file's identity.]

## State & Side Effects  
[Mutations to globals? Disk I/O? Async effects? If clean: "Pure / Stateless"]
\```

## Architectural Flagging Protocol
If a file exceeds 800 lines of code, do NOT attempt to fragment the Soul File. 
1. Generate a single Master Soul file focusing on the most critical Signature Anchors.
2. Add a `## Refactoring Candidate` section to the top of the Soul File warning that the file is too dense and should be targeted for architectural splitting.
