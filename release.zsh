#!/usr/bin/env zsh

# SPDX-License-Identifier: MIT
#
# Copyright 2026 Chris Barrick <cbarrick1@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -euo pipefail


# CLI Options:
OPT_DIRTY=0          # -d: Skip the git status check.
OPT_DRY_RUN=0        # -n: No mode: Perform a dry run without creating a release.
OPT_YES=0            # -y: Yes mode: Automatically confirm all prompts.
OPT_REMOTE="origin"  # -r: Override the git remote.
ARGS=()              # Remaining non-option arguments.


# Prints the usage string and exits.
function usage {
    err "Usage: ${0}: [-dny] [-r REMOTE] [TAG]"
    err ""
    err "Options:"
    err "  -h         Print this help message and exit."
    err "  -d         Skip the git status check."
    err "  -n         No mode: Perform a dry run without creating a release."
    err "  -y         Yes mode: Automatically confirm all prompts."
    err "  -r REMOTE  The git remote to use. Defaults to 'origin'."
    err ""
    err "Arguments:"
    err "  TAG        The tag to publish. Must be a semantic version string"
    err "             with a leading 'v'. If the tag is not given, it is "
    err "             inferred from Cargo.toml."
    exit 2
}


# Parses the CLI options.
#
# The option values are set in global variables named like `OPT_*`.
# The remaining non-option arguments are set in the array `ARGS`.
#
# Arguments:
#   The command line to be parsed, not including $0.
function parse_opts {
    while getopts hdnyr: arg; do
        case $arg in
        d) OPT_DIRTY=1;;
        n) OPT_DRY_RUN=1;;
        y) OPT_YES=1;;
        r) OPT_REMOTE="$OPTARG";;
        h) usage;;
        ?) usage;;
        esac
    done
    shift $((${OPTIND} - 1))
    ARGS=($@)
}


# Print to stderr.
function err {
    echo "$@" >/dev/stderr
}


# Prompt to run a commnad.
#
# If dry-run mode is enabled, this prints the command that would be run and
# returns. If yes mode is enabled, this prints the command then runs it
# immediately without prompting. Otherwise, it prints the command that will be
# run and asks the user to confirm.
#
# Arguments:
#   The command to run is given as arguments.
function run_prompt {
    # Format the command as a string for printing.
    # Put quotes around arguments that contain spaces.
    local cmd=""
    for arg in "${@}"; do
        if [[ "${arg}" =~ .*[[:space:]].* ]]; then
            cmd="${cmd} \"$arg\""
        else
            cmd="${cmd} $arg"
        fi
    done
    cmd="${cmd:1}" # Strip the leading space introduced by the loop.

    # Bail if in dry-run mode.
    if [[ "${OPT_DRY_RUN}" = 1 ]]; then
        err "Would run the command:   ${cmd}"
        return
    fi

    # Prompt if not in yes mode.
    if [[ "${OPT_YES}" != 1 ]]; then
        err
        err "Will run the command:   ${cmd}"
        while true; do
            read -k1 "?Do you wish to continue? [yN]: " yn
            err
            case $yn in
                [Yy]) break;;
                *) exit 1;;
            esac
        done
    fi

    # Run the command!
    ${@}
}


# Get the current version from Cargo.toml.
#
# Assumes that the `[package]` section is first.
#
# stdout:
#   Prints the current version, with a leading 'v'.
function version_from_cargo {
    if [[ ! -f "Cargo.toml" ]]; then
        err "$0: could not find Cargo.toml"
        exit 1
    fi
    sed -n 's/version *= "\(.*\)"/v\1/p' Cargo.toml | head -n1
}


# Performs prevalidation before creating the tag and release.
#
# If validation suceeds, it prints a message indicating the next steps.
#
# Arguments:
#   tag: The tag to publish. Must be a semantic version with a leading 'v'.
function validate {
    local tag="$1"

    # The tag must start with a 'v'.
    if [[ ! "${tag}" =~ v.* ]]; then
        err "$0: release tag must start with 'v': got '${tag}'"
        exit 1
    fi

    # The tag must be valid semver.
    # The pattern was taken from semver.org and modified to work with zsh.
    # https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
    local semver='^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$'
    if [[ ! "${tag}" =~ ${semver} ]]; then
        err "$0: release tag must be valid semver: got '${tag}'"
        exit 1
    fi

    # Check that the version in Cargo.toml matches the tag.
    # The [package] section is assumed to come before all others.
    if [[ "${tag}" != "$(version_from_cargo)" ]]; then
        err "$0: tag does not agree with Cargo.toml: got '${tag}', want '$(version_from_cargo)'"
        exit 1
    fi

    # Check that the tag does not already exist.
    if (git tag --list | grep -Fxq "${tag}"); then
        err "$0: tag already exists: '${tag}'"
        exit 1
    fi

    # Check that the Git repo status is clean.
    if [[ "${OPT_DIRTY}" != 1 && ! -z "$(git status --porcelain)" ]]; then
        err "$0: there are uncomitted changes or untracked files"
        exit 1
    fi

    # Success!
    err "Tagging release ${tag}"
}


# Create the release tag in git and push it to the remote.
#
# Arguments:
#   tag: The tag to publish.
function create_tag {
    local tag="$1"
    run_prompt git tag "${tag}" --sign --message "Release ${tag}"
    run_prompt git push "${OPT_REMOTE}" tag "${tag}"
}


# Wait until the release workflow is complete.
function watch_release_workflow {
    if [[ "${OPT_DRY_RUN}" == 1 ]]; then
        err
        err "Would wait for the GitHub release workflow to complete"
        return
    fi

    err
    err "Waiting for the release workflow to trigger"
    sleep 3  # Wait for the workflow to actually trigger.
    local id=$(gh run list --workflow 'Release to Github' --limit 1 --json databaseId --jq '.[0].databaseId')
    gh run watch "${id}"
}


# Main entry point of the script.
function main {
    # Parse the options in $@.
    parse_opts $@

    # Assign names to the non-option arguments.
    [[ "${#ARGS}" < 2 ]] || usage
    local tag
    if [[ "${#ARGS}" = 1 ]]; then
        tag="${ARGS[1]}"
    else
        tag="$(version_from_cargo)"
    fi

    # Execute the release
    validate "${tag}"
    create_tag "${tag}"
    watch_release_workflow

    # Debrief
    if [[ "${OPT_DRY_RUN}" = 0 ]]; then
        err
        err "A tag for ${tag} has been created, signed, and pushed."
        err
        err "A draft GitHub release has been created. Please review the release carefully"
        err "before publishing. Releases are immutable once published. Once the release is"
        err "published, an action will trigger to publish the crate to crates.io."
        err
        err "Visit https://github.com/cbarrick/reexport/releases to complete the release."
    fi
}

main $@
