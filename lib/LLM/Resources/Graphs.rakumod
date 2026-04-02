use v6.d;

unit module LLM::Resources::Graphs;

use LLM::Graph;
use LLM::Functions;
use LLM::Prompts;
use Data::Importers;
use Data::Translators;
use JSON::Fast;
use Hash::Merge;

my %text-summarize =
        TypeOfInput => sub ($_) {
            "Determine the input type of\n\n$_.\n\nThe result should be one of: 'Text', 'URL', 'FilePath', or 'Other'."  ~
                    llm-prompt('NothingElse')('single string')
        },

        IngestText =>  { eval-function => sub ($TypeOfInput, $_) { $TypeOfInput ~~ / URL | FilePath/ ?? data-import($_) !! $_} },

        Title => {
            eval-function => sub ($IngestText, $with-title = Whatever) {
                $with-title ~~ Str:D
                        ?? $with-title
                        !! llm-synthesize([llm-prompt("TitleSuggest")($IngestText, 'article'), "Short title with less that 6 words"]) },
        },

        Summary => sub ($IngestText) { llm-prompt("Summarize")() ~ "\n\n$IngestText" },

        TopicsTable => sub ($IngestText) { llm-prompt("ThemeTableJSON")($IngestText, 'article', 20) },

        ThinkingHats => sub ($IngestText) { llm-prompt("ThinkingHatsFeedback")($IngestText, <yellow grey>, format => 'HTML') },

        MindMap => sub ($IngestText) { llm-prompt('MermaidDiagram')($IngestText) },

        Report => { eval-function =>
        sub ($Title, $Summary, $TopicsTable, $MindMap, $ThinkingHats) {
            [
                "# $Title",
                '### *LLM summary report*',
                '## Summary',
                $Summary,
                '## Topics',
                to-html(
                from-json($TopicsTable.subst(/ ^ '```json' | '```' $/):g),
                        field-names => <theme content>,
                        align => 'left'),
                "## Mind map",
                $MindMap,
                '## Thinking hats',
                $ThinkingHats.subst(/ ^ '```html' | '```' $/):g
            ].join("\n\n")
        }
        }
        ;

#==========================================================
# All rules hashmap
#==========================================================

our %rules =
    text-summarize => %text-summarize
        ;