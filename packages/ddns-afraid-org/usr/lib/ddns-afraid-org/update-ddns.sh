#!/bin/bash

config_dir="/etc/ddns-afraid-org.d"

function alert() {
  #echo "$1"
  logger -t "ddns-afraid-org" "$1"
}

parse_config() {
  local config_file=$1
  local DDNS_URL
  local key
  local value

  if [ ! -f "$config_file" ] || [ ! -r "$config_file" ] || ! source "$config_file" &> /dev/null ; then
    alert "Can't open config: $config_file"
    return 1
  fi

  local oldifs="$IFS"
  sed -n '/^[\t ]*#/d;/^[\t ]*$/d;p' "$config_file" | while IFS='=' read -r key value; do
    if [[ $key && $value ]]; then
      declare "$key=$value"
    fi
  done
  IFS="$oldifs"

  if [ -z "$DDNS_URL" ] ; then
    alert "DDNS_URL is not set in $config_file"
    return 1
  fi

  echo ">> $DDNS_URL"

  if which curl &> /dev/null ; then
    curl --silent "$DDNS_URL" &> /dev/null && return 0
  elif which wget &> /dev/null ; then
    wget  --quiet -O - "$DDNS_URL" &> /dev/null && return 0
  else
    alert "Neither curl nor wget is installed. DDNS update canceled"
    return 1
  fi

  alert "DDNS update failed for $DDNS_URL"
  return 1
}


for conf in $config_dir/*.conf ; do
  parse_config "$conf"
done
