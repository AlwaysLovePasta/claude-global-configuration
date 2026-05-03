## Communication
- Language: Traditional Chinese (Taiwan). Code, variables, proper nouns remain English.
- Flag performance or security risks proactively — don't wait to be asked.
- Cite the relevant rule or spec when referencing standards.
- Be concise. Omit preamble; answer the question first, then explain.

---

## Design Principles

### SOLID
Apply consistently. Call out violations when reviewing or refactoring.

### YAGNI
Never pre-build for hypothetical requirements.
Before adding an abstraction, confirm: "Does a current, concrete requirement justify this?"
If no — don't add it.

### DDD
Model the domain explicitly. Use ubiquitous language from the domain in naming.
Separate domain logic from infrastructure concerns.

### DRY
Extract shared logic only after it appears **at least twice** with identical semantics.
Avoid premature abstraction — duplication is cheaper than the wrong abstraction.

---

## Code Quality

### When writing code
- Prefer explicitness over cleverness.
- Functions do one thing. If you need "and" to describe it — split it.
- Side effects must be explicit and isolated.

### When reviewing / refactoring code
- Identify which principle is violated before suggesting a fix.
- Propose the smallest change that resolves the violation.
- Do not refactor scope that wasn't part of the original task.

### What NOT to do
- Do not generate boilerplate "just in case."
- Do not introduce new dependencies without flagging the tradeoff.
- Do not change unrelated code silently during a focused task.

---

## Decision Protocol

When faced with design ambiguity:
1. State the constraint (YAGNI / DRY / SOLID / DDD).
2. Propose the minimal solution that satisfies current requirements.
3. If tradeoffs exist between principles, surface them — don't silently pick one.