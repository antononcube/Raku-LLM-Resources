use v6.d;

unit module LLM::Resources;

use LLM::Resources::Graphs;
use LLM::Graph;
use LLM::Functions;
use LLM::Prompts;

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

    my %rules = LLM::Resources::Graphs.rules{$graph-name};

    $llm-evaluator = llm-evaluator($llm-evaluator);

    my $llm-graph = llm-graph(%rules, :$llm-evaluator, :$async, :$progress-reporting);

    $llm-graph.eval(%input);

    # Maybe just result nodes? Or take return type argument.
    return $llm-graph;
}