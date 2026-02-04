# Alex Finn's OpenClaw Best Practices

## Top 10 Tips & Content from Alex Finn

### 1. Master the Onboarding (Context Dump)
The single most critical step. Treat it like onboarding a new human employee. Tell it everything: your business goals, current projects, work style, key competitors, hobbies, and personal preferences. The richer the initial context, the more effective.

### 2. Give the Proactive Mandate
You must explicitly grant permission and expectation to be proactive. After initial onboarding, give a powerful directive.

### 3. Interview Your Bot
Hunt for "unknown unknowns" by asking open-ended questions:
- "Based on my role as [X], what are 10 things you can do to make my life easier?"
- Forces the AI to search its capabilities and suggest workflows you didn't consider

### 4. Use the Right Model for the Job
- **Brain (complex reasoning):** Claude Opus, GPT-4
- **Muscles (execution):** Kimi K2.5, Haiku, local models via LM Studio
- This manages costs while maintaining quality

### 5. Morning Brief Prompt
```
I want you to send me a morning brief every morning at 8am my time. Include:
- Local weather for the day
- Trending YouTube videos about my interests
- Tasks I need to get done today from my todo list
- Tasks you can do for me today based on what you know about me
- Trending stories based on my interests
- Recommendations to make today super productive
```

### 6. Proactive Coder Prompt (Henry Bot)
```
I am a 1 man business. I work from the moment I wake up to the moment I go to sleep. I need an employee taking as much off my plate and being as proactive as possible. Please take everything you know about me and just do work you think would make my life easier or improve my business and make me money. I want to wake up every morning and be like "wow, you got a lot done while I was sleeping." Don't be afraid to monitor my business and build things that would help improve our workflow. Just create PRs for me to review, don't push anything live. I'll test and commit. Every night when I go to bed, build something cool I can test. Schedule time to work every night at 11pm
```

### 7. Second Brain Setup
```
I want you to build me a 2nd brain. This should be a NextJS app that shows a list of documents you create as we work together in a nice document viewer that feels like a mix of Obsidian and Linear. I want you to create a folder where all the documents in that folder are viewable in this 2nd brain. Update your memories/skills so that as we talk every day, you create documents that explore the more important concepts we discuss. You should also create daily journal entries that record all our daily discussions.
```

### 8. Afternoon Research Report
```
I want a daily research report sent to me every afternoon. Based on what you know about me, research and give me a report about:
- A concept that would improve me
- Processes that would improve our working relationship
- Anything else helpful (deep dives on concepts like machine learning, new workflows to improve productivity)
```

### 9. Model Fallback Configuration
Configure multiple models to handle rate limits gracefully:
- Primary: Claude Sonnet
- Fallback 1: GPT-4
- Fallback 2: GPT-4-mini or Kimi K2.5

### 10. Multiple API Keys
Add multiple Anthropic keys to increase rate limit ceiling. OpenClaw rotates through them automatically.

---

## Security Best Practices (Critical)

1. **NEVER run on your primary machine** - Use dedicated Mac Mini or VPS
2. **Sandbox the agent** - Create dedicated accounts with limited permissions
3. **Never connect to main accounts** - Use separate email, no password manager access
4. **Watch for prompt injection** - Attackers can hide commands in emails/websites
5. **Review community skills carefully** - Some contain vulnerabilities

---

## Sources
- Alex Finn Twitter: @AlexFinn
- YouTube: "ClawdBot is the most powerful AI tool I've ever used"
- YouTube: "How to make ClawdBot 10x better (5 easy steps)"
- YouTube: "Set up ClawdBot so you save THOUSANDS of dollars"
- Reddit: r/ThinkingDeeplyAI Ultimate Guide to OpenClaw
