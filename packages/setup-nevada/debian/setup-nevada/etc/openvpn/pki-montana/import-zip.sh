#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))
import_file="$1"

if [ -z "$import_file" ] || [ ! -s "$import_file" ] ; then
  echo "No zip file specified or it is empty"
  exit 1
fi

unzip "$import_file" -d "$current_dir"
