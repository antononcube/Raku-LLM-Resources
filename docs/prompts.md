
## Agent Skill Validator class

```text
Write the class `LLM::Resources::AgentSkillValidator` in "./lib/LLM/Resources/AgentSkillValidator.rakumod" that has methods for validating the structure, format, and content an Agent Skill directory. 
If you have to refer to the Python package "skills-ref" -- see https://github.com/agentskills/agentskills/tree/main/skills-ref .
```

> The reference behavior is deliberately narrow: extra files/directories are allowed, the body may be empty, and validation centers on SKILL.md plus its YAML metadata. I’ll expose both one-shot validation and separate structure/format/content methods, returning error-message arrays rather than throwing during normal validation.