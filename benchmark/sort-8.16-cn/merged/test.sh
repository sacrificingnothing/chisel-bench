#!/bin/bash

export BENCHMARK_NAME=sort-8.16
export BIN_NAME=sort-8.16-cn
export BENCHMARK_DIR=$CHISEL_BENCHMARK_HOME/benchmark/$BIN_NAME/merged
export SRC=$BENCHMARK_DIR/$BENCHMARK_NAME.c
export ORIGIN_BIN=$BENCHMARK_DIR/$BENCHMARK_NAME.origin
export REDUCED_BIN=$BENCHMARK_DIR/$BIN_NAME.reduced
export TIMEOUT="-k 0.8 0.8"
export LOG=$BENCHMARK_DIR/log.txt

source $CHISEL_BENCHMARK_HOME/benchmark/test-base.sh

export BENCHMARK_CFLAGS="-lpthread"

function clean() {
  rm -rf $LOG $REDUCED_BIN file temp* gt-*
  return 0
}

function conditional_exit(){
  if [[ $1 -eq 0 || $1 -eq 1 ]]; then
     return 0
  else
     return 1
  fi
}

function run() {
  timeout $TIMEOUT $REDUCED_BIN $1 $input >&$LOG
  conditional_exit $? || exit 1
  $ORIGIN_BIN $1 $input >&temp2
  diff -q <(cat $LOG | cut -d: -f4) <(cat temp2 | cut -d: -f4) || exit 1
  grep -q "(null)" $LOG && exit 1
}

function run_disaster() {
  timeout -k 0.5 0.5 $REDUCED_BIN $1 $input >&$LOG
  cat $LOG | grep -E -q "$2" || exit 1
}

function desired() {
  for input in $(ls test/*); do
    run "-cn" || exit 1
  done
  return 0
}

function desired_disaster() {
  case $1 in
  memory)
    MESSAGE="memory exhausted"
    ;;
  file)
    MESSAGE="Bad file descriptor|write error"
    ;;
  *)
    return 1
    ;;
  esac
  for input in $(ls test/*); do
    run_disaster "-cn" "$MESSAGE" || exit 1
  done
  return 0
}

function infinite() {
  r=$1
  grep "Sanitizer" $LOG >&/dev/null && return 0
  if [[ $r -eq 124 ]]; then # timeout
    return 0
  fi
  return 1
}

function outputcheckerror() {
  r="$1"
  if grep -E -q "$r" $LOG; then
    return 1
  fi
  return 0
}

OPT=("-b" "-d" "-f" "-g" "-i" "-M" "-h" "-n" "-V" "-c" "-C"
  "-k" "-m" "-o" "-S" "-t" "-T" "--help")
function undesired() {
  { timeout -k 0.1 0.1 $REDUCED_BIN; } >&$LOG
  infinite $? || exit 1
  export srcdir=$BENCHMARK_HOME/tests
  export PATH="$(pwd):$PATH"
  touch file
  for opt in ${OPT[@]}; do
    if [[ $opt == '-o' || $opt == '-T' ]]; then
      { timeout -k 0.1 0.1 $REDUCED_BIN $opt file; } >&$LOG
      infinite $? || exit 1
    else
      { timeout -k 0.5 0.5 $REDUCED_BIN $opt file; } >&$LOG
    fi
    crash $? && exit 1
  done
  for opt in ${OPT[@]}; do
    if [[ $opt == "-k" ]]; then
      { timeout -k 0.1 0.1 $REDUCED_BIN $opt notexist; } >&$LOG
      err=$?
      outputcheckerror "invalid number at field start: invalid count at start of 'notexist'" && exit 1
      crash $err && exit 1
    elif [[ $opt == '-T' || $opt == '--help' ]]; then
      continue
    elif [[ $opt == '-o' ]]; then
      err=$?
      crash $err && exit 1
    elif [[ $opt == '-S' ]]; then
      { timeout -k 0.1 0.1 $REDUCED_BIN $opt notexist; } >&$LOG
      err=$?
      outputcheckerror "invalid -S argument 'notexist'" && exit 1
      crash $err && exit 1
    elif [[ $opt == '-t' ]]; then
      { timeout -k 0.1 0.1 $REDUCED_BIN $opt notexist; } >&$LOG
      err=$?
      outputcheckerror "multi-character tab 'notexist'" && exit 1
      crash $err && exit 1
    else
      { timeout -k 0.1 0.1 $REDUCED_BIN $opt notexist; } >&$LOG
      err=$?
      outputcheckerror "open failed: notexist: No such file or directory" && exit 1
      crash $err && exit 1
    fi
  done
  for t in $(find tests/ -maxdepth 1 -perm -100 -type f); do
    { timeout -k 1 1 $t; } >&$LOG
    crash $? && exit 1
  done
  return 0
}

main
