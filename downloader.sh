#!/bin/bash

set -e

# print args
echo "-- arguments ------------------------------------------------------------"
echo "in_csv_file: ${in_csv_file}"
echo "url: ${url}"
echo "out_file: ${out_file}"
echo "do_extract: ${do_extract}"
echo "csv_has_headers: ${csv_has_headers}"

# validate args
if [ -z "$url" ] && [ -z "$in_csv_file" ]; then
  echo "no 'url' or 'in_csv_file' arg given"
  exit 1
fi
if [ -n "$url" ] && [ -n "$in_csv_file" ]; then
  echo "both 'url' and 'in_csv_file' arg given. Must be only one"
  exit 1
fi
if [ -n "$out_file" ] && [ -n "$in_csv_file" ]; then
  echo "both 'out_file' and 'in_csv_file' arg given. The names of the files must be defined within"\
  "the csv file and not with the global variable 'out_file'."
  exit 1
fi

cd /veld/output/

# main function, to be used for individual download or batch downloads from csv
function download {

  local url="$1"
  local out_file="$2"

  # sub download function checking for existence of download target file
  function check_cache_and_download {
    if [ -f "$out_file" ]; then
      echo "file ${out_file} already exists. Skipping download"
    else
      echo "downloading:"
      command="curl -L -o ${out_file} ${url}"
      echo "$command"
      eval "$command"
    fi
  }

  # handling existing or non-existing 'out_file' arg 
  if [ -z "$out_file" ]; then
    echo "no 'out_file' arg given, trying to fetch file name from url"
    command="curl -sI ${url} | grep -i 'content-disposition' | sed -n 's/.*filename=\"\(.*\)\".*/\1/p'"
    echo "$command"
    out_file=$(eval "$command")
    if [ -z "$out_file" ]; then
      echo "could not fetch name from url; downloading it without knowing the name in advance." 
      cd /tmp
      command="curl -L -O ${url}"
      echo "$command"
      eval "$command"
      out_file=$(ls)
      echo "downloaded ${out_file}"
      mv /tmp/"$out_file" /veld/output/"$out_file"
      cd /veld/output/
    else
      echo "fetched file name from url is ${out_file}"
      check_cache_and_download
    fi
  else
    check_cache_and_download
  fi
  
  # handling extraction
  if [[ "$do_extract" == "true" ]]; then
    echo "extracting:"
    command="dtrx --noninteractive --overwrite ${out_file}"
    echo "$command"
    eval "$command"
  fi

}

# main processing split between single download and reading from csv
if [ -n "$url" ]; then
  echo "-- downloading from single url ------------------------------------------"
  download "$url" "$out_file"
elif [ -n "$in_csv_file" ]; then
  echo "-- downloading from multiple urls from csv file -------------------------"
  in_csv_file_path=/veld/input/"$in_csv_file"
  if [ "$csv_has_headers" = "true" ]; then
    command="mlr --csv --headerless-csv-output --ofs ' ' cat ${in_csv_file_path}"
  else
    command="mlr --csv --headerless-csv-input --headerless-csv-output --ofs ' ' cat ${in_csv_file_path}"
  fi
  eval "$command" | while read -r url out_file; do
    download "$url" "$out_file"
  done
fi

