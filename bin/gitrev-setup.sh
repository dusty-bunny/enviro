#!/bin/bash

# shellcheck disable=2034
# YLWBLU='\033[1;33;44m'
# shellcheck disable=2034
# YLWltBLU='\033[1;33;46m'
# shellcheck disable=2034
YLWGRN='\033[1;33;42m'
# shellcheck disable=2034
YELLOW="\033[1;33m"
# shellcheck disable=2034
GREEN="\033[1;32m"
RESET='\033[0;39;49m'
# DEBUG=${DEBUG:-0}
declare -A git_review
# [ -f ~/bin/colors ] && source ~/bin/colors
# [ -z "${RED}" ] && echo "No color support"

am_I_lost()
{
        if  xtest="$(git rev-parse --is-inside-git-dir 2>/dev/null)" 2>/dev/null && [ "$xtest" = "true" ] ; then
                #
                # Take our path and strip off everything from .git on down.
                Here="$(pwd)"
                cd "${Here%.git/*}" || exit 2
        elif xtest="$(git rev-parse --is-inside-work-tree 2>/dev/null)" 2>/dev/null && [ "$xtest" = "false" ] ; then
                echo "==== A::a"
                exit
        else
                echo "I have no idea where I am." >&2
                exit 1
        fi
}

GERRIT_HOST_IP="${GERRIT_HOST_IP:-"101.132.142.37"}"
GERRIT_HOST_PORT="${GERRIT_HOST_PORT:-"30149"}"
GERRIT_USER="${GERRIT_USER:-"bill"}"
# shellcheck disable=2207
Repo=( $(git remote -v | grep fetch | awk -F'/' '{print $NF}') )
Local_Branch="$(git branch | awk '{print $2}' | tr -d [:space:])"
Repo_Branch=( $(git branch -vv | grep $Local_Branch | sed -e 's/^.*\[\([^:]*\):.*/\1/' | awk -F'/' '{print $1 " " $2}') )
GERRIT_REPO="${Repo[0]}"
GERRIT_REPO_BRANCH="${GERRIT_REPO_BRANCH:-${Repo_Branch[1]}}"
LOCAL_REMOTE_NAME="${LOCAL_REMOTE_NAME:-${Repo_Branch[0]}}"
GERRIT_XFER_PROTO="${GERRT_XFER_PROTO:-"ssh"}"

setup_gitreview()
{
	git_review["section"]="gitreview"
	git_review["host"]="$GERRIT_HOST_IP"
	git_review["port"]="$GERRIT_HOST_PORT"
	git_review["username"]="$GERRIT_USER"
	git_review["project"]="$GERRIT_REPO"
	git_review["branch"]="$GERRIT_REPO_BRANCH"
	git_review["remote"]="$LOCAL_REMOTE_NAME"
	git_review["scheme"]="$GERRIT_XFER_PROTO"
}

print_gitrev_config()
{
        echo -e "===== Config ========="
	echo -e "section:\\t${git_review["section"]}"
	echo -e "host:\\t\\t${git_review["host"]}"
	echo -e "port:\\t\\t${git_review["port"]}"
	echo -e "username:\\t${git_review["username"]}"
	echo -e "project:\\t${git_review["project"]}"
	echo -e "branch:\\t\\t${git_review["branch"]}"
	echo -e "remote:\\t\\t${git_review["remote"]}"
	echo -e "scheme:\\t\\t${git_review["scheme"]}"
        echo -e "=====        ========="
}

print_section_defaults()
{
        local Key=

        echo ""
        for Key in "${!git_review[@]}" ; do
                echo -e "Key: ${GREEN}$Key,\\t${YELLOW}${git_review[$Key]}${RESET}"
        done
        echo ""
}

print_section_config()
{
        git config --local --get-regexp "gitreview.*" | sed -e 's/^/\t/'
}

print_array()
{
        declare -a Array=
        local Last=
        local Count=

        Name="$1"; shift
        Count=0
        Array=( "$@" )
        Last="${#Array[@]}"
        echo "==="
        echo "Array: ($Name)"
        while [ "$Count" -ne "$Last" ] ; do
                echo "Array[$Count]: ${Array[$Count]}"
                Count=$(( Count + 1 ))
        done
        echo "==="
}

#
# Sift through all local branches reported and find which one
# is the current branch.  Output that name and return.
#
current_branch()
{
        # shellcheck disable=2162
        git branch | while read one two; do
                [ -z "$two" ] && continue
                [ "$one" = "*" ] && echo "$two" && break
        done
}

help()
{
        # shellcheck disable=2086
        sed -n -e '/^#Help/,/^#Help/p' $0 | grep -v ^#Help | grep -v ";;"
}

while [ $# -ne 0 ] ; do
        case "$1" in
#Help Start
        --env) PRINT_ENV="yes" # Print the internal default environment to use.
        ;;
        -e | --edit) git config --local --edit ; exit 0
        ;;
        -h | --help) help && exit 0
        ;;
        -l | --list) PRINT_CURRENT_CONFIG=yes     # Print current settings for the repo.
        ;;
        -r) # Remove the gitreview config info/section.
            git config --local --remove-section gitreview
            exit 0
        ;;
        *)  echo "I have no idea what that argument ($1) means.";
            exit 1
        ;;
#Help End
        esac
        shift
done

setup_gitreview

[ "$PRINT_CURRENT_CONFIG" = "yes" ] && print_section_config && exit
[ "$PRINT_ENV" = "yes" ] && print_section_defaults && exit


[ "$DEBUG" = "1" ] && \
        msg="${YLWBLU}DEBUG mode: ($DEBUG), no changes  will be made.${RESET}"
        echo -e "$msg" >&2
#
# Set a config section for git to setup git-review
#
Section="${git_review["section"]}"
for Key in "${!git_review[@]}" ; do
        Cmd="git config --local $Section.$Key ${git_review["$Key"]}"
        [ "$DEBUG" = "1" ] && echo "  $Cmd" && continue
        $Cmd
done
