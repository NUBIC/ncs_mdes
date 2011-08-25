#!/bin/bash -xe

BUNDLER_VERSION=1.0.18

if [ -z $RVM_RUBY ]; then
    echo "RVM_RUBY must be set"
    exit 1
fi

set +xe
echo "Initializing RVM"
source ~/.rvm/scripts/rvm
set -xe

type rvm | head -1

RVM_CONFIG="${RVM_RUBY}@ncs_mdes"
set +xe
echo "Switching to ${RVM_CONFIG}"
rvm use $RVM_CONFIG
set -xe

which ruby
ruby -v

set +e
gem list -i bundler -v $BUNDLER_VERSION
if [ $? -ne 0 ]; then
  set -e
  gem install bundler -v $BUNDLER_VERSION
fi
set -e

bundle update

bundle exec rake ci:spec --trace
