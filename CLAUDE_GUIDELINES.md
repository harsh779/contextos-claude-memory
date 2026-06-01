# Claude Code Guidelines

Drop this file into your project root as `CLAUDE.md`.
Claude Code reads it automatically on every session.

---

## 1. Think Before Coding

- State your assumptions before writing code.
- Surface tradeoffs explicitly — don't silently pick one path.
- If the requirement is ambiguous, ask. Don't guess and build.
- For non-trivial changes: outline the approach in 3-5 bullets first.

## 2. Simplicity First

- Write the minimum code that solves the problem.
- No speculative features. No "while we're here" additions.
- Don't create abstractions for single-use patterns.
- Prefer standard library over third-party when the difference is trivial.
- Delete dead code. Don't comment it out "just in case."

## 3. Surgical Changes

- Touch only the files and lines required by the task.
- Match the existing code style — indentation, naming, patterns.
- Don't reformat, reorganize, or "clean up" code outside your diff.
- If you break something unrelated, revert your change and rethink.
- One concern per commit. Don't bundle refactors with features.

## 4. Goal-Driven Execution

- Transform every task into a verifiable goal before starting.
- Define what "done" looks like: a passing test, a visible output, a measurable state.
- After implementing, verify against the goal. If it doesn't pass, loop.
- Don't mark work complete until verification succeeds.

## 5. Testing Discipline

- New logic gets a test. Bug fixes get a regression test.
- Run the existing test suite before and after changes.
- If tests fail after your change, fix the cause — don't skip the test.

## 6. Error Handling

- Handle errors at the boundary where you can do something useful.
- Fail loud with actionable messages. No silent swallowing.
- Log context: what was attempted, what failed, what the user should do.

---

## ContextOS Integration

If this project uses [ContextOS](https://github.com/harsh779/contextos-claude-memory):

- **Memory is automatic.** ContextOS injects project context (decisions,
  actions, blockers) into every session. Don't duplicate that information
  in this file.
- **Reference, don't repeat.** When a decision or blocker is relevant,
  point to the memory file by path (e.g., `memory/decisions.md`) instead
  of restating it.
- **Keep this file for behavioral rules only.** Project-specific facts,
  architecture notes, and historical decisions belong in ContextOS memory,
  not here.
- **Trust the injection.** If ContextOS is configured, Claude already has
  the project context. Don't add "read memory files first" instructions —
  that happens automatically.
