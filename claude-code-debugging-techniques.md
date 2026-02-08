# Debugging Techniques: Systematic Troubleshooting with Claude Code

## Executive Summary

Debugging with Claude Code works best when treated as a systematic investigation, not a guessing game. The core principle: understand the root cause before attempting a fix. Claude performs dramatically better at debugging when given the actual error, a way to reproduce it, and a way to verify the fix. Ad-hoc "try this, try that" approaches waste context and produce fragile patches.

| Technique                     | When to Use                                  | Key Benefit                            |
| ----------------------------- | -------------------------------------------- | -------------------------------------- |
| **Share the actual error**    | Always, as the first step                    | Eliminates guessing                    |
| **Reproduce first**           | Before attempting any fix                    | Confirms the problem, verifies the fix |
| **Trace backward**            | When the error location isn't the root cause | Finds where the problem originates     |
| **Git history investigation** | When it "used to work"                       | Finds the breaking change              |
| **Hypothesis testing**        | Complex bugs with multiple possible causes   | Systematic narrowing to root cause     |
| **Subagent investigation**    | Large codebase, many files to search         | Keeps main context clean for the fix   |
| **Minimal reproduction**      | Intermittent or environment-specific bugs    | Isolates the exact conditions          |

---

## Table of Contents

- [The Debugging Framework](#the-debugging-framework)
  - [Phase 1: Understand the Symptom](#phase-1-understand-the-symptom)
  - [Phase 2: Reproduce](#phase-2-reproduce)
  - [Phase 3: Investigate Root Cause](#phase-3-investigate-root-cause)
  - [Phase 4: Fix and Verify](#phase-4-fix-and-verify)
- [Sharing Errors Effectively](#sharing-errors-effectively)
  - [What to Include](#what-to-include)
  - [What Not to Do](#what-not-to-do)
- [Tracing Techniques](#tracing-techniques)
  - [Trace Backward from the Error](#trace-backward-from-the-error)
  - [Git History Investigation](#git-history-investigation)
  - [Log Analysis](#log-analysis)
  - [Reasoning Through Architecture](#reasoning-through-architecture)
- [Common Bug Categories](#common-bug-categories)
  - [Test Failures](#test-failures)
  - [Runtime Errors](#runtime-errors)
  - [It Worked Before](#it-worked-before)
  - [Intermittent Failures](#intermittent-failures)
  - [Build and Configuration Errors](#build-and-configuration-errors)
- [Using Subagents for Debugging](#using-subagents-for-debugging)
- [Debugging Across Context Windows](#debugging-across-context-windows)
- [Anti-Patterns](#anti-patterns)
- [Best Practices](#best-practices)
- [References](#references)

---

## The Debugging Framework

Every debugging session should follow four phases. Skipping to phase 4 (the fix) without understanding the root cause produces patches that mask problems rather than solve them.

```
Phase 1: UNDERSTAND THE SYMPTOM
  What is happening? What should be happening?
       │
Phase 2: REPRODUCE
  Can you make it happen reliably?
       │
Phase 3: INVESTIGATE ROOT CAUSE
  Why is it happening? Where does the problem originate?
       │
Phase 4: FIX AND VERIFY
  Fix the root cause, verify with tests.
```

### Phase 1: Understand the Symptom

Before Claude can help, it needs to understand what's wrong. The more precise your description, the faster the investigation.

```
Vague (Claude has to guess):
  "the login is broken"

Precise (Claude knows what to investigate):
  "login returns 401 after session timeout. the token
   refresh endpoint returns 200 but the new token isn't
   being stored in the cookie. here's the network trace:
   [paste]"
```

Key questions to answer:

- **What is the actual behavior?** -- Error message, status code, incorrect output
- **What is the expected behavior?** -- What should happen instead
- **When did it start?** -- After a deploy? A dependency update? A config change?
- **Who does it affect?** -- All users? Specific conditions? Specific environments?

### Phase 2: Reproduce

A bug you can't reproduce is a bug you can't verify you've fixed.

```
"the test fails with 'expected 200 but got 401'.
 reproduce it by running: go test ./internal/auth/..."
```

For bugs that are hard to reproduce, ask Claude to write a minimal reproduction:

```
"users report that checkout fails intermittently.
 write a test that simulates concurrent checkout
 requests to reproduce the race condition"
```

If the bug is environment-specific:

```
"this only fails in CI. here's the CI log output:
 [paste]. the local environment uses Go 1.22 but
 CI uses Go 1.21. check if any 1.22 features are
 being used"
```

### Phase 3: Investigate Root Cause

This is where most debugging time is spent -- and where Claude provides the most value. The key is systematic investigation, not random attempts.

**The backward trace:**

```
Symptom:    401 response on login
    ↑
Immediate:  token validation fails
    ↑
Deeper:     token has wrong expiry timestamp
    ↑
Root cause: clock skew between auth service and token issuer
```

Claude is good at tracing backward through code if you point it to the right starting location:

```
"the error is in auth.go:47 where validateToken()
 returns false. trace backward to find where the
 token gets its expiry timestamp and why it might
 be wrong"
```

### Phase 4: Fix and Verify

Only after understanding the root cause should Claude attempt a fix. And every fix needs verification:

```
"fix the clock skew issue by using the token
 issuer's timestamp instead of the local clock.
 write a test that reproduces the original bug
 (wrong expiry), then verify it passes with the fix"
```

The pattern: **write a failing test that captures the bug, then fix the code to make it pass.** This ensures:

- You're fixing the right problem
- The fix actually works
- The bug can't silently regress

---

## Sharing Errors Effectively

### What to Include

The single most useful thing you can give Claude is the actual error output. Not a paraphrase -- the real text.

| What to Share                 | Example                                                     |
| ----------------------------- | ----------------------------------------------------------- |
| **Full error message**        | Paste the complete error, not "it says something about nil" |
| **Stack trace**               | The full trace, not just the top line                       |
| **Command that triggered it** | `go test ./internal/auth/...` not "the tests fail"          |
| **Relevant log output**       | The lines around the error, not the entire 10,000-line log  |
| **Environment context**       | Go version, OS, CI vs local, relevant config                |
| **What changed recently**     | "This started after we upgraded the jwt library"            |

### What Not to Do

```
Bad:  "the test still fails, try something else"
      (Claude doesn't know what error to address)

Good: "the test fails with: 'panic: runtime error:
       invalid memory address or nil pointer
       dereference' at auth.go:47"
      (Claude knows exactly what's wrong and where)
```

```
Bad:  "it's broken again"
      (no information to work with)

Good: "same nil pointer, but now at auth.go:52.
       looks like the fix moved the problem
       downstream -- user.Token is nil when the
       account has never logged in before"
      (Claude understands the fix was incomplete)
```

Paraphrasing error messages loses critical information. The exact text often contains the solution -- line numbers, variable names, expected vs actual values.

---

## Tracing Techniques

### Trace Backward from the Error

The error location is rarely the root cause. Claude is effective at tracing backward through call chains:

```
"the panic is at handler.go:89 where it calls
 user.GetProfile(). trace backward to find how
 'user' gets its value -- it might be nil when
 the session lookup fails silently"
```

Ask Claude to map the data flow:

```
"trace the request token from the HTTP header
 through the middleware chain to the handler.
 find where validation happens and what happens
 when validation fails"
```

### Git History Investigation

When something used to work, git history tells you what changed:

```
"this worked last week. look through the git log
 for changes to the auth module since Monday"
```

For finding the exact breaking commit:

```
"use git bisect to find which commit broke the
 login test. the test is:
 go test -run TestLoginWithExpiredToken ./internal/auth/"
```

Claude can also investigate git blame for context:

```
"git blame auth.go around line 47. who changed
 this last and what was the commit message?"
```

### Log Analysis

For production issues where you have logs but can't easily reproduce:

```
"here's the error log from production: [paste].
 identify the pattern -- what requests trigger
 this error? is there a common thread (same user,
 same endpoint, same time of day)?"
```

Pipe logs directly to Claude for analysis:

```bash
cat error.log | claude -p "analyze these errors.
group by root cause and rank by frequency"
```

### Reasoning Through Architecture

For complex bugs, ask Claude to reason about what could go wrong:

```
"think through what happens if two users trigger
 checkout simultaneously. where could the race
 condition occur in our current checkout flow?"
```

```
"what could cause pagination to silently drop
 results? consider the database query, the
 cursor handling, and the response serialization"
```

This generates focused investigation targets rather than blind searching.

---

## Common Bug Categories

### Test Failures

```
Step 1: Read the full error output
  "run go test ./internal/auth/ -v and show me
   the complete output"

Step 2: Identify which assertion failed
  "the test expects 200 but gets 401. what's the
   auth middleware doing to this test request?"

Step 3: Trace the unexpected value
  "the token is being rejected. check what token
   the test fixture provides and whether it matches
   what the validator expects"

Step 4: Fix at the source
  "the test fixture uses an expired token. either
   fix the fixture or adjust the test to use a
   valid token -- which is correct for this test case?"
```

### Runtime Errors

```
Step 1: Get the full stack trace
  "paste the complete panic/error output"

Step 2: Identify the throwing line
  "the nil pointer is at handler.go:89 --
   user.GetProfile() on a nil user"

Step 3: Trace backward
  "how does 'user' get set? trace from the session
   lookup through to the handler. what happens when
   the session doesn't exist?"

Step 4: Fix with validation at the source
  "the session lookup returns nil without error
   when the session doesn't exist. add a nil check
   after lookup and return 401, not a panic"
```

### It Worked Before

```
Step 1: Find when it broke
  "this login test passed in CI last Wednesday.
   look at commits to the auth package since then"

Step 2: Identify the breaking change
  "commit abc123 changed the token validation to
   use a stricter time check. that's probably why
   tests with expired tokens now fail differently"

Step 3: Understand the intent
  "was the stricter validation intentional? read the
   commit message and PR description"

Step 4: Fix appropriately
  "the stricter validation was intentional for
   security. update the test fixtures to use valid
   tokens instead of reverting the validation change"
```

For harder cases, git bisect automates the search:

```
"use git bisect with the login test to find which
 exact commit broke it. mark the last known good
 commit as HEAD~20 and the bad commit as HEAD"
```

### Intermittent Failures

These are the hardest bugs. Common causes:

- **Race conditions** -- Concurrent access to shared state
- **Timing dependencies** -- Assumptions about execution order
- **Resource exhaustion** -- Connection pools, file handles, memory
- **External dependencies** -- Network timeouts, service degradation

```
"this test fails about 1 in 10 runs. look for:
 - shared mutable state accessed without locks
 - goroutines that assume execution order
 - timeouts that might be too tight
 - test cleanup that runs before assertions"
```

For race conditions specifically:

```
"run the tests with the Go race detector:
 go test -race ./internal/checkout/
 and show me any race conditions it finds"
```

### Build and Configuration Errors

```
Step 1: Share the exact build output
  "here's the build error: [paste]"

Step 2: Let Claude diagnose
  "fix the build error and verify it compiles.
   address the root cause, don't suppress the error"

Step 3: Check for cascading effects
  "the fix compiles. run the tests to make sure
   nothing else broke"
```

For dependency issues:

```
"the build fails with a version conflict between
 library X and Y. read go.mod and figure out which
 version constraints are incompatible"
```

---

## Using Subagents for Debugging

When debugging requires extensive codebase exploration, subagents keep your main context clean:

```
"use a subagent to investigate all the places
 where UserSession is created, modified, or
 invalidated. I need to understand the session
 lifecycle to debug the timeout issue"
```

The subagent reads many files and reports back a summary. Your main context stays focused on the actual fix.

**When to use subagents for debugging:**

- Searching across many files for a pattern
- Understanding a subsystem you're unfamiliar with
- Tracing dependencies across modules
- Checking if a bug exists elsewhere in the codebase

**When to debug directly:**

- You know the exact file and location
- The bug is in a single function
- You already understand the subsystem

---

## Debugging Across Context Windows

Long debugging sessions fill context with failed attempts and file reads. Strategies for managing this:

**Clear between attempts:**

If you've been debugging for a while and have accumulated several failed approaches, `/clear` and start fresh with what you've learned:

```
After failed attempts, start clean:
  "the nil pointer in auth.go:47 is because
   sessionLookup returns nil when the session
   expired. I tried adding a nil check but the
   real issue is that the caller doesn't handle
   the expired case. fix the caller to check for
   expired sessions before calling GetProfile()"
```

The clean prompt incorporates lessons from your investigation without the noise of failed attempts.

**Save debugging progress:**

For multi-session debugging, save what you've found:

```
"save your findings about the session timeout bug
 to progress.md: what we know, what we've tried,
 what the likely root cause is, and what to try next"
```

**Use git commits as checkpoints:**

```
"commit the diagnostic logging we added so we don't
 lose it. message: 'add debug logging for session
 timeout investigation'"
```

Even if the logging gets removed later, the commit preserves the investigation state.

---

## Anti-Patterns

### Symptom Patching

```
Bad:  "add a nil check to stop the panic"
      (hides the bug, doesn't fix it)

Good: "why is the value nil? trace backward to find
       where the expected value should have been set"
      (finds the root cause)
```

A nil check at the crash site stops the panic but doesn't fix the underlying problem. The nil value propagates to other code paths, causing subtler bugs.

### Shotgun Debugging

```
Bad:  "try adding error handling here, and also
       here, and also change this timeout, and
       also try a different library version"
      (multiple changes, can't tell which one helped)

Good: "let's test one hypothesis: is the timeout
       too short? change only the timeout to 30s
       and run the test again"
      (one change, clear signal)
```

Multiple simultaneous changes make it impossible to know what fixed the problem -- or what introduced new ones.

### Ignoring Error Messages

```
Bad:  "the test fails, make it pass"
      (Claude doesn't know what the error is)

Good: "the test fails with 'connection refused on
       localhost:5432'. the database container probably
       isn't running. check the test setup"
      (the error message contains the diagnosis)
```

Error messages are diagnostic data. Read them carefully before asking for help.

### Fixing the Test Instead of the Code

```
Bad:  "the test expects 200 but gets 401, update
       the test to expect 401"
      (the test was correct, the code is broken)

Good: "the test expects 200 but gets 401. is the
       test wrong or is the code wrong? check what
       this endpoint should return for an authenticated
       user"
      (figure out which side is correct first)
```

Before changing a test, verify that the test is wrong and not the code. Tests that used to pass probably represent correct behavior.

### Accumulating Failed Attempts

```
Bad:  Attempt 1 failed → "try this instead" →
      Attempt 2 failed → "what about this?" →
      Attempt 3 failed → "maybe this?" →
      Context is full of noise, Claude is confused

Good: After 2 failed attempts →
      /clear →
      "I've been debugging the session timeout. Here's
       what I know: [findings]. The nil pointer at
       auth.go:47 happens because [reason]. Fix it by
       [approach based on what I learned]."
```

After two failed fix attempts, the context is polluted. Start fresh with a better prompt that incorporates your investigation findings.

---

## Best Practices

1. **Share the actual error** -- Paste the real error text, don't paraphrase. Line numbers, variable names, and stack traces are diagnostic gold.

2. **Reproduce before fixing** -- If you can't reproduce it, you can't verify the fix. Ask Claude to write a reproduction test.

3. **Understand before fixing** -- Trace to the root cause before writing any fix. Symptom patches create new bugs.

4. **One change at a time** -- Test each hypothesis individually. Multiple simultaneous changes hide the real cause.

5. **Write a failing test** -- Capture the bug as a test before fixing it. The test both verifies the fix and prevents regression.

6. **Use git history** -- When it "used to work," git log and git bisect find the breaking change faster than speculation.

7. **Delegate investigation to subagents** -- Keep your main context clean for the fix by having subagents do the exploration.

8. **Clear context after failed attempts** -- Two failed fixes means the context is noisy. Start fresh with what you've learned.

9. **Read the error message** -- It sounds obvious, but most debugging starts with actually reading what the error says. The answer is often in the message itself.

10. **Don't fix the test** -- When a test fails, verify the test is correct before changing it. Tests that used to pass usually represent correct behavior.

---

## References

- [Common Workflows: Fix Bugs (Claude Code Docs)](https://code.claude.com/docs/en/common-workflows) -- Official debugging workflow recipes
- [Best Practices (Claude Code Docs)](https://code.claude.com/docs/en/best-practices) -- Verification-driven development patterns
- [Troubleshooting (Claude Code Docs)](https://code.claude.com/docs/en/troubleshooting) -- Diagnosing Claude Code itself
- [Workflow Patterns Article](claude-code-workflow-patterns.md) -- Fix with verification workflow
- [Effective Prompting Article](claude-code-effective-prompting.md) -- How to share errors and context effectively
