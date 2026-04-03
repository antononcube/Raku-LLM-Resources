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

Here is the usage message of CLI script `llm-text-summarization`:

```shell
llm-text-summarization --help
```
```
# Usage:
#   llm-text-summarization <input> [--title|--with-title=<Str>] [--conf|--llm|--llm-conf[=Any]] [--async] [--progress] [-o|--output=<Str>] -- LLM-based comprehensive text summarization.
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
llm-text-summarization some-large-text.txt -o summary.md --conf=ollama::gpt-oss:20b
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
my $gBestCode = llm-resource-graph('code-generation-by-fallback', input => {:$spec, lang => 'Raku', :split}, :$llm-evaluator);
```
```
# LLM::Graph(size => 4, nodes => code, dsl-grammar, llm-examples, workflow-name)
```

```raku
$gBestCode.nodes<code><result>
```
```
# ML::SparseMatrixRecommender.new(@dsData)
# .apply-term-weight-functions('IDF', 'None', 'Cosine')
# .recommend-by-profile({'passengerSex.male' => 1, 'passengerClass.1st' => 1})
# .join-across(@dsData, on => 'id')
# .echo-value()
```
