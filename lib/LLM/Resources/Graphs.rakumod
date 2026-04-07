use v6.d;

unit module LLM::Resources::Graphs;

# Core LLM packages
use LLM::Functions;
use LLM::Prompts;
use LLM::Graph;

# Data import, export, and transformation
use Data::Importers;
use Data::Translators;

# For code generation
use DSL::Translators;
use DSL::Examples;
use ML::FindTextualAnswer;
use ML::NLPTemplateEngine;

# Generic
use JSON::Fast;
use Hash::Merge;

#==========================================================
# Default LLM configuration and evaluator
#==========================================================

our $llm-evaluator = llm-evaluator(Whatever);
our sub set-default-llm-evaluator($obj) {
    $llm-evaluator = llm-evaluator($obj)
}

our sub get-default-llm-evaluator() {
    $llm-evaluator.clone
}

#==========================================================
# Comprehensive text summarization rules
#==========================================================
# See:
#  https://github.com/antononcube/RakuForPrediction-blog/blob/main/Articles/Agentic-AI-for-text-summarization.md
#  https://rakuforprediction.wordpress.com/2025/09/02/agentic-ai-for-text-summarization/

my %text-summarization =
        TypeOfInput => sub ($_) {
            "Determine the input type of\n\n$_.\n\nThe result should be one of: 'Text', 'URL', 'FilePath', or 'Other'."  ~
                    llm-prompt('NothingElse')('single string')
        },

        IngestText =>  { eval-function => sub ($TypeOfInput, $_) { $TypeOfInput ~~ / URL | FilePath/ ?? data-import($_) !! $_} },

        # Note that this uses the default LLM evaluator
        Title => {
            eval-function => sub ($IngestText, $with-title = Whatever) {
                $with-title ~~ Str:D && $with-title.trim
                        ?? $with-title
                        !! llm-synthesize([
                                llm-prompt("TitleSuggest")($IngestText, 'article'),
                                "Short title with less that 6 words"
                            ], llm-evaluator => get-default-llm-evaluator)
            },
        },

        Summary => sub ($IngestText) { llm-prompt("Summarize")() ~ "\n\n$IngestText" },

        TopicsTable => sub ($IngestText) { llm-prompt("ThemeTableJSON")($IngestText, 'article', 20) },

        ThinkingHats => sub ($IngestText) { llm-prompt("ThinkingHatsFeedback")($IngestText, <yellow grey>, format => 'HTML') },

        MindMap => sub ($IngestText) { llm-prompt('MermaidDiagram')($IngestText) },

        FindHiddenMessage => sub ($IngestText) { llm-prompt('FindHiddenMessage') ~ "\n\n$IngestText" },

        Report => { eval-function =>
            sub ($Title, $Summary, $TopicsTable, $MindMap, $ThinkingHats, $FindHiddenMessage) {
                [
                    "# $Title",
                    '### *LLM summary report*',
                    '## Summary',
                    $Summary,
                    '## Topics',
                    to-html(
                        from-json($TopicsTable.subst(/ ^ '```json' | '```' $/):g),
                        field-names => <theme content>,
                        align => 'left'
                    ),
                    "## Mind map",
                    $MindMap ~~ / ^ '```mermaid' | '```' $/ ?? $MindMap !! "```mermaid\n$MindMap\n```",
                    '## Thinking hats',
                    $ThinkingHats.subst(/ ^ '```html' | '```' $/):g,
                    '## Propaganda & hidden messages',
                    $FindHiddenMessage.subst(/ ^^ ('#' ** 2..6) /, { $0.Str ~ '#' }):g,
                ].join("\n\n")
            }
        }
        ;

#==========================================================
# Code generation: Fallback
#==========================================================
# See:
#  https://github.com/antononcube/RakuForPrediction-blog/blob/main/Articles/Robust-code-generation-combining-grammars-and-LLMs.md
#  https://raku-advent.blog/2025/12/06/day-6-robust-code-generation-combining-grammars-and-llms/

# Natural language labels to be understood by LLMs
my @mlLabels = 'Classification', 'Latent Semantic Analysis', 'Quantile Regression', 'Recommendations', 'Data Reshaping';

# Map natural language labels to workflow names in "DSL::Examples"
my %toMonNames = @mlLabels Z=> <ClCon LSAMon QRMon SMRMon DataReshaping>;

# Change the result of &llm-classify result into workflow names
sub llm-ml-workflow($spec, :$llm-evaluator) {
    my $res = llm-classify($spec, @mlLabels, request => 'which of these workflows characterizes it', :$llm-evaluator);
}

# Example invocation
#&llm-ml-workflow($spec);

# Specify a pipeline "separator" for the different programming languages:
my %langSeparator = Python => "\n.", Raku => "\n.", R => "%>%\n", WL => "⟹\n";

my %code-generation-by-fallback =
        dsl-grammar => {
            eval-function => sub ($spec, $lang = 'Raku') {
                my $res = ToDSLCode($spec, to => $lang, format => 'CODE');
                my $checkStr = 'my $obj = ML::SparseMatrixRecommender.new';
                return do with $res.match(/ $checkStr /):g {
                    $/.list.elems > 1 ?? $res.subst($checkStr) !! $res
                }
            }
        },

        workflow-name => {
            llm-function => sub ($spec) {
                my $class = llm-ml-workflow($spec, llm-evaluator => get-default-llm-evaluator);
                $class ~~ Positional:D ?? $class.head !! $class
            }
        },

        llm-examples => {
            llm-function => sub ($spec, $workflow-name is copy, $lang = 'Raku', $split = False) {
                $workflow-name = %toMonNames{$workflow-name} // $workflow-name;
                my &llm-pipeline-segment = llm-example-function(dsl-examples(){$lang}{$workflow-name}, llm-evaluator => get-default-llm-evaluator);
                return do if $split {
                    my @commands = $spec.lines;
                    @commands.map({ .&llm-pipeline-segment }).map({ .subst(/:i Output \h* ':'?/, :g).trim }).join(%langSeparator{$lang})
                } else {
                    &llm-pipeline-segment($spec).subst(";\n", %langSeparator{$lang}):g
                }
            },
            test-function => sub ($dsl-grammar) { !($dsl-grammar ~~ Str:D && $dsl-grammar.trim.chars) }
        },

        code => {
            eval-function => sub ($dsl-grammar, $llm-examples) {
                $dsl-grammar ~~ Str:D && $dsl-grammar.trim ?? $dsl-grammar !! $llm-examples
            }
        }
;

#==========================================================
# Code generation: Parallel race
#==========================================================
# See:
#  https://github.com/antononcube/RakuForPrediction-blog/blob/main/Articles/Robust-code-generation-combining-grammars-and-LLMs.md
#  https://raku-advent.blog/2025/12/06/day-6-robust-code-generation-combining-grammars-and-llms/

my %code-generation-by-parallel-race =
        dsl-grammar => {
            eval-function => sub ($spec, $lang = 'Raku') { ToDSLCode($spec, to => $lang, format => 'CODE') }
        },

        workflow-name => {
            llm-function => sub ($spec) {
                my $class = llm-ml-workflow($spec, llm-evaluator => get-default-llm-evaluator);
                $class ~~ Positional:D ?? $class.head !! $class
            }
        },

        llm-examples => {
            llm-function =>
                sub ($spec, $workflow-name is copy, $lang = 'Raku', $split = False) {
                    $workflow-name = %toMonNames{$workflow-name} // $workflow-name;
                    my &llm-pipeline-segment = llm-example-function(dsl-examples(){$lang}{$workflow-name}, llm-evaluator => get-default-llm-evaluator);
                    return do if $split {
                        note 'with spec splitting...';
                        my @commands = $spec.lines;
                        @commands.map({ .&llm-pipeline-segment }).map({ .subst(/:i Output \h* ':'?/, :g).trim }).join("\n.")
                    } else {
                        note 'no spec splitting...';
                        &llm-pipeline-segment($spec).subst(";\n", "\n."):g
                    }
                },
        },

        nlp-template-engine => {
            llm-function => sub ($spec, $workflow-name, $lang = 'Raku') {
                concretize($spec, template => $workflow-name, :$lang, llm-evaluator => get-default-llm-evaluator)
            }
        },

        judge => sub ($spec, $lang, $dsl-grammar, $llm-examples, $nlp-template-engine) {
            [
                "Choose the generated code that most fully adheres to the spec:\n",
                $spec,
                "\nfrom the following $lang generation results:\n\n",
                "1) DSL-grammar:\n$dsl-grammar\n",
                "2) LLM-examples:\n$llm-examples\n",
                "3) NLP-template-engine:\n$nlp-template-engine\n",
                "and copy it:"
            ].join("\n\n")
        },

        report => {
            eval-function => sub ($spec, $lang, $dsl-grammar, $llm-examples, $nlp-template-engine, $judge) {
                [
                    '# Best generated code',
                    "Three $lang code generations were submitted for the spec:",
                    '```text',
                    $spec,
                    '```',
                    'Here are the results:',
                    to-html( ['dsl-grammar', 'llm-examples', 'nlp-template-engine'].map({ [ name => $_, code => ::('$' ~ $_)] })».Hash.Array, field-names => <name code> ).subst("\n", '<br/>'):g,
                    '## Judgement',
                    $judge.contains('```') ?? $judge !! "```$lang\n" ~ $judge ~ "\n```"
                ].join("\n\n")
            }
        }
        ;

#==========================================================
# All rules hashmap
#==========================================================

our %rules =
        :%text-summarization,
        :%code-generation-by-fallback,
        :%code-generation-by-parallel-race,
        ;