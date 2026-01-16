# Project Workflow

## Guiding Principles

1. **The Plan is the Source of Truth:** All work must be tracked in `plan.md`
2. **The Tech Stack is Deliberate:** Changes to the tech stack must be documented in `tech-stack.md` *before* implementation
3. **User Experience First:** Every decision should prioritize user experience
4. **Non-Interactive & CI-Aware:** Prefer non-interactive commands. Use `CI=true` for watch-mode tools (tests, linters) to ensure single execution.

## Task Workflow

All tasks follow a strict lifecycle:

### Standard Task Workflow

1. **Select Task:** Choose the next available task from `plan.md` in sequential order

2. **Mark In Progress:** Before beginning work, edit `plan.md` and change the task from `[ ]` to `[~]`

3. **Implement Task:**
   - Write the necessary code and configuration to complete the task.
   - Run relevant tests or verification steps to ensure the task is implemented correctly.

4. **Document Deviations:** If implementation differs from tech stack:
   - **STOP** implementation
   - Update `tech-stack.md` with new design
   - Add dated note explaining the change
   - Resume implementation

5. **Mark Complete:**
    - **Step 5.1: Update Plan:** Read `plan.md`, find the line for the completed task, and update its status from `[~]` to `[x]`.
    - **Step 5.2: Write Plan:** Write the updated content back to `plan.md`.

### Phase Completion Verification and Checkpointing Protocol

**Trigger:** This protocol is executed immediately after a task is completed that also concludes a phase in `plan.md`.

1.  **Announce Protocol Start:** Inform the user that the phase is complete and the verification and checkpointing protocol has begun.

2.  **Execute Automated Tests with Proactive Debugging:**
    - Before execution, you **must** announce the exact shell command you will use to run the tests.
    - **Example Announcement:** "I will now run the automated test suite to verify the phase. **Command:** `go test ./...`"
    - Execute the announced command.
    - If tests fail, you **must** inform the user and begin debugging. You may attempt to propose a fix a **maximum of two times**. If the tests still fail after your second proposed fix, you **must stop**, report the persistent failure, and ask the user for guidance.

3.  **Propose a Detailed, Actionable Manual Verification Plan:**
    - **CRITICAL:** To generate the plan, first analyze `product.md`, `product-guidelines.md`, and `plan.md` to determine the user-facing goals of the completed phase.
    - You **must** generate a step-by-step plan that walks the user through the verification process, including any necessary commands and specific, expected outcomes.
    - The plan you present to the user **must** follow this format:

        **For a Technical Change:**
        ```
        The automated tests have passed. For manual verification, please follow these steps:

        **Manual Verification Steps:**
        1.  **Run the experiment with:** `skaffold run -p <profile>`
        2.  **Verify the output:** Check logs for expected behavior.
        ```

4.  **Await Explicit User Feedback:**
    - After presenting the detailed plan, ask the user for confirmation: "**Does this meet your expectations? Please confirm with yes or provide feedback on what needs to be changed.**"
    - **PAUSE** and await the user's response. Do not proceed without an explicit yes or confirmation.

5.  **Commit All Changes:**
    - Stage all changes related to the completed phase.
    - Perform the commit with a clear and concise message (e.g., `feat(phase): Complete Phase X - <Phase Name>`).

6.  **Get and Record Phase Checkpoint SHA:**
    - **Step 6.1: Get Commit Hash:** Obtain the hash of the *just-created checkpoint commit* (`git log -1 --format="%H"`).
    - **Step 6.2: Update Plan:** Read `plan.md`, find the heading for the completed phase, and append the first 7 characters of the commit hash in the format `[checkpoint: <sha>]`.
    - **Step 6.3: Write Plan:** Write the updated content back to `plan.md`.

7. **Commit Plan Update:**
    - **Action:** Stage the modified `plan.md` file.
    - **Action:** Commit this change with a descriptive message following the format `conductor(plan): Mark phase '<PHASE NAME>' as complete`.

8.  **Announce Completion:** Inform the user that the phase is complete and the checkpoint has been created.

### Quality Gates

Before marking any task complete, verify:

- [ ] Task goals are met
- [ ] Code follows project's code style guidelines (as defined in `code_styleguides/`)
- [ ] No linting or static analysis errors (using the project's configured tools)
- [ ] Documentation updated if needed

## Development Commands

### Setup
```bash
go mod tidy
```

### Daily Development
```bash
go test ./...
go fmt ./...
```

## Commit Guidelines

### Message Format
```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting, missing semicolons, etc.
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests
- `chore`: Maintenance tasks
- `conductor`: Conductor-related tasks (plan updates, setup)

## Definition of Done

A task is complete when:

1. All code implemented to specification
2. Implementation notes added to `plan.md`
3. Changes pass basic verification

A phase is complete when:
1. All phase tasks are marked complete
2. Automated tests pass
3. Manual verification confirmed by user
4. All changes committed with proper message