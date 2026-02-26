---
title: "The 'AI Will Replace Programmers' Narrative"
linkTitle: "AI Replacing Programmers"
weight: 1
---

# The "AI Will Replace Programmers" Narrative

What's actually happening vs. what people think is happening, based on conversations with colleagues, observations from local meetups, and the steady stream of hot takes online.

## The Claim

Non-technical people are building personal tools with AI and concluding:

1. We don't need programmers anymore
2. Anyone can vibe-code an application
3. SaaS is dead because why pay for something you can build yourself

## What's Actually True

The barrier to building personal tools has genuinely collapsed. Someone who couldn't code two years ago can now build something that solves their specific problem. That's real and worth taking seriously.

AI coding tools have made producing code almost trivially fast. Code production is no longer the constraint. What hasn't kept pace is everything around it: review bandwidth, testing, deployment confidence, operational readiness. I'm feeling this personally -- I can spin up changes faster than ever, but then they sit waiting for review, or I'm blocked on validating them properly, or the release process can't absorb the pace.

## What's Not True

### "Works for me" is not "works for everyone"

Building something that works once for you is fundamentally different from building something that works reliably for thousands of users with auth, billing, support, uptime, security patches, and compliance. The gap between "it works on my machine" and "it's a product" is enormous and AI hasn't closed it.

When you build for yourself, you unconsciously work around bugs. You know not to click that button twice. You don't need multi-tenancy, data isolation, GDPR compliance, rate limiting, graceful degradation, or a rollback plan. Your personal tool breaks at 2 AM? You shrug. A SaaS product breaks at 2 AM? You lose customers and money.

### "I can vibe-code it" is not "I can engineer it"

At a recent vibe coding meetup, the recurring theme was "why can't it just do what I ask" and "what do I do when I get stuck and don't have skills in that area." One PM wanted to do customer-facing website changes but didn't want to touch "the backend" -- what she called the HTML/CSS. "If I had wanted to become a software engineer I would have."

That reaction reflects a reasonable expectation the tools created and can't yet fulfill. She wants engineering outcomes without engineering knowledge, and the marketing around these tools told her that was the deal. The gap between that promise and reality is where most vibe coding projects die. Not at the start, when everything feels magical. Three weeks in, when you're staring at an error message that means nothing to you and the AI keeps suggesting fixes that make it worse.

The tools amplify what you already understand. They don't substitute for understanding. You can absolutely code yourself into a corner on larger projects, and the less you know about the corner, the deeper you get before you realize you're stuck.

### SaaS Isn't Dead

SaaS isn't expensive because writing code is hard. It's expensive because reliability, security, compliance, support, integrations, multi-tenancy, and operations are hard. None of that goes away because someone vibe-coded a Streamlit app.

More people building means more demand for the infrastructure underneath: auth services, database hosting, payment processing, deployment pipelines. The picks-and-shovels layer grows.

## The Historical Pattern

This cycle repeats:

- Spreadsheets didn't kill accounting
- WordPress didn't kill web development
- Squarespace didn't kill design agencies
- No-code didn't kill app development

Each wave democratized the simple tier and pushed professionals toward harder problems. The bottom of the market gets commoditized. The middle and top get more valuable because expectations rise.

The pattern still holds with AI. What's different is the clock speed.

Spreadsheets played out over decades. WordPress over a decade. No-code over years. AI is compressing the cycle into months. The pattern was never reassuring because of what happened -- it was reassuring because of how long people had to adapt between waves. Accountants had a generation to move up the value chain. Web developers had a decade to shift from static HTML to full-stack engineering.

AI isn't giving people that runway. The adaptive mechanisms that made previous waves manageable -- retraining programs, career pivots, industry restructuring -- assume years of lead time. When the cycle compresses to months, those mechanisms don't disappear, but they stop working for anyone who isn't already in motion. The people most at risk aren't those who refuse to adapt. They're the ones operating on the assumption that they have the same runway previous generations had.

## Who Wins

The right pattern for using AI effectively: treat it as a capable assistant that needs direction. Write stories from the product owner perspective, break work into digestible chunks, provide architectural guidance. That produces real results vs. "build me an app."

The people who thrive will be the ones who understand the system and use the tools to accelerate within it. The roles now demand both product sense and technical depth. The bar goes up because more people are competing for fewer of these roles, and each role demands range that used to be spread across a team.

People who skip the understanding part will keep hitting walls. Faster.

## The Junior Developer Problem

The job market for junior devs is shrinking. Companies that used to hire five juniors and grow them into seniors are instead hiring two mid-levels and handing them AI tools. The math makes sense quarter to quarter. It stops making sense over five years.

Senior engineers didn't appear from nowhere. They were junior engineers who spent years making mistakes in production, debugging systems they didn't fully understand, and slowly building the judgment that makes them valuable. If you cut off that pipeline, you're consuming a resource you're not replenishing. The industry is eating its seed corn.

The counterargument: juniors are learning theory and using these tools in school, so they'll arrive pre-accelerated. There's truth in that. Theory matters more now, not less. When code generation is cheap, the ability to evaluate whether generated code is correct becomes the differentiating skill. But theory without operational reps produces people who can pass an interview and struggle in production. The tools don't substitute for the years of "I shipped a bug at 3 AM and learned why input validation matters."

This is the structural crack underneath the "who wins" argument. The winners need deep system understanding. Deep system understanding comes from years of practice. The market is eliminating the entry point for that practice. Something has to give. Either companies find ways to grow juniors alongside AI tools, or the talent pipeline thins until senior engineers become scarce enough that the economics reverse.

## The Bottleneck Shift

The bottleneck has moved. Code production used to be the constraint. Now it's:

- **Review bandwidth** -- generating code faster doesn't help if review can't keep up
- **Testing confidence** -- more code means more surface area to verify
- **Deployment readiness** -- release processes built for human-speed development can't absorb AI-speed output
- **Operational maturity** -- running the thing is still hard

Until the verification and integration pipeline catches up to the generation pipeline, faster code production just moves the pileup downstream.

The tooling is starting to address this. Agentic coding tools that read your codebase, run commands, inspect logs, execute tests, and iterate represent a fundamentally different paradigm than pasting code into a chat window and evaluating the response. The complaint that "AI can't see your metrics, logs, or traces" is exactly what tool use and [MCP servers]({{< relref "guides/essential-plugins" >}}) solve. The generic-advice problem is real, but the fix is giving the tools specific context: [memory organization]({{< relref "guides/memory-organization" >}}), project history, runtime state. The bottleneck moves again when the verification tools catch up to the generation tools.

## The Wrong Optimization

There's a deeper critique of the "AI for coding" wave that deserves attention. [Mark Fisher](https://www.linkedin.com/posts/markrfisher_im-looking-forward-to-a-time-when-developers-activity-7422981475064508416-qLwD) -- creator of Spring Integration and one of the earliest contributors to the Spring Framework -- put it this way: "Generating 10x more code 10x as fast is not the answer to building better software. The greater potential of AI is to deliver 10x better experiences with 10x LESS code."

This lands differently coming from someone who's lived through the cycle. Spring's entire arc was about removing code, not adding it. J2EE was drowning in ceremony -- XML config files that could rival a novel in length, 200-line `pom.xml` files just to get a REST endpoint running. Spring didn't generate the XML faster; it eliminated the need for XML. Spring Boot didn't scaffold better; it made scaffolding unnecessary. Each step was about stripping away layers of ceremony until `@SpringBootApplication` and go was all you needed.

And now the AI-for-coding wave is celebrating that it can generate boilerplate at machine speed. Fisher would say that's the J2EE mistake all over again. The vibe coders at the meetup are generating full-stack apps with 47 files. The right question isn't "can AI write this code for me?" It's "should this code exist at all?"

Fisher's distinction between "AI for coding" (use AI to generate more code faster) and "coding for AI" (build primitives that agents compose dynamically) is where the real opportunity lies. His company, Modulewise, is exploring composable integration for intelligent systems -- small, well-defined building blocks that agents can wire together at runtime based on intent, rather than statically configured full-stack applications. Less like scaffolding a Rails app and more like how UNIX pipes work, but with agents that understand what you're trying to accomplish.

This is still more manifesto than shipped product. But the architectural thesis is sound, and it maps to a pattern that's worked before: raise the abstraction, eliminate the ceremony, let the platform figure out the how while you express the what. Spring proved that approach works. The question is whether the AI tooling ecosystem will learn the same lesson or keep selling "generate more stuff faster" because that's the easier pitch.

## Bottom Line

AI coding tools are a productivity multiplier for people who already understand what they're building. They are not a replacement for understanding. The people drawing the biggest conclusions ("programmers are done," "SaaS is dead") are the ones with the least context on what production software actually requires.

The real shift: code is no longer the scarce resource. Judgment is.
