#!/usr/bin/env raku
use v6.d;

use LLM::Resources;
use LLM::Functions;

my $spec = q:to/END/;
create a brandon new recommender object;
load data @dsData;
apply LSI functions IDF, None, Cosine;
recommend by profile for passengerSex:male, and passengerClass:1st;
join across with @dsData on "id";
echo the pipeline value;
END

my $llm-evaluator = llm-evaluator(llm-configuration('Ollama', model => 'gpt-oss:20b'));

my $tStart = now;
my $gBestCode = llm-resource-graph('code-generation-by-parallel-race', input => {:$spec, lang => 'Raku', :split}, :$llm-evaluator, :async);
my $tEnd = now;

say '-' x 80;
say "LLM-graph evaluation {$tEnd - $tStart}.";
say '-' x 80;
say (:$gBestCode);
say '-' x 80;
say $gBestCode.nodes<code><result> // $gBestCode.nodes<report><result>;
