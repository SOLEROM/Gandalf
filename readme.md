# GANDALF

My custom assistant for LLM agents development and management based on public tools and templates, with a focus on Anthropic's Claude.


## Tools Map

```0 claude settings``` : *GLOBAL* setting config files

```2 scope``` : codebase scanning ;
* socraticode - ollama + qdrant for codebase indexing and semantic search;

```1 claude top mds``` : top level markdown files *TEMPLATES*


```3 agentTeam``` :  skill to build *A-TEAM* of agents to implement a project from a markdown plan;

```4 ganMaster``` :  skill to implement *GOF* patterns;

```10 tools``` : local clones of *public tools*


## submodules:
* my skill or public skills are clone here by submodels
```
git submodule add  https://github.com/SOLEROM/skill_XXXXX 11_mySubsSkills/skill_XXXX
```

## deployment:

* run ```deploy.sh``` script that will updare ~/.cluade (only the needed files)


