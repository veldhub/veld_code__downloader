#!/bin/bash

set -e

if [[ "$url" = "" ]]; then
  echo "no 'url' arg given"
  exit 1
fi

if [[ "$out_file" = "" ]]; then
  echo "no 'out_file' arg given, fetching file name from url"
  out_file=$(curl -sI "$url" | grep -i "content-disposition" | sed -n 's/.*filename="\(.*\)".*/\1/p')
  echo "file name is ${out_file}"
fi

out_path=/veld/output/"$out_file"

if [ -f "$out_path" ]; then
  echo "file ${out_file} already exists. Skipping download"
else
  echo "downloading from ${url} to ${out_path}"
  curl -o "$out_path" "$url"
fi

