#!/usr/bin/env zsh
setopt extendedglob
typeset SCRIPT_VERSION="0.1"
die() > /dev/stderr { print -- "FAIL: $1"; exit 1 }
script-header() > /dev/stderr { print -- "Jsonizsh - A Kind of Json API for ZSH - Version $SCRIPT_VERSIONj""$1" }
script-usage()  > /dev/stderr {
    script-header "Usage: eval \"${${${(%):-%x}:a}t} json-file assosciation-name [-l]\""'

    Parameters:
        json-file   - The JSON file to parse -- use =() in zsh
        -l          - Declare the variables local rather than global'
    [[ -z "${1:-}" ]] && exit 0 || die "$1"
}

typeset -g SCRIPT_PATH="${${(%):-%x}:A}"
typeset -g SCRIPT_NAME="${${${(%):-%x}:t}:A:t}"
typeset -g TARGET_JSON="$1"; [[ -e "$1" ]] || die "The file, $1, does not exist"
shift

call-jq() { "${SCRIPT_PATH:h}/jq/tozsh.jq" "$TARGET_JSON" }
() {
    local -a jq_arr_result=( ); jq_arr_result=( "${(f@)$(call-jq)}" ) || die "Unable to parse JSON response"
    [[ -n "$jq_arr_result" ]] || { print -- "declare -gA $1=( )"; exit 1 }
    local -A jq_assoc_result=( "${(@)jq_arr_result}" )
    local -i FIELD_WIDTH=${#${(O@)${(k@)jq_assoc_result}//?/X}[1]}
    print "typeset -gA $1=( "
    printf "    %-${FIELD_WIDTH}s  %s"$'\n' "${(@)jq_arr_result[@]}"
    print \)

    print "typeset -ga $1_arrays=("
    printf "    %s"$'\n' "${(on)${(kM@)jq_assoc_result:#*.length}[@]%.length}"
    print \)
} "$@"
