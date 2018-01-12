#!/bin/bash

DEBUG=${DEBUG:-0}
declare -A git_review

am_I_lost()
{
        if  xtest="$(git rev-parse --is-inside-git-dir 2>/dev/null)" 2>/dev/null && [ "$xtest" = "true" ] ; then
                #
                # Take our path and strip off everything from .git on down.
                Here="$(pwd)"
                cd "${Here%.git/*}"
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
Repo=( $(git remote -v | grep fetch | awk -F'/' '{print $NF}') )
echo "Repo Repo Repo: ($Repo)"
GERRIT_REPO="${Repo[0]}"
GERRIT_REPO_BRANCH="${GERRIT_REPO_BRANCH:-"zdk"}"
LOCAL_REMOTE_NAME="${LOCAL_REMOTE_NAME:-"origin"}"
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
	echo -e "section:\t${git_review["section"]}"
	echo -e "host:\t\t${git_review["host"]}"
	echo -e "port:\t\t${git_review["port"]}"
	echo -e "username:\t${git_review["username"]}"
	echo -e "project:\t${git_review["project"]}"
	echo -e "branch:\t\t${git_review["branch"]}"
	echo -e "remote:\t\t${git_review["remote"]}"
	echo -e "scheme:\t\t${git_review["scheme"]}"
        echo -e "=====        ========="
}

print_section()
{
        local Key=

        echo ""
        for Key in ${!git_review[@]} ; do
                echo -e "Key: $Key,\t${git_review[$Key]}"
        done
        echo ""
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
        git branch | while read one two; do
                [ -z "$two" ] && continue
                [ "$one" = "*" ] && echo "$two" && break
        done
}

extract_environs()
{
        local User=
        local Envars=

        GERRIT_REPO_BRANCH=$(current_branch)
        Envars=( $(git remote -v | grep fetch | awk  '{ print  $1 " "  $2 " " $3 " " $NF}') )
        print_array Envars "${Envars[@]}"
        LOCAL_REMOTE_NAME="${Envars[0]}"
        URI="${Envars[1]}"
        print_array URI "${URI[@]}"
        URL=( $(echo $URI | awk -F'/' '{print NF  " " $1" "  $NF }') )
        print_array URI "${URI[@]}"
        INDEX=$(( ${#URL[@]} - 1 ))
        User="$(git config --global user.email)"
        GERRIT_USER="${User%@*}"
        GERRIT_REPO="${URL[$INDEX]}"
        INDEX=$(( INDEX - 1 ))
        Repo="${URL[$INDEX]}" && echo "Repo: (${Repo[@]})"
#       echo "Envars[1]:  (${Envars[1]})"
#       GERRIT_XFER_PROTO=( $(echo ${Envars[1]} | awk -F'/' '{print $1 " " $2 " " $(NF-1) " " $NF " " NF}') )
        print_array URL "${URL[@]}"
}

while [ $# -ne 0 ] ; do
        case "$1" in
        -l | --list) PRINT_VARS=yes
        ;;
        *) echo "I have no idea what that argument ($1) means.";
            exit 1
        ;;
        esac
        shift
done

setup_gitreview
[ "$PRINT_VARS" = "yes" ] && print_section && exit


[ "$DEBUG" = "1" ] && echo "DEBUG is on: ($DEBUG)" >&2
#
# Set a config section for git to setup git-review
#
Section="${git_review["section"]}"
for Key in "${!git_review[@]}" ; do
        Cmd="git config --local "$Section"."$Key" ${git_review["$Key"]}"
        [ "$DEBUG" = "1" ] && echo "Cmd: $Cmd"
        [ "$DEBUG" != "1" ] && $Cmd
done
