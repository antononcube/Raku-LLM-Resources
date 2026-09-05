use v6.d;

use JSON::Fast;

#| Validate directories which implement the Agent Skills specification.
#|
#| The validator follows the reference implementation at
#| https://github.com/agentskills/agentskills/tree/main/skills-ref. Validation
#| methods return an Array of error messages; an empty Array means valid.
class LLM::Resources::AgentSkillValidator {
    our constant MAX-SKILL-NAME-LENGTH = 64;
    our constant MAX-DESCRIPTION-LENGTH = 1024;
    our constant MAX-COMPATIBILITY-LENGTH = 500;
    our constant ALLOWED-FIELDS = Set.new(
            <name description license allowed-tools metadata compatibility>
    );

    #| Validate a complete Agent Skill directory.
    proto method validate(Str:D $skill-dir --> Array:D) {*}

    multi method validate(Str:D $skill-dir --> Array:D) {
        if $skill-dir.IO.d {
            return self.validate($skill-dir.IO)
        }
        die 'The first argument is expected to be valid directory.'
    }

    multi method validate(IO::Path:D $skill-dir --> Array:D) {
        my $dir = $skill-dir.IO;
        my @errors = self.validate-structure($dir);
        return @errors if @errors;

        my %parsed = self.parse-skill-file($dir);
        return %parsed<errors>.Array if %parsed<errors>.elems;

        self.validate-content(%parsed<metadata>, :skill-dir($dir));
    }

    #| Return True when the supplied directory is a valid Agent Skill.
    proto method is-valid(IO::Path:D $skill-dir --> Bool:D) {*}

    multi method is-valid(Str:D $skill-dir --> Bool:D) {
        if $skill-dir.IO.d {
            return self.is-valid($skill-dir.IO)
        }
        die 'The first argument is expected to be valid directory.'
    }

    multi method is-valid(IO::Path:D $skill-dir --> Bool:D) {
        self.validate($skill-dir).elems == 0
    }

    #| Validate the directory and the presence of SKILL.md.
    method validate-structure(IO::Path:D $skill-dir --> Array:D) {
        my $dir = $skill-dir.IO;
        return ["Path does not exist: $dir"] unless $dir.e;
        return ["Not a directory: $dir"] unless $dir.d;
        return ['Missing required file: SKILL.md'] unless self.find-skill-md($dir).defined;
        return []
    }

    #| Validate that SKILL.md contains well-formed YAML frontmatter.
    method validate-format(IO::Path:D $skill-dir --> Array:D) {
        my @errors = self.validate-structure($skill-dir);
        return @errors if @errors;
        return self.parse-skill-file($skill-dir.IO)<errors>.Array
    }

    #| Validate already parsed frontmatter metadata.
    method validate-content(
            Associative:D $metadata,
            IO::Path:D :$skill-dir
            --> Array:D
    ) {
        my @errors;
        my @extra = $metadata.keys.grep({ $_ !(elem) ALLOWED-FIELDS }).sort;
        if @extra {
            my $allowed = ALLOWED-FIELDS.keys.sort.map({ "'$_'" }).join(', ');
            @errors.push(
                    "Unexpected fields in frontmatter: {@extra.join(', ')}. " ~
                    "Only [$allowed] are allowed."
            );
        }

        if $metadata<name>:exists {
            @errors.append(|self.validate-name($metadata<name>, :$skill-dir));
        } else {
            @errors.push('Missing required field in frontmatter: name');
        }

        if $metadata<description>:exists {
            @errors.append(|self.validate-description($metadata<description>));
        } else {
            @errors.push('Missing required field in frontmatter: description');
        }

        if $metadata<compatibility>:exists {
            @errors.append(|self.validate-compatibility($metadata<compatibility>));
        }

        @errors.Array
    }

    #| Alias for validate-content, matching skills-ref terminology.
    method validate-metadata(
            Associative:D $metadata,
            IO::Path:D :$skill-dir
            --> Array:D
    ) {
        self.validate-content($metadata, :$skill-dir)
    }

    #| Validate a skill name and, optionally, its containing directory name.
    method validate-name(Mu $value, IO::Path:D :$skill-dir --> Array:D) {
        return ["Field 'name' must be a non-empty string",]
        unless $value ~~ Str:D && $value.trim.chars;

        # Raku strings use Normalization Form Grapheme internally, so
        # canonically equivalent spellings compare equal.
        my $name = $value.trim;
        my @errors;

        if $name.chars > MAX-SKILL-NAME-LENGTH {
            @errors.push(
                    "Skill name '$name' exceeds {MAX-SKILL-NAME-LENGTH} " ~
                    "character limit ({$name.chars} chars)"
            );
        }

        @errors.push("Skill name '$name' must be lowercase") if $name ne $name.lc;

        @errors.push('Skill name cannot start or end with a hyphen')
        if $name.starts-with('-') || $name.ends-with('-');

        @errors.push('Skill name cannot contain consecutive hyphens')
        if $name.contains('--');

        with $name.comb.first({ $_ ne '-' && $_ !~~ /^ <:L+:N>+ $/ }) {
            @errors.push(
                    "Skill name '$name' contains invalid characters. " ~
                    'Only letters, digits, and hyphens are allowed.'
            );
        }

        with $skill-dir {
            my $directory-name = $skill-dir.IO.basename;
            if $directory-name ne $name {
                @errors.push(
                        "Directory name '$directory-name' must match skill name '$name'"
                );
            }
        }

        @errors.Array
    }

    #| Validate the required skill description.
    method validate-description(Mu $description --> Array:D) {
        return ["Field 'description' must be a non-empty string",]
        unless $description ~~ Str:D && $description.trim.chars;
	
        return [
            "Description exceeds {MAX-DESCRIPTION-LENGTH} character limit " ~
            "({$description.chars} chars)"
        ] if $description.chars > MAX-DESCRIPTION-LENGTH;
        []
    }

    #| Validate the optional compatibility declaration.
    method validate-compatibility(Mu $compatibility --> Array:D) {
        return ["Field 'compatibility' must be a string",]
        unless $compatibility ~~ Str:D;
	
        return [
            "Compatibility exceeds {MAX-COMPATIBILITY-LENGTH} character limit " ~
            "({$compatibility.chars} chars)"
        ] if $compatibility.chars > MAX-COMPATIBILITY-LENGTH;
        []
    }

    #| Locate the conventional skill file. Uppercase is preferred, while the
    #| lowercase spelling accepted by skills-ref is supported for compatibility.
    method find-skill-md(IO::Path:D $skill-dir --> Mu) {
        for <SKILL.md skill.md> -> $name {
            my $candidate = $skill-dir.IO.add($name);
            return $candidate if $candidate.f;
        }
        Nil
    }

    #| Parse the metadata of the skill file YAML header.
    #| The returned Hash has 'name' nad 'description' entries.
    proto method parse-frontmatter(Str:D $content --> Hash:D) {*}

    multi method parse-frontmatter(IO::Path:D $dir --> Hash:D) {
        my $file = self.find-skill-md($dir);
        return self.parse-frontmatter($file.slurp) with $file;
        Nil
    }

    multi method parse-frontmatter(Str:D $content --> Hash:D) {
        self!parse-content($content)<metadata>
    }

    #| Parse SKILL.md file.
    #| The returned Hash has 'metadata', 'body', and 'errors' entries.
    method parse-skill-file(IO::Path:D $skill-dir --> Hash:D) {
        my $skill-md = self.find-skill-md($skill-dir);
        my $content;
        try {
            $content = $skill-md.slurp;
            CATCH {
                default {
                    return {
                        metadata => {}, body => '',
                        errors => ["Cannot read $skill-md: {$_.message}",]
                    };
                }
            }
        }
        self!parse-content($content)
    }

    method !parse-content(Str:D $content --> Hash:D) {
        my $text = $content.subst("\r\n", "\n", :g).subst("\r", "\n", :g);
        my @lines = $text.split("\n", :skip-empty(False));

        return self!parse-error('SKILL.md must start with YAML frontmatter (---)') unless @lines.elems && @lines[0] ~~ / ^ '-' ** 3..* \h* /;

        my $close = (1 ..^ @lines.elems).first({ @lines[$_] ~~ / ^ '-' ** 3..* \h* / });
        return self!parse-error('SKILL.md frontmatter not properly closed with ---') unless $close.defined;

        my @yaml = @lines[1 ..^ $close];
        my $body = @lines[$close + 1 .. *].join("\n").trim;
        my %metadata;
        my @errors;
        my $i = 0;

        while $i < @yaml.elems {
            my $line = @yaml[$i];
            $i++;
            next if $line.trim eq '' || $line.trim.starts-with('#');

            if $line.contains("\t") {
                @errors.push("Invalid YAML in frontmatter: tabs are not allowed (line {$i + 1})");
                next;
            }
            if $line ~~ /^ \s / {
                @errors.push("Invalid YAML in frontmatter: unexpected indentation (line {$i + 1})");
                next;
            }

            my $match = $line.match(/^ (<-[\s:]>+) \s* ':' (.*) $/);
            unless $match {
                @errors.push("Invalid YAML in frontmatter: expected 'key: value' (line {$i + 1})");
                next;
            }

            my $key = ~$match[0];
            my $raw = (~$match[1]).trim;
            if %metadata{$key}:exists {
                @errors.push("Invalid YAML in frontmatter: duplicate key '$key'");
                next;
            }

            if $raw ~~ /^ <[|>]> <[+-]>? $/ {
                my $style = $raw.substr(0, 1);
                my @block;
                while $i < @yaml.elems {
                    my $next = @yaml[$i];
                    last if $next.trim.chars && $next !~~ /^ \s /;
                    @block.push($next);
                    $i++;
                }
                my @nonempty = @block.grep(*.trim.chars);
                my $indent = @nonempty.elems
                        ?? @nonempty.map({ .chars - .trim-leading.chars }).min
                        !! 0;
                my @values = @block.map({ .chars >= $indent ?? .substr($indent) !! '' });
                %metadata{$key} = $style eq '|'
                        ?? @values.join("\n")
                        !! @values.join("\n").split(/ \n ** 2 /)
                                .map({ .subst("\n", ' ', :g) }).join("\n\n");
                next;
            }

            if $raw eq '' {
                my %mapping;
                while $i < @yaml.elems && (@yaml[$i].trim eq '' || @yaml[$i] ~~ /^ \s /) {
                    my $nested = @yaml[$i];
                    $i++;
                    next if $nested.trim eq '' || $nested.trim.starts-with('#');
                    if $nested.contains("\t") {
                        @errors.push("Invalid YAML in frontmatter: tabs are not allowed (line {$i + 1})");
                        next;
                    }
                    my $nested-match = $nested.match(/^ \s+ (<-[\s:]>+) \s* ':' (.*) $/);
                    unless $nested-match {
                        @errors.push("Invalid YAML in frontmatter: expected a mapping (line {$i + 1})");
                        next;
                    }
                    my $nested-key = ~$nested-match[0];
                    if %mapping{$nested-key}:exists {
                        @errors.push("Invalid YAML in frontmatter: duplicate key '$nested-key'");
                        next;
                    }
                    my %scalar = self!parse-scalar((~$nested-match[1]).trim, $i + 1);
                    @errors.append(|%scalar<errors>);
                    %mapping{$nested-key} = %scalar<value> unless %scalar<errors>.elems;
                }
                %metadata{$key} = %mapping;
                next;
            }

            my %scalar = self!parse-scalar($raw, $i + 1);
            @errors.append(|%scalar<errors>);
            %metadata{$key} = %scalar<value> unless %scalar<errors>.elems;
        }

        return self!parse-error(@errors.join('; ')) if @errors;
        return { metadata => %metadata, body => $body, errors => [] }
    }

    method !parse-scalar(Str:D $raw is copy, Int:D $line --> Hash:D) {
        if $raw.starts-with("'") {
            unless $raw.chars >= 2 && $raw.ends-with("'") {
                return {
                    value => Any,
                    errors => ["Invalid YAML in frontmatter: unterminated quoted value (line $line)",]
                };
            }
            return { value => $raw.substr(1, $raw.chars - 2).subst("''", "'", :g), errors => [] };
        }
        if $raw.starts-with('"') {
            unless $raw.chars >= 2 && $raw.ends-with('"') {
                return {
                    value => Any,
                    errors => ["Invalid YAML in frontmatter: unterminated quoted value (line $line)",]
                };
            }
            my $value;
            my $error;
            $value = from-json($raw);

            with $error {
                return {
                    value => Any,
                    errors => ["Invalid YAML in frontmatter: invalid quoted value (line $line)",]
                };
            }
            return { :$value, errors => [] }
        }

        # Strip a YAML comment only when its # is preceded by whitespace.
        $raw ~~ s/ \s+ '#' .* $//;
        $raw = $raw.trim;
        if $raw.starts-with('[') || $raw.starts-with('{') || $raw.starts-with('- ') {
            return {
                value => Any,
                errors => ["Invalid YAML in frontmatter: expected a scalar value (line $line)",]
            }
        }
        return { value => $raw, errors => [] }
    }

    method !parse-error(Str:D $message --> Hash:D) {
        return { metadata => {}, body => '', errors => [$message,] }
    }

}
