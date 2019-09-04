#!/usr/bin/env bash
shopt -s extglob

if [[ "${DEBUG}" = "true" ]]
then
  TF_LOG_LEVEL="DEBUG"
  TF_LOG_PATH=./log.txt
  set -x
fi

function make_abs_path {
  local file="$1"

  if [[ "${file}" = ./* ]]
  then
    file="$PWD/${file#./}"
  elif [[ "${file}" != /* ]]
  then
    file="$PWD/${file#./}"
  fi

  echo "${file%\/}"

}


function abspath {
    if [[ -d "$1" ]]
    then
        pushd "$1" >/dev/null
        pwd
        popd >/dev/null
    elif [[ -e $1 ]]
    then
        pushd "$(dirname "$1")" >/dev/null
        echo "$(pwd)/$(basename "$1")"
        popd >/dev/null
    else
        echo "$1" does not exist! >&2
        return 127
    fi
}

function get_json_value {
  
  local key=$1
  local jsonString=$2
  local patrn=\"$key\"': *"[^"]*"'
  local result

  result=$(grep -o "$patrn" <<< "$jsonString" | grep -o '"[^"]*"$')
  echo "${result//\"/}"

}

function all {

  local inputFilter
  local inputSearchPath  
  local files
  local abs_files

  inputFilter=$(get_json_value filter "$stdin")
  inputSearchPath=$(get_json_value search_path "$stdin")



  mapfile -t files < <(find "$inputSearchPath" -type f  -name "$inputFilter")

  for f in ${files[*]}
  do  
    i=$(abspath "$f")
    abs_files+=("$i")
  done

  printf '{"key":"%s"}\n' "${abs_files[*]}"

}

stdin=$(cat /dev/stdin)

all


#'{"filter":"*.yaml", "search_path": "../teams"}'