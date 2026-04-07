#!/usr/bin/env raku
use v6.d;

use LLM::Resources;
use LLM::Functions;
use Graph;

# Machine Learning workflow spec
my $spec = q:to/END/;
new recommender object;
load data @dsData;
apply LSI functions IDF, None, Cosine;
recommend by profile for passengerSex:male, and passengerClass:1st;
join across with @dsData on "id";
echo the pipeline value;
END

# Using an Ollama model
my $llm-evaluator = llm-evaluator(llm-configuration('Ollama', model => 'gemma3:4b'));

# The LLM-graph 'code-generation-by-parallel-race' uses DSL translators (grammar-based), DSL examples (LLM-based), and NLP template engine (LLM-based).
# The LLM-graph 'code-generation-by-fallback' uses DSL translators (grammar-based) and DSL examples (LLM-based).

my @graph-names = <code-generation-by-fallback code-generation-by-parallel-race>;

for @graph-names -> $g {
    say '=' x 80;
    say "Graph: $g";
    say '-' x 80;

    my $tStart = now;
    my $gBestCode = llm-resource-graph($g, input => { :$spec, lang => 'Raku', :split }, :$llm-evaluator, :async);
    my $tEnd = now;

    say "LLM-graph evaluation  {$tEnd - $tStart}.";
    say '-' x 80;
    say (:$gBestCode);
    say '-' x 80;
    my @end-nodes = $gBestCode.graph.vertex-out-degree(:p).grep(!*.value)».key;
    say (:@end-nodes);
    say '-' x 80;
    { $_<result>.say } for $gBestCode.nodes{|@end-nodes};
}