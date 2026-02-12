---
title: "The 'AI Will Replace Programmers' Narrative"
linkTitle: "AI Replacing Programmers"
weight: 1
---

# The "AI Will Replace Programmers" Narrative

What's actually happening vs. what people think is happening, based on conversations with colleagues, observations from local meetups, and the steady stream of hot takes online.

---

## The Claim

Non-technical people are building personal tools with AI and concluding:

1. We don't need programmers anymore
2. Anyone can vibe-code an application
3. SaaS is dead because why pay for something you can build yourself

---

## What's Actually True

The barrier to building personal tools has genuinely collapsed. Someone who couldn't code two years ago can now build something that solves their specific problem. That's real and worth taking seriously.

AI coding tools have made producing code almost trivially fast. Code production is no longer the constraint. What hasn't kept pace is everything around it: review bandwidth, testing, deployment confidence, operational readiness. I'm feeling this personally -- I can spin up changes faster than ever, but then they sit waiting for review, or I'm blocked on validating them properly, or the release process can't absorb the pace.

---

## What's Not True

### "Works for me" is not "works for everyone"

Building something that works once for you is fundamentally different from building something that works reliably for thousands of users with auth, billing, support, uptime, security patches, and compliance. The gap between "it works on my machine" and "it's a product" is enormous and AI hasn't closed it.

When you build for yourself, you unconsciously work around bugs. You know not to click that button twice. You don't need multi-tenancy, data isolation, GDPR compliance, rate limiting, graceful degradation, or a rollback plan. Your personal tool breaks at 2 AM? You shrug. A SaaS product breaks at 2 AM? You lose customers and money.

### "I can vibe-code it" is not "I can engineer it"

At a recent vibe coding meetup, the recurring theme was "why can't it just do what I ask" and "what do I do when I get stuck and don't have skills in that area." One PM wanted to do customer-facing website changes but didn't want to touch "the backend" -- what she called the HTML/CSS. "If I had wanted to become a software engineer I would have."

That attitude hits a wall fast. You can absolutely code yourself into a corner on larger projects. The tools amplify what you already understand. They don't substitute for understanding.

### SaaS isn't dead

SaaS isn't expensive because writing code is hard. It's expensive because reliability, security, compliance, support, integrations, multi-tenancy, and operations are hard. None of that goes away because someone vibe-coded a Streamlit app.

If anything, more people building increases demand for infrastructure and platforms -- auth services, database hosting, payment processing, deployment pipelines. The picks-and-shovels layer grows.

---

## The Historical Pattern

This cycle repeats:

- Spreadsheets didn't kill accounting
- WordPress didn't kill web development
- Squarespace didn't kill design agencies
- No-code didn't kill app development

Each wave democratized the simple tier and pushed professionals toward harder problems. The bottom of the market gets commoditized. The middle and top get more valuable because expectations rise.

---

## Who Wins

**Multi-disciplinary people who combine product sense with technical understanding will be the most sought after.** Product AND technical skills become the requirement. The bar goes up because more people are competing for fewer roles.

The right pattern for using AI effectively: treat it as a capable assistant that needs direction. Write stories from the product owner perspective, break work into digestible chunks, provide architectural guidance. That produces real results vs. "build me an app."

People who understand the system but use the tools to accelerate will be the real winners. People who skip the understanding part will keep hitting walls.

---

## The Junior Developer Problem

The job market for junior devs is shrinking. That said, they're learning the theory and using these tools in school, which isn't wasted. The theory matters more now, not less -- when code generation is cheap, the ability to evaluate whether generated code is correct becomes the differentiating skill.

---

## The Bottleneck Shift

The part most people in the AI hype cycle aren't talking about: the bottleneck has moved. Code production used to be the constraint. Now it's:

- **Review bandwidth** -- generating code faster doesn't help if review can't keep up
- **Testing confidence** -- more code means more surface area to verify
- **Deployment readiness** -- release processes built for human-speed development can't absorb AI-speed output
- **Operational maturity** -- running the thing is still hard

Until the verification and integration pipeline catches up to the generation pipeline, faster code production just moves the pileup downstream.

---

## The Wrong Optimization

There's a deeper critique of the "AI for coding" wave that deserves attention. [Mark Fisher](https://www.linkedin.com/posts/markrfisher_im-looking-forward-to-a-time-when-developers-activity-7422981475064508416-qLwD) -- creator of Spring Integration and one of the earliest contributors to the Spring Framework -- put it this way: "Generating 10x more code 10x as fast is not the answer to building better software. The greater potential of AI is to deliver 10x better experiences with 10x LESS code."

This lands differently coming from someone who's lived through the cycle. Spring's entire arc was about removing code, not adding it. J2EE was drowning in ceremony -- XML config files that could rival a novel in length, 200-line `pom.xml` files just to get a REST endpoint running. Spring didn't generate the XML faster; it eliminated the need for XML. Spring Boot didn't scaffold better; it made scaffolding unnecessary. Each step was about stripping away layers of ceremony until `@SpringBootApplication` and go was all you needed.

And now the AI-for-coding wave is celebrating that it can generate boilerplate at machine speed. Fisher would say that's the J2EE mistake all over again. The vibe coders at the meetup are generating full-stack apps with 47 files. The right question isn't "can AI write this code for me?" It's "should this code exist at all?"

Fisher's distinction between "AI for coding" (use AI to generate more code faster) and "coding for AI" (build primitives that agents compose dynamically) is where the real opportunity lies. His company, Modulewise, is exploring composable integration for intelligent systems -- small, well-defined building blocks that agents can wire together at runtime based on intent, rather than statically configured full-stack applications. Less like scaffolding a Rails app and more like how UNIX pipes work, but with agents that understand what you're trying to accomplish.

This is still more manifesto than shipped product. But the architectural thesis is sound, and it maps to a pattern that's worked before: raise the abstraction, eliminate the ceremony, let the platform figure out the how while you express the what. Spring proved that approach works. The question is whether the AI tooling ecosystem will learn the same lesson or keep selling "generate more stuff faster" because that's the easier pitch.

---

## On the "I Tested 17 AI Tools" Genre

There's a whole genre of blog posts where someone "tests" every AI coding tool and concludes that only 2-3 are useful, but only for limited tasks (code analysis, boilerplate, documentation). These evaluations are almost always based on pasting code into a chat window and evaluating the response -- the state of the art circa early 2024.

They miss agentic tools entirely. Claude Code reading your codebase, running commands, inspecting logs, executing tests, and iterating is a fundamentally different paradigm than "paste code into chat, evaluate response." The complaint that "AI can't see your metrics, logs, or traces" is exactly what tool use and MCP servers solve.

Similarly, the over-engineered prompting guides that prescribe rigid multi-phase role-playing workflows fight against how these models work best. Writing stories as a product owner and letting the AI figure out implementation is more effective than any "10 ChatGPT prompts that will 10x your productivity" system.

The genuine insight buried in these posts: AI tools give generic advice while production requires specific answers. That's real. But the solution isn't to dismiss AI tools -- it's to give them specific context ([memory organization]({{< relref "guides/memory-organization" >}}), codebase access, [MCP servers]({{< relref "guides/essential-plugins" >}})) so they can give specific answers.

---

## Bottom Line

AI coding tools are a genuine productivity multiplier for people who already understand what they're building. They are not a replacement for understanding. The people drawing the biggest conclusions ("programmers are done," "SaaS is dead") are the ones with the least context on what production software actually requires.

The real shift: code is no longer the scarce resource. Judgment is.
