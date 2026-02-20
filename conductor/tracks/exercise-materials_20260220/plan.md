# Implementation Plan: Training Exercise Materials

**Track ID:** exercise-materials_20260220
**Spec:** [spec.md](./spec.md)
**Created:** 2026-02-20
**Status:** [ ] Not Started

## Overview

Create three standalone exercise repos (one per persona), each containing realistic project scaffolding, intentional bugs, incomplete features, and scenario descriptions that map to the training path exercises. The developer repo uses Java/Spring + TypeScript/Next.js. The platform engineer repo uses Terraform. The PM repo has a mock product backlog plus a development codebase for PR practice.

## Phase 1: Repository Foundation

Create all three repos with basic structure, README, CLAUDE.md, and git initialization.

### Tasks

- [ ] Task 1.1: Create `~/code/training-dev-exercises/` -- Java/Spring + Next.js project skeleton with CLAUDE.md, README explaining the repo's purpose, and project-specific conventions
- [ ] Task 1.2: Create `~/code/training-platform-exercises/` -- Terraform project skeleton with CLAUDE.md, README, and module structure
- [ ] Task 1.3: Create `~/code/training-pm-exercises/` -- Product backlog structure plus a small development codebase (Java/Spring app) with CLAUDE.md and README

### Verification

- [ ] All three repos initialize and build/validate (Maven + npm, terraform init, Maven)

## Phase 2: Developer Exercise Materials

Build out the Java/Spring backend and Next.js frontend with exercise-specific scenarios mapped to each module.

### Tasks

- [ ] Task 2.1: **Module 1 (Prompting)** -- Create a Spring REST API with 3-4 endpoints and a Next.js frontend. Include a requirements doc describing features to add, so users can practice writing specific prompts
- [ ] Task 2.2: **Module 2 (Verification Loop)** -- Add a feature branch with an incomplete implementation and failing tests. Users practice the instruct-act-review-correct loop with explicit verification steps
- [ ] Task 2.3: **Module 3 (TDD)** -- Create test stubs with descriptions of expected behavior but no implementation. Include one test file with mocked HTTP calls that should be replaced with real dependencies (e.g., testcontainers or MockMvc)
- [ ] Task 2.4: **Module 4 (Debugging)** -- Introduce 3-4 intentional bugs across the codebase (null reference, off-by-one, wrong status code, race condition). Include a `BUGS.md` with symptoms but not solutions
- [ ] Task 2.5: **Module 5 (Context Management)** -- Create a large enough codebase that context management matters (~20+ files). Include a design decision log template in CLAUDE.md for persistence exercises
- [ ] Task 2.6: **Module 6 (Extensions)** -- Add an authentication module with enough complexity for subagent exploration. Include a `.claude/` directory with example skill and subagent configurations

### Verification

- [ ] Java/Spring backend compiles and existing tests pass
- [ ] Next.js frontend builds
- [ ] Intentional bugs produce the documented symptoms

## Phase 3: Platform Engineer Exercise Materials

Build out Terraform configurations and policy files for infrastructure exercises.

### Tasks

- [ ] Task 3.1: **Module 2 (Infrastructure)** -- Create Terraform modules for a VPC with private subnets, VPC endpoints, and a placeholder Bedrock configuration. Include a `terraform.tfvars.example` with sample values
- [ ] Task 3.2: **Module 3 (Configuration)** -- Provide sample `managed-settings.json` files (baseline and strict variants), a sample managed CLAUDE.md, and a deployment script skeleton for MDM distribution
- [ ] Task 3.3: **Module 4 (Permissions)** -- Create a permissions test harness: a `.claude/settings.json` with layered permission rules at managed, project, and user scopes. Include a test script that validates deny rules can't be overridden
- [ ] Task 3.4: **Module 5 (Cost Management)** -- Provide a cost calculator spreadsheet/script, sample CloudWatch dashboard JSON, and a gateway rate-limiting configuration template
- [ ] Task 3.5: **Module 6 (Rollout)** -- Create document templates: cohort roster spreadsheet, rollback playbook, success metrics dashboard, and a sample communication plan

### Verification

- [ ] `terraform init` and `terraform validate` pass on the infrastructure modules
- [ ] Sample configurations are valid JSON/YAML
- [ ] Cost calculator produces correct output for sample inputs

## Phase 4: Product Manager Exercise Materials

Build out the mock product backlog and development codebase for PM exercises.

### Tasks

- [ ] Task 4.1: **Mock backlog** -- Create a set of GitHub issues (as markdown files) representing a realistic product backlog: mix of well-written and poorly-written tickets, feature requests, and bug reports
- [ ] Task 4.2: **Module 5 (TDD)** -- Include tickets with vague acceptance criteria that users rewrite into testable Given/When/Then format. Provide before/after examples
- [ ] Task 4.3: **Module 6 (Workflows)** -- Set up a Spring app with 2-3 open PRs (as branches) that PMs can review: one that matches its ticket, one with scope creep, one missing acceptance criteria
- [ ] Task 4.4: **Feature decomposition** -- Include a large feature spec that users break into independently verifiable tasks. Provide a template for task decomposition

### Verification

- [ ] Development codebase compiles and tests pass
- [ ] All PR branches exist and diff cleanly against main
- [ ] Backlog issues are complete and realistic

## Phase 5: Integration

Link training articles to exercise repos and final verification.

### Tasks

- [ ] Task 5.1: Add exercise repo links to each training path article's exercise sections
- [ ] Task 5.2: Verify Hugo builds cleanly with updated training articles
- [ ] Task 5.3: Commit all changes to `feature/training-section` integration branch

### Verification

- [ ] Hugo production build succeeds
- [ ] All exercise links in training articles resolve
- [ ] All three exercise repos build/validate independently

## Final Verification

- [ ] All acceptance criteria met
- [ ] Each exercise in all three paths has starter materials
- [ ] Materials are self-contained
- [ ] Three repos with persona-specific CLAUDE.md
- [ ] Training articles link to exercise repos

_Generated by Conductor. Tasks will be marked [~] in progress and [x] complete._
