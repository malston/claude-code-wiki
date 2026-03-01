# PM Training Path Redesign

**Date:** 2026-03-01
**Status:** Approved

## Problem

The PM training path was six modules teaching PMs to be junior developers -- software design principles, architecture decisions, coding standards, TDD. None of it taught PMs how to use Claude Code for their own work. Meanwhile, the Product Development section covers the stuff PMs actually own (product thinking, user research, prototyping, prioritization) and the training path didn't reference any of it.

## Decisions

- **Audience:** PMs who will use Claude Code directly AND work alongside developers using it. PM work first, developer literacy second.
- **Developer literacy:** Condensed from three modules (design, architecture, standards) to one.
- **Exercises:** Inline only, no separate exercise repo dependency.
- **Module count:** Five.

## New Structure

| Module                            | Focus                                           | Prerequisites |
| --------------------------------- | ----------------------------------------------- | ------------- |
| 1. How Claude Code Works          | What it is, what PMs can do with it             | None          |
| 2. Product Research & Discovery   | Research synthesis, validation, prototyping     | Module 1      |
| 3. Requirements & Prioritization  | Specs, decomposition, trade-off modeling        | Module 2      |
| 4. Technical Literacy             | Design, architecture, standards, TDD essentials | Module 2      |
| 5. Working with Development Teams | Tickets, reviews, session planning              | Modules 1-4   |

Modules 3 and 4 can be taken in either order. Both depend on Module 2, and Module 5 depends on all four.

## Key Changes

- Exercise repo references removed entirely (was `training-pm-exercises` with Spring Boot order service)
- Product Development articles woven in as references throughout
- Emphasis flipped from "understand developers" to "use Claude Code for PM work"
- Each module follows: Goal → Key Concepts → Claude Code in Practice → Exercises → References
