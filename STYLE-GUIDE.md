# Writing Style Guide

How content in this wiki should read. These rules apply to all contributors -- human and AI.

---

## Voice

### Guides and Reference

Guides teach. They should be dry, precise, and direct. The reader came to learn how something works or how to do something. Respect their time.

- State things directly. No buildup, no throat-clearing, no preamble.
- Use imperative or declarative sentences. "Add the field to Config" or "Claude reads the system prompt first."
- Use second person ("you") when addressing the reader.
- First person ("I", "we") is fine in introductions to establish context but should not dominate.

### Perspectives

Perspective pieces are opinion. They can have personality, take positions, and use a conversational tone. But the same structural rules apply -- no filler, no slop.

---

## Anti-Patterns to Avoid

These patterns are characteristic of AI-generated content. They make writing feel generic and hollow. Avoid them in all content types.

### Contrastive Reframes

The "It's not X, it's Y" structure. LLMs use this constantly because it creates the feeling of depth without saying anything substantive.

```text
Bad:  "Claude Code isn't just a tool -- it's a development partner."
Bad:  "This isn't about speed, it's about quality."
Bad:  "We're not just building features, we're crafting experiences."

Good: "Claude Code reads your codebase, runs commands, and iterates on
       test failures autonomously."
```

If something matters, describe what it does. Don't set up a false dichotomy to make it sound important.

### Superlative Filler

Words that sound impressive but carry no information: "powerful", "seamless", "elegant", "robust", "cutting-edge", "game-changing", "next-level."

```text
Bad:  "a powerful framework for seamless integration"
Good: "a framework that handles auth, routing, and database connections"
```

If you can remove the adjective and the sentence still works, remove it.

### Triplet Lists

LLMs love grouping things in threes for rhetorical effect, especially abstract nouns.

```text
Bad:  "speed, precision, and reliability"
Bad:  "clarity, consistency, and confidence"

Good: Describe the specific thing you mean. If three items genuinely
      belong together, that's fine -- but check that each one adds
      information rather than rhythm.
```

### The Hedged Bold Sandwich

A hedge, followed by a strong claim, followed by another hedge. This is the AI equivalent of throat-clearing.

```text
Bad:  "While there's no single solution, the reality is that AI tools
       are fundamentally reshaping development. Of course, results
       may vary depending on context."

Good: "AI tools change how development works. The degree depends on
       the team and the problem."
```

Pick a position and state it. If you need to qualify, qualify with specifics, not vagueness.

### Em Dashes for Drama

Using em dashes to create artificial pause or emphasis, especially combined with contrastive reframes.

```text
Bad:  "The bottleneck hasn't moved -- it's shifted entirely."
Bad:  "This approach doesn't just work -- it scales."
```

Em dashes are fine for parenthetical asides. They are not a substitute for substance. (Note: this project uses `--` instead of the `—` character.)

### "Let's Be Honest" and Similar Openers

Phrases that signal insight is coming without delivering any: "Here's the thing," "Let's be real," "The truth is," "At the end of the day."

```text
Bad:  "Here's the thing: most developers don't read documentation."
Good: "Most developers don't read documentation."
```

The sentence after these openers is usually the one you should lead with.

---

## Structural Rules

### Say Things Once

If you've made a point, move on. Don't rephrase it from three angles. One clear statement beats three fuzzy ones.

### Be Specific or Be Quiet

Vague claims are content filler. If you can't name a concrete example, measurement, or mechanism, the claim probably doesn't belong.

```text
Bad:  "dramatically improves your workflow"
Good: "saves roughly 2,000 tokens per message by caching the system
       prompt after the first turn"
```

### Show, Don't Describe

Code examples, command output, and diagrams convey more than prose descriptions of the same thing. When possible, demonstrate rather than explain.

```text
Bad:  "Claude Code provides a sophisticated mechanism for persistent
       configuration that allows developers to specify rules and
       preferences that carry across sessions."

Good: "CLAUDE.md files are loaded into every message. Put your coding
       standards and project conventions there."
```

### No Relative Timeline Phrasing

Don't describe features using relative product-timeline phrasing like "new," "recently added," "improved," or "legacy." Content should describe things as they are, not relative to some past state. A reader in six months shouldn't have to wonder what "the new approach" replaced.

The words themselves are fine in non-relative contexts ("start a new session", "create a new file"). The rule targets phrasing that positions a feature on a product timeline ("the new context management system", "the legacy API").

### No Internal Implementation Names

Don't leak internal type names (private classes, structs, internal modules) into user-facing prose. Documented configuration and interface names (env vars, flags, settings keys) are fine when they're the subject of the section.

```text
Bad:  "the ZodValidator processes input schemas"
Good: "input validation checks arguments against the tool's schema"

Fine: "set MAX_THINKING_TOKENS to control the thinking budget"
      (this is a documented, user-facing setting)
```

---

## Formatting

- Use `--` for dashes, not `—` (em dash character)
- Use fenced code blocks with language identifiers for all code and examples (use `text` for plain-text examples, `bash` for commands, etc.)
- Use ASCII diagrams over Mermaid for simple structures
- Keep tables for genuinely tabular data, not for lists disguised as tables
- Headers should describe content, not tease it ("How Context Windows Work" not "The Surprising Truth About Context")

---

## Punctuation and Grammar

- Oxford comma: yes
- Title case for headers: "How Context Windows Work" not "How context windows work"
- One space after periods
- Contractions are fine in all content types

---

## What Good Wiki Content Looks Like

Good content in this wiki:

- Teaches the reader something specific they can apply immediately
- Contains at least one concrete example (code, config, command)
- Can be scanned -- headers, code blocks, and lists break up the prose
- Doesn't repeat what's in another page -- link to it instead
- Credits sources when drawing on someone else's ideas or work
