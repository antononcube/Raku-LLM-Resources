use v6.d;

unit module LLM::Resources::DSLTranslation;

use DSL::Examples;
use LLM::Functions;
use ML::FindTextualAnswer;
use ML::NLPTemplateEngine;
use JSON::Fast;

#==========================================================
# Utilities
#==========================================================

# Natural language labels to be understood by LLMs
my @mlLabels =
        'Classification', 'Latent Semantic Analysis', 'Quantile Regression', 'Recommendations',
        'Data Reshaping', 'Prefix Trees';

# Map natural language labels to workflow names in "DSL::Examples"
my %toMonNames = @mlLabels Z=> <ClCon LSAMon QRMon SMRMon DataReshaping TriesWithFrequencies>;

# Change the result of &llm-classify result into workflow names
sub llm-ml-workflow($spec, :$llm-evaluator, Bool:D :$echo = False) {
    my $res = llm-classify($spec, @mlLabels, request => 'which of these workflows characterizes it', :$llm-evaluator, :$echo);
}

# Specify a pipeline "separator" for the different programming languages:
my %langSeparator = Python => "\n.", Raku => "\n.", R => "%>%\n", WL => "⟹\n";

#==========================================================
# LLM DSL Translation
#==========================================================

#| Translation of input from one language to another using LLM-based methods.
our proto sub llm-dsl-translation(
        $input,                                    #= String or a list of strings to translate.
        :t(:to(:to-lang(:$lang))) = Whatever,      #= Language to translate to.
        :w(:workflow(:$workflow-spec)) = Whatever, #= Workflow spec; string or Whatever.
        :m(:$method) = Whatever,                   #= Method, one 'dsl-examples', 'nlp-template-engine' or Whatever.
        :e(:$llm-evaluator) = Whatever,            #= LLM-evaluator spec.
        :split-with(:separator(:$sep)) = Whatever, #= Separator(s) to split the input with; string or regex.
        Bool:D :$echo = False,                     #= Whether to echo internal stages or not.
                              ) is export {*}

multi sub llm-dsl-translation(
        $input,
        :t(:to(:to-lang(:$lang))) is copy = Whatever,
        :w(:workflow(:$workflow-spec)) is copy = Whatever,
        :m(:$method) is copy = Whatever,
        :e(:$llm-evaluator) is copy = Whatever,
        :split-with(:separator(:$sep)) is copy = Whatever,
        Bool:D :$echo = False,
                              ) {

    # Process method
    $method = do given $method {
        when $_.isa(Whatever) || $_.isa(WhateverCode) { 'dsl-examples' }
        when $_ ~~ Str:D && $_.lc ∈ <dsl-examples dslexamples examples few-shot fewshot> { 'dsl-examples' }
        when $_ ~~ Str:D && $_.lc ∈ <template templates templateengine template-engine nlptemplateengine nlp-template-engine> { 'nlp-template-engine' }
        default {
            die 'The value of :$method is expected one of "dsl-examples", "nlp-template-engine" or Whatever.'
        }
    }

    # Process separator
    $sep = do given $sep {
        when Whatever { "\n" }
        when WhateverCode { rx/ \v | [ \h+ ';' \h+ \v]/ }
        default {
            $_
        }
    }

    # Process workflow spec
    if $workflow-spec.isa(Whatever) {
        my $class = llm-ml-workflow($input, :$llm-evaluator, :$echo);
        $workflow-spec = $class ~~ Positional:D ?? $class.head !! $class;
    }

    # Process LLM lang
    if $lang.isa(Whatever) { $lang = 'Raku' }

    # Process LLM evaluator
    $llm-evaluator = llm-evaluator($llm-evaluator);

    note "llm-evaluator : {$llm-evaluator.raku}" if $echo;

    # Translate
    return do given $method {
        when 'dsl-examples' {

            $workflow-spec = %toMonNames{$workflow-spec} // $workflow-spec;

            note (:$workflow-spec) if $echo;

            my $examples = dsl-examples(){$lang}{$workflow-spec};

            note "DSL examples : {$examples ?? to-json($examples, :pretty) !! $examples.raku}" if $echo;

            my &llm-pipeline-segment = llm-example-function($examples, :$llm-evaluator);

            my $lang-sep = dsl-workflow-separators(){$lang}{$workflow-spec} // %langSeparator{$lang} // "\n";

            note ('lang-sep' => $lang-sep.raku) if $echo;

            return do if $sep.defined {
                my @commands = $input.split($sep, :skip-empty)».trim;
                @commands.map({ .&llm-pipeline-segment }).map({ .subst(/:i Output \h* ':'?/, :g).trim }).join($lang-sep)
            } else {
                &llm-pipeline-segment($input).subst(";\n", $lang-sep):g
            }
        }
        when 'nlp-template-engine' {
            concretize($input, template => $workflow-spec, :$lang, :$llm-evaluator, :$echo)
        }
    }
}
