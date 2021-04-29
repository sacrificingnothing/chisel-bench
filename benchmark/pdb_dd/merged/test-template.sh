#!/bin/bash

export BENCHMARK_NAME=head
export BENCHMARK_DIR=$CHISEL_BENCHMARK_HOME/benchmark/$BENCHMARK_NAME
export SRC=$BENCHMARK_DIR/$BENCHMARK_NAME.c
export ORIGIN_BIN=head #$BENCHMARK_DIR/$BENCHMARK_NAME.origin
export REDUCED_BIN=head #$BENCHMARK_DIR/$BENCHMARK_NAME.reduced
export TIMEOUT="-k 0.5 0.5"
export LOG=$BENCHMARK_DIR/log.txt

# source $CHISEL_BENCHMARK_HOME/benchmark/test-base.sh

function clean() {
  # TODO
  return 0
}

function test(){
  FILE=$1
  ARG_VALS=$2
  for n in $ARG_VALS; do
    diff -q \
    <(cat $FILE | $ORIGIN_BIN -$n) \
    <(cat $FILE | $REDUCED_BIN -$n) \
    >&/dev/null || exit 1
  done
}

function desired() {
  return 0
}

function undesired() {
  # TODO
  return 0
}

function desired_disaster() {
  # TODO
  return 0
}

# main
desired