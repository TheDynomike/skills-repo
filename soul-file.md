---
name: soul-file
description: >
  Universal, resource-efficient codebase comprehension system using persistent markdown "soul files". 
  Mandatory caching layer for understanding source code across any application architecture. Creates .filename.soul.md files 
  that capture file identity, exports, semantic signature anchors, and state effects.
  Enables full codebase awareness while aggressively preserving token limits, preventing pointer drift, and maintaining deterministic cache states.
---

# Soul File Protocol

## Core Directives
1. **Always Use Souls:** You MUST NEVER read a raw source file in its entirety for general comprehension without FIRST checking for its Soul File.
2. **Always Create:** If a Soul File does not exist for a target file, you MUST create it immediately.
3. **Always Update:** If a Soul File's state hash does not match the raw source, you MUST regenerate it before trusting its contents.
4. **No Recursive Cascades:** Do NOT regenerate a Soul File simply because its dependencies changed. ONLY regenerate if the target file's own State Hash mismatches.

## The Lifecycle Workflow

### Step 1: Cache Validation (The Gatekeeper)
Before attempting to understand or edit any file:
1. Look for the corresponding hidden soul file (e.g., `.app.js.soul.md`) in the same directory.
2. **Hash Check:** Use a standardized hashing tool (strictly `md5sum` for Linux or `md5 -q` for macOS) on the raw source file to generate a clean string.
3. Compare the output against the exact hash recorded in the `## State Hash` of the Soul File.
   - **Match**: Soul is fresh. Do NOT read the raw file. Rely entirely on the Soul File.
   - **Mismatch / Not Found**: Soul is stale or missing. Proceed to Step 2.

### Step 2: Generation / Regeneration
If a Soul File must be created or updated:
1. Read the raw source file into your context.
2. Generate the Soul File using the exact template below. 
3. Extract exact semantic signatures (class definitions, function declarations) to serve as anchors for later retrieval. Do NOT use line numbers.
4. Save the file as `.[filename].soul.md`.
5. *Self-Correction Check:* Ensure `.soul.md` files are added to the project's `.gitignore` if not already present.

### Step 3: Surgical Extraction (Using AST & Buffers)
When you need to read or modify specific implementation details without loading the full file:
1. Read the Soul File's `Structural Map`.
2. Identify the exact semantic anchors needed for your task.
3. **Primary Method (AST):** If an Abstract Syntax Tree (AST) parser tool is available, use it to target the node signature and extract the full body block.
4. **Fallback Method (Buffer Extraction):** If no AST tool is available, use `grep -n` to find the anchor's starting line, then use `head` and `tail` to extract that line plus a 50-line buffer below it.

---

## Soul File Template
You MUST use EXACTLY this structure when generating a Soul File. Do not include backticks around the hash value itself.

```markdown
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

## Architectural Flagging Protocol (For Files > 800 lines)
If a file exceeds 800 lines of code, do NOT attempt to fragment the Soul File. 
1. Generate a single Master Soul file focusing on the most critical Signature Anchors.
2. Add a `## Refactoring Candidate` section to the top of the Soul File warning that the file is too dense and should be targeted for architectural splitting into discrete modules.
