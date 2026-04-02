# LLM::Resources

Raku package with different subs and CLI scripts for specific but repeatable LLM-based workflows.

----

## Installation

From Zef ecosystem:

```
zef install LLM::Resources
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-LLM-Resources.git
```

----

## Usage examples

### Comprehensive text summarization

Here is the usage message of CLI script `llm-text-summarize`:

```shell
llm-text-summarize --help
```

Here is an example usage:

```
llm-text-summarize some-large-text.txt -o summary.md --conf=ollama::gpt-oss:20b
```
