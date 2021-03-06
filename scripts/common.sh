#!/usr/bin/env sh
set -ex

# Common setup for both Appveyor and Circle CI

REPO_ROOT=$(git rev-parse --show-toplevel)

if [ -z "${OPAMROOT}" ]; then
  OPAMROOT=${REPO_ROOT}/_build/opam
fi

export OPAMROOT
export OPAMYES=1
export OPAMCOLORS=1

# if a compiler is specified, use it; otherwise use the system compiler
if [ -n "${OPAM_COMP}" ]; then
  OPAM_COMP_ARG="--comp=${OPAM_COMP}"
  OPAM_SWITCH_ARG="--switch=${OPAM_COMP}"
fi

opam init -v -n "${OPAM_COMP_ARG}" "${OPAM_SWITCH_ARG}" local "${OPAM_REPO}"
echo opam configuration is:
opam config env
eval $(opam config env)

export PATH="${OPAMROOT}/${OPAM_COMP}/bin:${PATH}"

opam install depext -y -v
opam install depext-cygwinports -y || true

OPAMBUILDTEST=1 opam depext -u vpnkit

# Debug a failure to find stringext's archive
OPAMVERBOSE=1 opam install stringext -y

# Don't run all the unit tests of all upstream packages in the universe
# for speed. As a special exception we will run the tests for tcpip
OPAMVERBOSE=1 opam install --deps-only tcpip -y
OPAMVERBOSE=1 opam install tcpip -t

opam install $(ls -1 ${OPAM_REPO}/packages/upstream) -y
OPAMVERBOSE=1 opam install --deps-only -t vpnkit -y

OPAMVERBOSE=1 make
OPAMVERBOSE=1 make test
OPAMVERBOSE=1 make artefacts
OPAMVERBOSE=1 make OSS-LICENSES
OPAMVERBOSE=1 make COMMIT
