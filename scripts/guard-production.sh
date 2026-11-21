#!/usr/bin/env bash
#
# PreToolUse guard for the Bash and PowerShell tools: the production lock.
#
# In this way of working, main (or master) is production and only changes
# through a pull request from dev, opened by the versionamento-publicar-prod
# skill when the person asks to publish. Everything else that would change
# production is blocked here, outside the model:
#
#   - saving, merging or replaying versions on main (commit, merge, cherry-pick,
#     revert, am, rebase) once the project has a first version;
#   - sending versions to a main that already exists in the cloud (git push);
#   - opening a pull request into main from any line other than dev/develop.
#
# The lock only applies to projects that have a dev (or develop) line, here or in
# the cloud: that line is the sign that the project has a test environment and a
# production. Without it the repository only keeps the code (or publishes from
# its main line), and nothing is blocked.
#
# Each git command is judged in the repository it actually touches, not in the
# folder of the conversation: "git -C <dir>", "cd <dir>" / "Set-Location <dir>"
# earlier in the same command, and simple variables set earlier in it
# (DIR=...; cd "$DIR") are followed. Heredoc and here-string bodies that only feed
# a file are text, not commands, and are skipped.
#
# The lock is on while this plugin's preferences are on; the preferencias skill
# can turn it off (production-lock.sh off) when the person asks for it.
#
# Exit code 2 blocks the tool call; stderr goes back to Claude as the reason.
# Anything that cannot be parsed is allowed: the guard must never block normal work.

set -u

INPUT="$(cat)"

to_unix_path() {
    if [ -n "$1" ] && command -v cygpath >/dev/null 2>&1; then
        cygpath -u "$1"
    else
        printf '%s' "$1"
    fi
}

# Extracts a top-level string field from the hook JSON without a JSON parser.
# Escaped backslashes are parked first, so "C:\\new" does not turn into a line break.
json_field() {
    printf '%s' "$INPUT" |
        grep -o -E "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" |
        head -n 1 |
        sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//" |
        sed -e 's/\\\\/\x01/g' -e 's/\\n/\n/g' -e 's/\\t/\t/g' -e 's/\\r//g' -e 's/\\"/"/g' -e 's/\x01/\\/g'
}

COMMAND="$(json_field command)"
CWD="$(json_field cwd)"

# Not a git or GitHub CLI command: nothing to check.
printf '%s' "$COMMAND" | grep -Eq '(^|[^[:alnum:]_-])(git|gh)([[:space:]]|$)' || exit 0

block() {
    printf '%s\n' "$1" >&2
    exit 2
}

PRODUCTION_MESSAGE="Bloqueado pelo plugin Fábrica de Asas no Ar: a linha main (ou master) é produção e só recebe versões por um pedido de junção (pull request) vindo da dev, quando a pessoa pede para publicar, como explica a skill fabrica-de-asas-no-ar:versionamento-publicar-prod. Salve as versões num rascunho do assunto (git switch -c <assunto>) e, quando a pessoa pedir para publicar, siga aquela skill. Não tente outro caminho para mudar a main. Explique para a pessoa em linguagem simples, sem jargão de git, o que você ia fazer e o caminho seguro."

# Separator between the tokens of one segment in the lexer output.
SEP=$'\037'

# ---------------------------------------------------------------------------
# CommandLexer: turns the command into segments (split on newlines, ;, &&, ||,
# |, parentheses and braces), one per line, with tokens separated by SEP.
# Quotes are honoured, so a commit message with ";" inside stays one token.
# Backslashes are kept as they are (Windows paths).
# ---------------------------------------------------------------------------

CommandLexer::segments() {
    printf '%s' "$COMMAND" | awk -v SEP="$SEP" '
        BEGIN { RS = "\001" }
        function emit_token() {
            if (has) { segment = (count ? segment SEP : "") token; count++ }
            token = ""; has = 0
        }
        function emit_segment() {
            emit_token()
            if (count) print segment
            segment = ""; count = 0
        }
        {
            # Pass 1: drop heredoc and here-string bodies that only feed a file;
            # keep them when they feed a shell, since then they run.
            lines = split($0, line, "\n"); text = ""; until_word = ""; until_ps = ""
            for (i = 1; i <= lines; i++) {
                current = line[i]; sub(/\r$/, "", current)
                if (until_word != "") {
                    probe = current; if (dash) sub(/^\t+/, "", probe)
                    if (probe == until_word) until_word = ""
                    continue
                }
                if (until_ps != "") {
                    if (index(current, until_ps) == 1) { current = substr(current, 3); until_ps = "" }
                    else continue
                }
                text = text current "\n"
                probe = current; gsub(/<<</, "\002\002\002", probe)
                feeds_shell = (probe ~ /(^|[^[:alnum:]_.\/-])(bash|sh|zsh|dash|ksh|pwsh|powershell)(\.exe)?([ \t]+-[[:alnum:]-]+)*[ \t]*<</)
                if (match(probe, /<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/)) {
                    if (!feeds_shell) {
                        word = substr(probe, RSTART, RLENGTH)
                        dash = (substr(word, 3, 1) == "-")
                        sub(/^<<-?[ \t]*/, "", word); gsub(/["\047]/, "", word)
                        until_word = word
                    }
                } else if (current ~ /@\047[ \t]*$/) {
                    until_ps = "\047@"
                } else if (current ~ /@"[ \t]*$/) {
                    until_ps = "\"@"
                }
            }

            # Pass 2: split into segments and tokens.
            length_text = length(text); token = ""; has = 0; segment = ""; count = 0; quote = ""
            for (i = 1; i <= length_text; i++) {
                c = substr(text, i, 1); next_c = substr(text, i + 1, 1)
                if (quote == "\047") {
                    if (c == "\047") quote = ""; else token = token (c == "\n" ? " " : c)
                    continue
                }
                if (quote == "\"") {
                    if ((c == "\\" || c == "`") && next_c == "\"") { token = token "\""; i++ }
                    else if (c == "\"") quote = ""
                    else token = token (c == "\n" ? " " : c)
                    continue
                }
                if (c == "\047" || c == "\"") { quote = c; has = 1; continue }
                if (c == "#" && !has && (i == 1 || substr(text, i - 1, 1) ~ /[ \t\n;&|(){}]/)) {
                    while (i < length_text && substr(text, i + 1, 1) != "\n") i++
                    continue
                }
                if (c == "\\" && next_c == "\n") { i++; emit_token(); continue }
                if (c == "$" && next_c == "{") {
                    close_at = index(substr(text, i), "}")
                    if (close_at) { token = token substr(text, i, close_at); has = 1; i += close_at - 1; continue }
                }
                if (c == " " || c == "\t") { emit_token(); continue }
                if (c == "&" && (substr(text, i - 1, 1) ~ /[<>]/ || next_c == ">")) { token = token c; has = 1; continue }
                if (c ~ /[\n;&|(){}]/) { emit_segment(); continue }
                token = token c; has = 1
            }
            emit_segment()
        }'
}

# ---------------------------------------------------------------------------
# Workspace: the folder each segment runs in, following cd / Set-Location and
# simple variables set earlier in the same command. An empty DIR means the
# folder can no longer be known; segments after that are not judged.
# ---------------------------------------------------------------------------

declare -A VARS=()
declare -A UNKNOWN_VARS=()
DIR="$(to_unix_path "$CWD")"
[ -n "$DIR" ] || DIR="$PWD"

# Expands $NAME, ${NAME}, $env:NAME and ~ with what is known; fails if something is unknown.
Workspace::expand() {
    local s="$1" whole name value
    case "$s" in
        "~") s="$HOME" ;;
        "~/"* | "~\\"*) s="$HOME/${s:2}" ;;
    esac
    while [[ "$s" =~ \$(\{)?(env:)?([A-Za-z_][A-Za-z0-9_]*)(\})? ]]; do
        whole="${BASH_REMATCH[0]}"
        name="${BASH_REMATCH[3]}"
        if [ -n "${UNKNOWN_VARS[$name]+x}" ]; then
            return 1
        elif [ -n "${VARS[$name]+x}" ]; then
            value="${VARS[$name]}"
        elif [ "$name" = PWD ]; then
            value="$DIR"
        elif [ "$name" != OLDPWD ] && [ -n "${!name+x}" ]; then
            value="${!name}"
        else
            return 1
        fi
        s="${s/"$whole"/$value}"
    done
    printf '%s' "$s"
}

# Resolves a path against a base folder.
Workspace::resolve() {
    local path
    path="$(Workspace::expand "$1")" || return 1
    [ -n "$path" ] && [ -n "$2" ] || return 1
    case "$path" in
        [A-Za-z]:*) path="$(to_unix_path "$path")" ;;
        /*) ;;
        *) path="$2/$path" ;;
    esac
    printf '%s' "$path"
}

Workspace::remember() {
    local value
    if value="$(Workspace::expand "$2")"; then
        VARS[$1]="$value"
        unset 'UNKNOWN_VARS[$1]'
    else
        UNKNOWN_VARS[$1]=1
        unset 'VARS[$1]'
    fi
}

# Handles segments that change the folder or set a variable; returns 0 when it did.
Workspace::track() {
    local first="${TOKENS[0]:-}" n=${#TOKENS[@]} i target=""
    case "${first,,}" in
        cd | pushd | chdir | set-location | sl | push-location)
            i=1
            while [ "$i" -lt "$n" ]; do
                case "${TOKENS[$i],,}" in
                    -path | -literalpath) target="${TOKENS[$((i + 1))]:-}"; break ;;
                    -l | -p | -e | -@ | --) ;;
                    *) target="${TOKENS[$i]}"; break ;;
                esac
                i=$((i + 1))
            done
            if [ -z "$target" ]; then
                DIR="$HOME"
            elif [ "$target" = "-" ]; then
                DIR=""
            else
                DIR="$(Workspace::resolve "$target" "$DIR")" || DIR=""
            fi
            return 0
            ;;
        popd | pop-location)
            DIR=""
            return 0
            ;;
        export | declare | local | typeset | readonly)
            [ "$n" -eq 2 ] && [[ "${TOKENS[1]}" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || return 1
            Workspace::remember "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
            return 0
            ;;
    esac
    # NAME=value alone (a NAME=value before a command only applies to that command).
    if [ "$n" -eq 1 ] && [[ "$first" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        Workspace::remember "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        return 0
    fi
    # PowerShell: $name = value
    if [[ "$first" =~ ^\$([A-Za-z_][A-Za-z0-9_]*)$ ]] && [ "${TOKENS[1]:-}" = "=" ] && [ "$n" -eq 3 ]; then
        Workspace::remember "${BASH_REMATCH[1]}" "${TOKENS[2]}"
        return 0
    fi
    return 1
}

# ---------------------------------------------------------------------------
# Production lock
#
# Segments are read in order, so a "git switch main && git merge dev" is judged
# on the branch it switches to, in the repository it runs in.
# ---------------------------------------------------------------------------

declare -A BRANCH_OF=()
declare -A WORK_LINE_OF=()
REPO=""
BRANCH=""

git_here() {
    git -C "$REPO" "$@" 2>/dev/null
}

# On unless this plugin's preferences are off or the person turned the lock off.
ProductionLock::enabled() {
    local data_dir
    data_dir="$(to_unix_path "${CLAUDE_PLUGIN_DATA:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/data/fabrica-de-asas-no-ar-fabricadeasas}")"
    if [ -f "$data_dir/config" ] && tr -d '\r' < "$data_dir/config" | grep -Eq '^preferences=off$'; then
        return 1
    fi
    if [ -f "$data_dir/production_lock" ] && [ "$(tr -d '\r\n' < "$data_dir/production_lock")" = off ]; then
        return 1
    fi
    return 0
}

# The repository works with a test line (dev/develop), locally or on any remote.
ProductionLock::has_work_line() {
    if [ -z "${WORK_LINE_OF[$REPO]+x}" ]; then
        if git_here for-each-ref --format='%(refname)' refs/heads refs/remotes |
            grep -Eq '^refs/(heads|remotes/[^/]+)/(dev|develop)$'; then
            WORK_LINE_OF[$REPO]=yes
        else
            WORK_LINE_OF[$REPO]=no
        fi
    fi
    [ "${WORK_LINE_OF[$REPO]}" = yes ]
}

ProductionLock::is_production() {
    case "${1#refs/heads/}" in
        main | master) return 0 ;;
        *) return 1 ;;
    esac
}

ProductionLock::is_work_line() {
    case "${1#*:}" in
        dev | develop) return 0 ;;
        *) return 1 ;;
    esac
}

# The branch exists in the cloud already (pushing it for the first time is allowed).
ProductionLock::remote_has() {
    git_here rev-parse --verify -q "refs/remotes/$1/${2#refs/heads/}" >/dev/null
}

ProductionLock::has_history() {
    git_here rev-parse --verify -q HEAD >/dev/null
}

# Finds git/gh in TOKENS; sets TOOL, SUB_INDEX (index of the subcommand) and
# SEGMENT_DIR (the folder after any "git -C <dir>"). Fails when there is nothing
# to judge or the folder cannot be known.
ProductionLock::parse() {
    TOOL=""
    SUB_INDEX=-1
    SEGMENT_DIR="$DIR"
    local i=0 n=${#TOKENS[@]} name
    while [ "$i" -lt "$n" ]; do
        name="${TOKENS[$i]##*[/\\]}"
        name="${name%.exe}"
        case "$name" in
            git | gh) TOOL="$name"; break ;;
        esac
        i=$((i + 1))
    done
    [ -n "$TOOL" ] || return 1
    i=$((i + 1))
    while [ "$i" -lt "$n" ]; do
        case "${TOKENS[$i]}" in
            -C)
                [ "$TOOL" = git ] || { i=$((i + 2)); continue; }
                SEGMENT_DIR="$(Workspace::resolve "${TOKENS[$((i + 1))]:-}" "$SEGMENT_DIR")" || return 1
                i=$((i + 2))
                ;;
            -c | -R | --repo) i=$((i + 2)) ;;
            -*) i=$((i + 1)) ;;
            *) SUB_INDEX=$i; break ;;
        esac
    done
    [ "$SUB_INDEX" -ge 0 ] && [ -n "$SEGMENT_DIR" ]
}

# Points REPO and BRANCH at the repository the segment touches; fails outside a repository.
ProductionLock::enter_repo() {
    REPO="$(git -C "$SEGMENT_DIR" rev-parse --show-toplevel 2>/dev/null)" || return 1
    [ -n "$REPO" ] || return 1
    if [ -z "${BRANCH_OF[$REPO]+x}" ]; then
        BRANCH_OF[$REPO]="$(git_here branch --show-current)"
    fi
    BRANCH="${BRANCH_OF[$REPO]}"
}

# Value of an option given as "--name value", "--name=value" or "-x value".
ProductionLock::option() {
    local long="$1" short="$2" i=$((SUB_INDEX + 1)) n=${#TOKENS[@]}
    while [ "$i" -lt "$n" ]; do
        case "${TOKENS[$i]}" in
            "$long"=*) printf '%s' "${TOKENS[$i]#*=}"; return 0 ;;
            "$long" | "$short") printf '%s' "${TOKENS[$((i + 1))]:-}"; return 0 ;;
        esac
        i=$((i + 1))
    done
    return 1
}

ProductionLock::check_push() {
    local i=$((SUB_INDEX + 1)) n=${#TOKENS[@]} token remote="" refspecs=() tags_only=no dst
    while [ "$i" -lt "$n" ]; do
        token="${TOKENS[$i]}"
        case "$token" in
            --all | --branches) block "$PRODUCTION_MESSAGE" ;;
            --tags) tags_only=yes ;;
            -o | --push-option | --repo | --receive-pack | --exec) i=$((i + 1)) ;;
            -*) ;;
            *) if [ -z "$remote" ]; then remote="$token"; else refspecs+=("$token"); fi ;;
        esac
        i=$((i + 1))
    done
    remote="${remote:-origin}"
    if [ ${#refspecs[@]} -eq 0 ]; then
        [ "$tags_only" = yes ] && return 0
        refspecs=("$BRANCH")
    fi
    for token in "${refspecs[@]}"; do
        dst="${token#+}"
        dst="${dst##*:}"
        [ "$dst" = "HEAD" ] && dst="$BRANCH"
        if ProductionLock::is_production "$dst" && ProductionLock::remote_has "$remote" "$dst"; then
            block "$PRODUCTION_MESSAGE"
        fi
    done
}

ProductionLock::check_pr_create() {
    local base head
    base="$(ProductionLock::option --base -B)" || base="$(git_here symbolic-ref --short refs/remotes/origin/HEAD)"
    base="${base#origin/}"
    base="${base:-main}"
    ProductionLock::is_production "$base" || return 0
    head="$(ProductionLock::option --head -H)" || head="$BRANCH"
    ProductionLock::is_work_line "$head" || block "$PRODUCTION_MESSAGE O pedido de junção para a main tem que sair da dev (gh pr create --base main --head dev)."
}

# Follows a branch change made by switch/checkout.
ProductionLock::track_switch() {
    local sub="$1" target
    if target="$(ProductionLock::option --create -c)" ||
        target="$(ProductionLock::option --force-create -C)" ||
        target="$(ProductionLock::option --orphan --orphan)" ||
        { [ "$sub" = checkout ] && { target="$(ProductionLock::option -b -b)" || target="$(ProductionLock::option -B -B)"; }; }; then
        BRANCH="$target"
    elif printf ' %s ' "${TOKENS[*]:$((SUB_INDEX + 1))}" | grep -Eq '[[:space:]](--|\.)[[:space:]]'; then
        : # checkout of files: the branch does not change
    else
        # The last argument is the branch; "-" means the previous one, which is unknown here.
        target="${TOKENS[${#TOKENS[@]} - 1]}"
        case "$target" in
            -) BRANCH="" ;;
            -* | "$sub") ;;
            *) BRANCH="$target" ;;
        esac
    fi
    BRANCH_OF[$REPO]="$BRANCH"
}

ProductionLock::check_segment() {
    ProductionLock::parse || return 0
    ProductionLock::enter_repo || return 0
    ProductionLock::has_work_line || return 0
    local sub="${TOKENS[$SUB_INDEX]}"
    if [ "$TOOL" = gh ]; then
        [ "$sub" = pr ] && [ "${TOKENS[$((SUB_INDEX + 1))]:-}" = create ] && ProductionLock::check_pr_create
        return 0
    fi
    case "$sub" in
        switch | checkout) ProductionLock::track_switch "$sub" ;;
        push) ProductionLock::check_push ;;
        commit | merge | cherry-pick | revert | am | rebase)
            printf ' %s ' "${TOKENS[*]}" | grep -Eq '[[:space:]]--(abort|quit)[[:space:]]' && return 0
            if ProductionLock::is_production "$BRANCH" && ProductionLock::has_history; then
                block "$PRODUCTION_MESSAGE"
            fi
            ;;
    esac
}

ProductionLock::check_command() {
    local segment
    while IFS= read -r segment; do
        IFS="$SEP" read -r -a TOKENS <<< "$segment"
        [ ${#TOKENS[@]} -gt 0 ] || continue
        Workspace::track && continue
        ProductionLock::check_segment
    done < <(CommandLexer::segments)
}

ProductionLock::enabled || exit 0
ProductionLock::check_command
exit 0
