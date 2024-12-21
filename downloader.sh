#!/bin/bash

set -e

cd /veld/output/

if [[ "$url" = "" ]]; then
  echo "no 'url' arg given"
  exit 1
fi

function download {
  if [ -f "$1" ]; then
    echo "file ${1} already exists. Skipping download"
  else
    echo "downloading from ${url} to ${1}"
    curl -L -o "$1" "$url"
  fi
}

if [ -z "$out_file" ]; then
  echo "no 'out_file' arg given, fetching file name from url"
  out_file=$(curl -sI "$url" | grep -i "content-disposition" | sed -n 's/.*filename="\(.*\)".*/\1/p')
  if [ -z "$out_file" ]; then
    echo "could not fetch name from resource; downloading it without knowing the name in advance." 
    cd /tmp
    curl -L -O "$url"
    out_file=$(ls)
    echo "downloaded ${out_file}"
    mv /tmp/"$out_file" /veld/output/"$out_file"
    cd /veld/output/
  else
    echo "file name is ${out_file}"
    download "$out_file"
  fi
else
  download "$out_file"
fi

if [[ "$do_extract" == "true" ]]; then
  echo "extracting:"
  command="dtrx --noninteractive --overwrite ${out_file}"
  echo "$command"
  eval "$command"
fi

