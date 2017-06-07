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
    # check for wget
    check_for wget
}

# check for needed programs
check_programs

yell "Installing jkyotocabinet"

try wget "http://fallabs.com/kyotocabinet/javapkg/kyotocabinet-java-1.24.tar.gz"
try tar -xzf kyotocabinet-java-1.24.tar.gz
cd kyotocabinet-java-1.24
try ./configure --prefix=/usr/local
try make
try make install
