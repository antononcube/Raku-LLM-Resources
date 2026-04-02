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
```
# Usage:
#   llm-text-summarize <input> [--title|--with-title=<Str>] [--conf|--llm|--llm-conf[=Any]] [--async] [--progress] [-o|--output=<Str>] -- LLM-based comprehensive text summarization.
#   
#     <input>                          Text, file path, or a URL.
#     --title|--with-title=<Str>       Title of the result document; if 'Whatever' or 'Auto' then it is derived from the text. [default: 'Whatever']
#     --conf|--llm|--llm-conf[=Any]    LLM specification. (E.g. "gpt-5.2" or "openai::gpt-4.1-mini".) [default: 'chatgpt::gpt-5.1']
#     --async                          Whether to make the LLM calls interactively or not. [default: True]
#     --progress                       Whether to show progress or not. [default: True]
#     -o|--output=<Str>                Output location; if empty or '-' then stdout is used. [default: '-']
```

Here is an example usage:

```
llm-text-summarize some-large-text.txt -o summary.md --conf=ollama::gpt-oss:20b
```
