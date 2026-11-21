#!/usr/bin/env bash
#
# PreToolUse guard for the Bash and PowerShell tools: the production lock.
#
# In this way of working, main (or master) is production and only changes
# through a pull request from dev, opened by the versionamento-publicar-prod
# skill after an alert and the person's yes. Everything else that would change
# production is blocked here, outside the model:
#
#   - saving, merging or replaying versions on main (commit, merge, cherry-pick,
#     revert, am, rebase) once the project has a first version;
#   - sending versions to a main that already exists in the cloud (git push);
#   - opening a pull request into main from any line other than dev/develop.
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
json_field() {
    printf '%s' "$INPUT" |
        grep -o -E "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" |
        head -n 1 |
        sed -E "s/^\"$1\"[[:space:]]*:[[:space:]]*\"//; s/\"\$//" |
        sed -e 's/\\"/"/g' -e 's/\\\\/\\/g'
}

COMMAND="$(json_field command)"
CWD="$(json_field cwd)"

# Not a git or GitHub CLI command: nothing to check.
printf '%s' "$COMMAND" | grep -Eq '(^|[^[:alnum:]_-])(git|gh)([[:space:]]|$)' || exit 0

git_here() {
    if [ -n "$CWD" ]; then
        git -C "$CWD" "$@" 2>/dev/null
    else
        git "$@" 2>/dev/null
    fi
}

block() {
    printf '%s\n' "$1" >&2
    exit 2
}

PRODUCTION_MESSAGE="Bloqueado pelo plugin Fábrica de Asas no Ar: a linha main (ou master) é produção e só recebe versões por um pedido de junção (pull request) vindo da dev, quando a pessoa pediu para publicar em produção, como explica a skill fabrica-de-asas-no-ar:versionamento-publicar-prod. Salve e mande as versões na dev (git switch dev; se ela não existe, git switch -c dev) e, para publicar, siga aquela skill. Não tente outro caminho para mudar a main. Explique para a pessoa em linguagem simples, sem jargão de git, o que você ia fazer e o caminho seguro."

# ---------------------------------------------------------------------------
# Production lock
#
# The command is split into segments (&&, ||, ;, |) and read in order, so a
# "git switch main && git merge dev" is judged on the branch it switches to.
# ---------------------------------------------------------------------------

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

# Splits a segment into TOKENS; sets TOOL (git|gh) and SUB_INDEX (index of the subcommand).
ProductionLock::parse() {
    read -r -a TOKENS <<< "$1"
    TOOL=""
    SUB_INDEX=-1
    local i=0 n=${#TOKENS[@]} name
    while [ "$i" -lt "$n" ]; do
        name="${TOKENS[$i]##*/}"
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
            -C | -c | -R | --repo) i=$((i + 2)) ;;
            -*) i=$((i + 1)) ;;
            *) SUB_INDEX=$i; return 0 ;;
        esac
    done
    return 1
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

ProductionLock::check_segments() {
    BRANCH="$(git_here branch --show-current)"
    local segment sub target
    while IFS= read -r segment; do
        ProductionLock::parse "$segment" || continue
        sub="${TOKENS[$SUB_INDEX]}"
        if [ "$TOOL" = gh ]; then
            [ "$sub" = pr ] && [ "${TOKENS[$((SUB_INDEX + 1))]:-}" = create ] && ProductionLock::check_pr_create
            continue
        fi
        case "$sub" in
            switch | checkout)
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
                ;;
            push) ProductionLock::check_push ;;
            commit | merge | cherry-pick | revert | am | rebase)
                printf '%s' "$segment" | grep -Eq '[[:space:]]--(abort|quit)([[:space:]]|$)' && continue
                if ProductionLock::is_production "$BRANCH" && ProductionLock::has_history; then
                    block "$PRODUCTION_MESSAGE"
                fi
                ;;
        esac
    done < <(printf '%s\n' "$COMMAND" | sed -E 's/(&&|\|\||;|\|)/\n/g')
}

ProductionLock::enabled || exit 0
ProductionLock::check_segments
exit 0
