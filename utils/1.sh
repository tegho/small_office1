#!/bin/bash


echo "${1:-word}"

exit

function exitinfo() {
  echo $1
  exit 1
}

current_dir=$(dirname $(realpath -ms $0))
project_root=$(realpath "$current_dir/..")
source "$project_root/vars" || exitinfo "Cannot include $project_root/vars"

[ -z "$repo_webroot" ] && exitinfo "No repo_webroot set. Check project_root/vars"
if [ "${repo_webroot::1}" != "/" ]; then
  repo_webroot=$(realpath -ms "$project_root/$repo_webroot")
fi
[ ! -d "$repo_webroot" ] || [ ! -w "$repo_webroot" ] && exitinfo "No access to $repo_webroot"

cp "$project_root/packages/"*.deb "$repo_webroot/pool/main/" || exitinfo "Cannot copy .deb files"

echo $current_dir
echo $project_root
echo $repo_webroot

