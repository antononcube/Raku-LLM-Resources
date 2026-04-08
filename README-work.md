# LLM::Resources

Raku package with different subs and CLI scripts for specific but repeatable LLM-based workflows.

For usage examples see:
- The sections below
- Jupyter notebook ["Basic-usage.ipynb"](https://github.com/antononcube/Raku-LLM-Resources/blob/main/docs/Basic-usage.ipynb)
- The script ["Basic-usage.raku"](https://github.com/antononcube/Raku-LLM-Resources/blob/main/examples/Basic-usage.raku)

There are several options for using LLMs with this package:

- Install and run [Ollama](https://ollama.com)
  - For the corresponding setup see ["WWW::Ollama"](https://github.com/antononcube/Raku-WWW-Ollama)
- Run a [llamafile / LLaMA model](https://github.com/mozilla-ai/llamafile)
  - For the corresponding setup see ["WWW::LLaMA"](https://github.com/antononcube/Raku-WWW-LLaMA)
- Have programmatic access to LLMs of service providers like [OpenAI](https://developers.openai.com/api/docs/models) or [Gemini](https://ai.google.dev/gemini-api/docs/models)
  - For the corresponding setup see ["WWWW::OpenAI"](https://github.com/antononcube/Raku-WWW-OpenAI), ["WWWW::Gemini"](https://github.com/antononcube/Raku-WWW-Gemini), or ["WWW::MistralAI"](https://github.com/antononcube/Raku-WWW-MistralAI) 

----

## Installation

### Preliminary installations

The code generation LLM-graphs use the package ["DSL::Translators"](https://github.com/antononcube/Raku-DSL-Translators)
which is not in the Zef ecosystem. Install it with [this script](https://github.com/antononcube/RakuForPrediction-book/blob/main/scripts/raku-dsl-install.sh).

Here is an example of such installation: 

```
curl -O https://raw.githubusercontent.com/antononcube/RakuForPrediction-book/refs/heads/main/scripts/raku-dsl-install.sh
source raku-dsl-install.sh
```

To check successful installation use the following command in a terminal:

```
dsl-translation 'use dfTitanic; filter by sex is male; show counts'
```

### The package installation

From Zef ecosystem:

```
zef install LLM::Resources
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-LLM-Resources.git
```

----

## Comprehensive text summarization

Here is the usage message of CLI script `llm-text-summarization`:

```shell
llm-text-summarization --help
```

Here is an example usage:

```
llm-text-summarization some-large-text.txt -o summary.md --conf=ollama::gpt-oss:20b
```

---

### Code generation

```raku
use LLM::Functions;
use LLM::Resources;

my $spec = q:to/END/;
new recommender object;
load dataset @dsData;
make document term matrix;
apply LSI functions IDF, None, Cosine; 
recommend by profile for passengerSex:male, and passengerClass:1st;
join across with @dsData on "id";
echo the pipeline value;
END

my $llm-evaluator = llm-evaluator('Ollama', model => 'gemma3:4b');
my $gBestCode = llm-resource-graph('code-generation-by-fallback', input => {:$spec, lang => 'Raku', :split}, :$llm-evaluator);
```

```raku
$gBestCode.nodes<code><result>
```

-----

## References

### Articles, blog posts

[AA1] Anton Antonov,
["Agentic-AI for text summarization"](https://rakuforprediction.wordpress.com/2025/09/02/agentic-ai-for-text-summarization/),
(2025),
[RakuForPrediction at WordPress](https://rakuforprediction.wordpress.com). 
([GitHub](https://github.com/antononcube/RakuForPrediction-blog/blob/main/Articles/Agentic-AI-for-text-summarization.md).)

[AA2] Anton Antonov,
["Day 6 – Robust code generation combining grammars and LLMs"](https://raku-advent.blog/2025/12/06/day-6-robust-code-generation-combining-grammars-and-llms/),
(2025),
[Raku Advent Calendar at WordPress](https://raku-advent.blog).
([GitHub](https://github.com/antononcube/RakuForPrediction-blog/blob/main/Articles/Robust-code-generation-combining-grammars-and-LLMs.md), 
[Wolfram Community](https://community.wolfram.com/groups/-/m/t/3588794).)

### Packages

[AAp1] Anton Antonov
[LLM::Functions, Raku package](https://github.com/antononcube/Raku-LLM-Functions),
(2023-2026),
[GitHub/antononcube](https://github.com/antononcube).

[AAp2] Anton Antonov
[LLM::Prompts, Raku package](https://github.com/antononcube/Raku-LLM-Prompts),
(2023-2025),
[GitHub/antononcube](https://github.com/antononcube).

[AAp3] Anton Antonov
[DSL::Examples, Raku package](https://github.com/antononcube/Raku-DSL-Examples),
(2024-2025),
[GitHub/antononcube](https://github.com/antononcube).

[AAp4] Anton Antonov
[DSL::Translators, Raku package](https://github.com/antononcube/Raku-DSL-Translators),
(2020-2026),
[GitHub/antononcube](https://github.com/antononcube).

[AAp5] Anton Antonov
[ML::NLPTemplateEngine, Raku package](https://github.com/antononcube/Raku-ML-NLPTemplateEngine),
(2023-2025),
[GitHub/antononcube](https://github.com/antononcube).

[AAp6] Anton Antonov
[WWW::OpenAI, Raku package](https://github.com/antononcube/Raku-WWW-OpenAI),
(2023-2026),
[GitHub/antononcube](https://github.com/antononcube).

[AAp7] Anton Antonov
[WWW::Gemini, Raku package](https://github.com/antononcube/Raku-WWW-Gemini),
(2023-2025),
[GitHub/antononcube](https://github.com/antononcube).

[AAp8] Anton Antonov
[WWW::MistralAI, Raku package](https://github.com/antononcube/Raku-WWW-MistralAI),
(2023-2024),
[GitHub/antononcube](https://github.com/antononcube).

[AAp9] Anton Antonov
[WWW::LLaMA, Raku package](https://github.com/antononcube/Raku-WWW-LLaMA),
(2024-2025),
[GitHub/antononcube](https://github.com/antononcube).

[AAp10] Anton Antonov
[WWW::Ollama, Raku package](https://github.com/antononcube/Raku-WWW-Ollama),
(2026),
[GitHub/antononcube](https://github.com/antononcube).

