use v6.d;

#==========================================================
# Export
#==========================================================

sub EXPORT {
    use LLM::Resources::DSLTranslation;
    Map.new:
            '&llm-dsl-translation' => &LLM::Resources::DSLTranslation::llm-dsl-translation
}

unit module LLM::Resources;

use LLM::Resources::Graphs;
use LLM::Resources::DSLTranslation;
use LLM::Graph;
use LLM::Functions;
use LLM::Prompts;
use Data::Importers;

#==========================================================
# LLM resource function
#==========================================================

#| LLM resource function for a given resource identifier.
proto sub llm-resource-function($resource, *%args) is export {*}

multi sub llm-resource-function(IO::Path:D $resource, *%args) {
    die "Cannot ingest the resource: $resource." unless $resource.f;
    my $text = slurp($resource);
    return llm-function({$text ~ "\n$_"}, |%args);
}

multi sub llm-resource-function(Str:D $resource, *%args) {
    # For $resource:

    # - Check is it a known prompt
    if llm-prompt-data{$resource} {
        my $prompt = llm-prompt($resource);
        return $prompt ~~ Callable:D ?? llm-function( { $prompt($_) }, |%args) !! llm-function({$prompt ~ "\n$_"}, |%args)
    }

    # - File location of a string -- to be used as prompt
    return llm-resource-function($resource.IO, |%args) if $resource.IO.f;

    # - Check is it a known graph
    if %LLM::Resources::Graphs::rules{$resource}:exists {
        my %rules = %LLM::Resources::Graphs::rules{$resource};

        my $llm-graph = llm-graph(%rules, |%args);

        # This should be a function; just a graph for now. (LLM::Graph objects are callables.)
        return $llm-graph;
    }

    # - URL location of a string -- to be used as prompt
    my $text;
    try {
        $text = data-import($resource, 'plaintext');
    }

    if !$! {
        return llm-function({$text ~ "\n$_"}, |%args);
    }

    # - At this point it is "just" a string
    return llm-function({$resource ~ "\n$_"}, |%args);
}

#==========================================================
# LLM resource graph
#==========================================================

#| Invoke a resource graph by its name with given input and operating values.
proto sub llm-resource-graph(|) is export {*}

multi sub llm-resource-graph(Str:D $graph-name, *%args) {
    return llm-resource-graph(:$graph-name, |%args);
}

multi sub llm-resource-graph(
        Str:D :graph(:name(:$graph-name))!,
        :%input!,
        :e(:$llm-evaluator) is copy = Whatever,
        Bool:D :$async = True,
        Bool:D :echo(:progress(:$progress-reporting)) = False
        ) {

    die 'Unknown graph name.'
    unless %LLM::Resources::Graphs::rules{$graph-name}:exists;

    my %rules = %LLM::Resources::Graphs::rules{$graph-name};

    $llm-evaluator = llm-evaluator($llm-evaluator);

    # Set the default evaluator to be user-specified one
    my $llm-evaluator-current = LLM::Resources::Graphs::get-default-llm-evaluator();
    LLM::Resources::Graphs::set-default-llm-evaluator($llm-evaluator);

    my $llm-graph = llm-graph(%rules, :$llm-evaluator, :$async, :$progress-reporting);

    $llm-graph.eval(%input);

    # Restore the default evaluator
    LLM::Resources::Graphs::set-default-llm-evaluator($llm-evaluator-current);

    # Maybe just result nodes? Or take return type argument.
    return $llm-graph;
}