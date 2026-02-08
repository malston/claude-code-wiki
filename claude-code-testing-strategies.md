# Testing Strategies: TDD Patterns and Test Automation with Claude Code

## Executive Summary

Testing is the highest-leverage tool for getting good results from Claude Code. Tests give Claude a concrete feedback loop -- write code, run tests, see failures, fix. Without tests, Claude produces code that looks right but may not work. With tests, Claude iterates until the output actually passes. This article covers how to structure test-driven development with Claude Code, avoid common testing pitfalls, and automate testing workflows.

| Strategy                        | When to Use                           | Key Benefit                                    |
| ------------------------------- | ------------------------------------- | ---------------------------------------------- |
| **Test-first (TDD)**            | New features, bug fixes               | Tests define requirements, Claude has a target |
| **Test-after**                  | Exploratory work, prototyping         | Locks down behavior once approach is settled   |
| **Existing test suite**         | Refactoring, bug fixes in tested code | Safety net already exists, just run it         |
| **Separate writer/implementer** | High-quality features, complex logic  | Context isolation prevents bias                |
| **Hooks for auto-testing**      | All development                       | Immediate feedback after every edit            |
| **Headless test runner**        | CI/CD, batch validation               | Automated verification at scale                |

---

## Table of Contents

- [Why Tests Matter More with AI](#why-tests-matter-more-with-ai)
- [Test-Driven Development with Claude Code](#test-driven-development-with-claude-code)
  - [The Red-Green-Refactor Cycle](#the-red-green-refactor-cycle)
  - [Prompting for Tests](#prompting-for-tests)
  - [Committing the Cycle](#committing-the-cycle)
- [Context Isolation: The Writer/Implementer Split](#context-isolation)
  - [Why Isolation Matters](#why-isolation-matters)
  - [Patterns for Isolation](#patterns-for-isolation)
- [What Makes a Good Test with Claude Code](#what-makes-a-good-test-with-claude-code)
  - [Match Existing Patterns](#match-existing-patterns)
  - [Avoid Mocks Where Possible](#avoid-mocks-where-possible)
  - [Test Behavior, Not Implementation](#test-behavior-not-implementation)
  - [Edge Cases Claude Misses](#edge-cases-claude-misses)
- [Tests as Durable Requirements](#tests-as-durable-requirements)
  - [Surviving Context Windows](#surviving-context-windows)
  - [Multi-Session TDD](#multi-session-tdd)
  - [Structured Test Tracking](#structured-test-tracking)
- [Automating Test Workflows](#automating-test-workflows)
  - [Hooks for Auto-Testing](#hooks-for-auto-testing)
  - [CLAUDE.md Testing Rules](#claudemd-testing-rules)
  - [Headless Testing in CI](#headless-testing-in-ci)
- [Test Coverage Strategies](#test-coverage-strategies)
  - [Finding Untested Code](#finding-untested-code)
  - [Incremental Coverage Improvement](#incremental-coverage-improvement)
  - [When Coverage Tools Help](#when-coverage-tools-help)
- [Common Testing Anti-Patterns](#common-testing-anti-patterns)
- [Best Practices](#best-practices)
- [References](#references)

---

## Why Tests Matter More with AI

Claude Code performs dramatically better when it can verify its own work. This isn't just a nice-to-have -- it's the single highest-leverage pattern for improving Claude's output quality.

```
Without tests:
  You → "implement rate limiting"
  Claude → writes code that looks correct
  You → manually test → find edge case
  You → "fix this edge case"
  Claude → patches it
  You → manually test → find another issue
  ... repeat

With tests:
  You → "write tests for rate limiting, then implement"
  Claude → writes tests → writes code → runs tests →
           sees failures → fixes → runs again → all pass
  You → review the final result
```

The difference: without tests, you are the feedback loop. With tests, Claude has its own feedback loop and iterates until the code actually works. You review the result instead of being in the debugging loop.

This applies to all types of work -- new features, bug fixes, refactoring, and migrations. If you can express the expected behavior as a test, Claude's success rate goes up significantly.

---

## Test-Driven Development with Claude Code

### The Red-Green-Refactor Cycle

TDD with Claude Code follows the standard cycle, adapted for agentic development:

```
RED: Write failing tests
  Claude writes tests for functionality that
  doesn't exist yet. Tests should fail.
       │
GREEN: Implement to pass
  Claude writes the minimum code to make
  all tests pass. Nothing more.
       │
REFACTOR: Clean up with safety
  Claude improves the code while keeping
  all tests passing.
       │
  Commit and move to the next feature
```

The practical workflow:

```
Step 1: Write tests first
  "write tests for a rate limiter that allows 5
   requests per minute per IP address. cover:
   - allowing requests under the limit
   - rejecting requests over the limit (429 status)
   - resetting the counter after the time window
   - handling multiple IPs independently
   do NOT write any implementation yet"

Step 2: Confirm tests fail
  "run the tests to confirm they fail"

Step 3: Commit the failing tests
  "commit the tests with message: 'add rate limiter
   tests (red phase)'"

Step 4: Implement
  "implement the rate limiter with the sole goal
   of making all committed tests pass. run the tests
   after each change"

Step 5: Commit the passing implementation
  "commit the implementation"

Step 6: Refactor (optional)
  "refactor the rate limiter for clarity. keep all
   tests passing"
```

### Prompting for Tests

Be explicit that you're doing TDD. This prevents Claude from writing mock implementations or stubbing out code that doesn't exist yet.

```
Explicit TDD prompt:
  "I'm doing TDD. Write tests FIRST for the feature
   described below. Do NOT create any implementation
   code, mocks, or stubs. The tests should fail when
   run against the current codebase."

Specify the framework:
  "write tests using go test with the testify assertion
   library, matching the patterns in existing test files"

Specify what to test:
  "write a test for the ParseConfig function covering:
   valid YAML input, missing required fields, invalid
   port numbers, and an empty file"

Specify what NOT to do:
  "do not use mocks for the database. use testcontainers
   for integration tests, matching the pattern in
   user_test.go"
```

The more specific your test requirements, the better the tests. Vague requests like "write some tests" produce generic tests. Specific requests produce tests that actually verify the behavior you care about.

### Committing the Cycle

Committing at each phase creates checkpoints:

```
Commit 1: "add rate limiter tests (red)"
  → Tests exist but fail. Requirements are captured.

Commit 2: "implement rate limiter (green)"
  → Tests pass. Minimum viable implementation.

Commit 3: "refactor rate limiter for clarity"
  → Code is clean. Tests still pass.
```

This serves two purposes:

1. Each phase is reversible -- you can rewind to any checkpoint
2. The test commit is a standalone artifact that survives context transitions

---

## Context Isolation

### Why Isolation Matters

When Claude writes both tests and implementation in the same context, there's a subtle bias: Claude designs the tests around the implementation it's already planning. The tests pass easily because they test exactly what Claude intended to build, not necessarily what you need.

```
Same context (biased):
  Claude thinks about implementation → writes tests
  that match its planned approach → writes code that
  passes easily → edge cases get missed because the
  tests and code share assumptions

Separate contexts (unbiased):
  Session A writes tests based on requirements →
  Session B writes code to pass tests → mismatch
  between assumptions gets caught
```

### Patterns for Isolation

**Pattern 1: Two sessions**

```
Session A (test writer):
  "write comprehensive tests for user notification
   preferences. cover opt-in, opt-out, per-channel
   preferences, and bulk updates"
       │
  → Tests committed to git
       │
Session B (implementer):
  "run the tests in notification_test.go. implement
   whatever is needed to make them all pass"
```

**Pattern 2: Subagent writer**

```
"use a subagent to write tests for the checkout flow.
 the subagent should cover: adding items, removing
 items, applying discount codes, and calculating tax.
 once the tests are committed, I'll implement the code
 in the main session"
```

**Pattern 3: Test spec, then implement**

```
Step 1: Write a test specification
  "write a test plan for the search feature in
   TESTPLAN.md. list every test case with inputs
   and expected outputs, but don't write code yet"
       │
Step 2: /clear
       │
Step 3: Generate tests from the spec
  "read TESTPLAN.md and generate test code for
   every case listed. use the testing patterns
   from the existing test files"
       │
Step 4: Implement
  "make all tests pass"
```

The `/clear` between steps 1 and 3 breaks the context connection, reducing bias.

---

## What Makes a Good Test with Claude Code

### Match Existing Patterns

Claude examines existing test files to match style, frameworks, and assertion patterns. Point it to good examples:

```
"look at how tests are structured in user_test.go.
 follow the same patterns for the new auth tests:
 table-driven tests, testify assertions, test
 fixtures in testdata/"
```

If your codebase has inconsistent test patterns, specify which pattern to follow. Otherwise, Claude picks whatever pattern it finds first, which may not be the one you want.

### Avoid Mocks Where Possible

Mocks test that you called the mock correctly, not that the code works. For integration points, prefer real dependencies when feasible:

```
Good: "use testcontainers for database tests, matching
      the pattern in user_test.go"

Good: "use httptest.NewServer to create a real HTTP
      server for API client tests"

Avoid: "mock the database interface and verify the
       query was called with the right parameters"
       (tests the mock, not the code)
```

There are valid uses for mocks -- external services you can't control, slow dependencies in unit tests, and interfaces you want to test in isolation. But when you have a choice, real dependencies catch more bugs.

### Test Behavior, Not Implementation

Tests that verify behavior survive refactoring. Tests that verify implementation break whenever the code changes:

```
Behavior test (durable):
  "test that a rate-limited request returns 429
   with a Retry-After header"

Implementation test (fragile):
  "test that the rate limiter increments the Redis
   counter and checks it against the threshold"
```

The behavior test works regardless of whether you use Redis, an in-memory counter, or a sliding window algorithm. The implementation test breaks if you change anything about the internals.

Tell Claude to focus on behavior:

```
"write tests that verify the external behavior of the
 API -- inputs and outputs. don't test internal
 implementation details"
```

### Edge Cases Claude Misses

Claude is good at happy-path tests but sometimes misses edge cases. Prompt for them explicitly:

```
"after writing the main tests, add edge case tests for:
 - empty input
 - nil/null values
 - boundary values (0, max int, empty string)
 - concurrent access
 - error conditions (network timeout, permission denied)
 - Unicode and special characters in string inputs"
```

You can also ask Claude to identify edge cases it might have missed:

```
"review the tests you just wrote. what edge cases
 are missing? add them"
```

---

## Tests as Durable Requirements

### Surviving Context Windows

Tests are the most reliable way to carry requirements across context transitions. Unlike conversation history (which gets compacted) or instructions (which get summarized), test files persist on disk exactly as written.

```
Context window fills up → compaction happens →
  conversation summary may lose details →
  BUT test files on disk are unchanged

Session ends → new session starts →
  conversation history is gone →
  BUT test files on disk are unchanged
```

This is why committing tests before implementation matters -- the tests survive any context event.

### Multi-Session TDD

For features that span multiple sessions:

```
Session 1: Write all the tests
  "write comprehensive tests for the notification
   system. commit them when done."
  → Tests committed to git

Session 2 (next day, fresh context):
  "run the tests in internal/notification/. implement
   whatever is needed to make them pass."
  → Claude discovers requirements from the tests

Session 3 (if needed):
  "continue making the notification tests pass.
   check which tests still fail and fix them."
  → Claude picks up where it left off
```

Each session starts fresh but the tests provide continuity.

### Structured Test Tracking

For large features with many test cases, track progress in a structured format:

```json
{
  "feature": "notification-system",
  "tests": [
    { "name": "create_notification", "status": "passing" },
    { "name": "email_delivery", "status": "passing" },
    { "name": "preference_opt_out", "status": "failing" },
    { "name": "bulk_notifications", "status": "not_started" },
    { "name": "rate_limiting", "status": "not_started" }
  ],
  "passing": 2,
  "failing": 1,
  "not_started": 2
}
```

Claude can read and update this file as it works:

```
"read tests.json, implement the next failing test
 case, run the tests, and update the status in
 tests.json when it passes"
```

---

## Automating Test Workflows

### Hooks for Auto-Testing

Hooks run scripts automatically at specific points in Claude's workflow. A PostToolUse hook can run tests after every file edit:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "go test ./... 2>&1 | tail -20",
        "timeout": 30000
      }
    ]
  }
}
```

This gives Claude immediate feedback after every edit -- it sees test results without needing to explicitly run them.

For linting alongside tests:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "command": "golangci-lint run --new-from-rev=HEAD 2>&1 | head -20",
        "timeout": 15000
      }
    ]
  }
}
```

### CLAUDE.md Testing Rules

Put your test conventions in CLAUDE.md so Claude follows them every session:

```markdown
## Testing

- Run tests: go test ./...
- Run single test: go test -run TestName ./package/
- Integration tests: go test -tags=integration ./...
- Always run relevant tests after making changes
- Use testcontainers for database integration tests
- Use table-driven tests matching existing patterns
- Never delete a failing test -- fix the code or discuss
```

Include the specific test commands so Claude doesn't have to guess. Different projects use different test runners, flags, and conventions.

### Headless Testing in CI

Run Claude as a test quality checker in CI:

```bash
# Check test coverage for changed files
claude -p "analyze test coverage for files changed
in this PR. identify functions without tests and
suggest what test cases are needed" --output-format text

# Validate test quality
claude -p "review the tests in this PR. check for:
mock-heavy tests that don't test real behavior,
missing edge cases, and tests that would pass
even if the code was broken" --output-format text
```

For test generation in CI:

```bash
# Generate tests for untested code in the PR
claude -p "find functions in the changed files
that lack tests. generate tests following the
patterns in existing test files. output only
the test code" --output-format text > new_tests.go
```

---

## Test Coverage Strategies

### Finding Untested Code

Ask Claude to identify gaps:

```
"find functions in the auth package that don't
 have corresponding tests. list them with a brief
 description of what each function does"
```

Or use coverage tools:

```
"run go test -coverprofile=coverage.out ./... and
 then go tool cover -func=coverage.out. show me
 functions with less than 50% coverage"
```

### Incremental Coverage Improvement

Don't try to go from 20% to 90% coverage in one session. Target the highest-value gaps first:

```
Step 1: Identify critical untested paths
  "which functions in the checkout package handle
   money or user data but don't have tests?"

Step 2: Write tests for the highest-risk code first
  "write tests for calculateTotal and processPayment.
   these handle money and need thorough testing"

Step 3: Run and verify
  "run the new tests and fix any failures in the
   tests (not the code -- the code is working in
   production)"
```

### When Coverage Tools Help

Coverage tools are useful for finding gaps but not for measuring quality. 100% coverage with bad tests is worse than 60% coverage with good tests.

```
Coverage tells you:
  "this function has no tests at all"  ← useful
  "this function has 100% line coverage" ← doesn't
     mean the tests are good

Better quality signal:
  "do the tests verify the actual behavior?"
  "would the tests catch a real bug?"
  "do the tests cover edge cases?"
```

Ask Claude to evaluate test quality, not just coverage:

```
"review the tests for the auth package. for each
 test, evaluate: does it test real behavior or just
 implementation details? would it catch a real bug?
 what edge cases are missing?"
```

---

## Common Testing Anti-Patterns

### Testing Mocked Behavior

```
Bad:  mock.Expect("GetUser").Return(user)
      service.Process()
      mock.AssertCalled("GetUser")
      (tests that the mock was called, not that the code works)

Good: db := testcontainer.StartPostgres()
      db.Insert(testUser)
      result := service.Process()
      assert.Equal(expectedResult, result)
      (tests actual behavior with real dependencies)
```

### Deleting Failing Tests

```
Bad:  "this test keeps failing, delete it"
      (the test was probably right -- the code is broken)

Good: "this test is failing. is the test wrong or is
       the code wrong? investigate before changing either"
```

Tests that used to pass represent correct behavior. Deleting them loses that knowledge.

### Writing Tests After Implementation in the Same Session

```
Bad:  "implement the feature" → "now write tests"
      (tests are biased toward what was just implemented)

Better: "write tests first" → "now implement"
      (tests define requirements, implementation follows)

Best: Session A writes tests → Session B implements
      (complete context isolation)
```

### Hard-Coding Test Values

```
Bad:  "Claude hard-coded the expected API response in
       the test -- it matches the current output exactly
       but doesn't test the logic"

Good: "write tests that verify the structure and
       constraints of the response, not the exact values.
       a valid response has a non-empty 'id' field, a
       'created_at' timestamp in the past, and a 'status'
       that is one of: active, pending, disabled"
```

Tell Claude to test properties and constraints rather than exact values when the values are dynamic or generated.

### Ignoring Test Output

```
Bad:  "the tests pass" (didn't actually check)

Good: "run the tests with -v and show me the output.
       I want to see what's being tested"
```

Test output often reveals that tests pass for the wrong reasons -- skipped tests, empty test bodies, or tests that assert nothing. Use verbose output to verify tests are actually testing something.

---

## Best Practices

1. **Write tests first** -- Tests define requirements. Let Claude implement against a concrete target rather than vague instructions.

2. **Be specific about what to test** -- "Write tests for the rate limiter" is worse than "test allowing requests under the limit, rejecting over the limit, and resetting after the window."

3. **Specify the framework and patterns** -- "Use testify assertions and table-driven tests matching user_test.go" prevents Claude from guessing.

4. **Commit tests before implementation** -- The test commit is a checkpoint that survives context transitions and session boundaries.

5. **Avoid mocks for things you can test directly** -- Real dependencies catch more bugs. Use testcontainers, httptest servers, and in-memory databases when feasible.

6. **Test behavior, not implementation** -- Tests that verify inputs and outputs survive refactoring. Tests that verify internal calls break with every change.

7. **Use context isolation for important features** -- Write tests in one session, implement in another. This prevents bias.

8. **Ask Claude to find edge cases** -- After writing main tests, explicitly ask for edge cases: empty input, nil values, boundaries, concurrency, error conditions.

9. **Never delete failing tests** -- Investigate whether the test or the code is wrong. Tests that used to pass usually represent correct behavior.

10. **Automate with hooks** -- PostToolUse hooks that run tests after every edit give Claude immediate feedback without explicit prompting.

---

## References

- [Best Practices: Verification (Claude Code Docs)](https://code.claude.com/docs/en/best-practices) -- Official guide on giving Claude verification criteria
- [Common Workflows: Testing (Claude Code Docs)](https://code.claude.com/docs/en/common-workflows) -- Testing workflow recipes
- [TDD with Claude Code (Steve Kinney)](https://stevekinney.com/courses/ai-development/test-driven-development-with-claude) -- Practical TDD patterns
- [Hooks Guide (Claude Code Docs)](https://code.claude.com/docs/en/hooks-guide) -- Auto-testing with PostToolUse hooks
- [Workflow Patterns Article](claude-code-workflow-patterns.md) -- TDD and verification workflows
- [Debugging Techniques Article](claude-code-debugging-techniques.md) -- Writing tests to reproduce bugs
- [Effective Prompting Article](claude-code-effective-prompting.md) -- Tests as durable requirements across context windows
