#!/bin/bash

# Call like 'run.sh <C> <pattern-type> <pattern-param> <trials> [--auto] [--debug]

# Remove last arg
alias lshift="set -- "${@:1:$(($#-1))}""

if [ "$5" = "--debug" ]; then
  debug="true"
  lshift
fi

if [ "$5" = "--auto" ]; then
  auto="-d:auto"
  lshift
fi

if [ "$1" -ne "2" ]; then
  echo "Only C=2 is currently supported"
  exit
fi

mkdir -p data
cd data

dirname="C=$(printf %05d $1);pattern=$2($3)"
mkdir -p "$dirname"
cd "$dirname"

if [ "$debug" = true ]; then
  nim c $auto --threads:on -r ../../multiThread $1 $2 $3 $4 2> ../../debug.txt
  cat ../../debug.txt
else
  nim c -d:release $auto --threads:on -r ../../multiThread $1 $2 $3 $4
fi
