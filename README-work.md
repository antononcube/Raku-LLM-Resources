# LLM::Resources

Raku package with different subs and CLI scripts for specific but repeatable LLM-based workflows.

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

Here is the usage message of CLI script `llm-text-summarize`:

```shell
llm-text-summarize --help
```

Here is an example usage:

```
llm-text-summarize some-large-text.txt -o summary.md --conf=ollama::gpt-oss:20b
```

---

### Code generation

```raku
use LLM::Functions;
use LLM::Resources;

my $spec = q:to/END/;
make a brand new recommender with the data @dsData;
apply LSI functions IDF, None, Cosine; 
recommend by profile for passengerSex:male, and passengerClass:1st;
join across with @dsData on "id";
echo the pipeline value;
END

my $llm-evaluator = llm-evaluator('Ollama', model => 'gemma3:4b');
my $gBestCode = llm-resource-graph('code-generate-by-fallback', input => {:$spec, lang => 'Raku', :split}, :$llm-evaluator);
```

```raku
$gBestCode.nodes<code><result>
```
