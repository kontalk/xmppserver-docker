#!/usr/bin/env bash
set -e

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 1; }
try() { "$@" || die "cannot $*"; }
check_for() { which $@ >/dev/null || die "Unable to locate $*"; }

check_programs()
{
    # check for git
    check_for git
}

# check for needed programs
check_programs

yell "Cloning repositories"

try git clone https://github.com/kontalk/HttpUploadComponent.git
