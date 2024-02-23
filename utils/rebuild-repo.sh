#!/bin/bash

function exitinfo() {
  echo $1
  exit 1
}

keyfile_cmdline=$1
current_dir=$(dirname $(realpath -ms $0))
project_root=$(realpath "$current_dir/..")
source "$project_root/vars" || exitinfo "Cannot include $project_root/vars"
keyfile_cmdline=$1

which gzip &> /dev/null  || exitinfo "gzip not found"
which lzma &> /dev/null  || exitinfo "lzma not found"
which xz &> /dev/null    || exitinfo "xz not found"
which bzip2 &> /dev/null || exitinfo "bzip2 not found"

[ -z "$repo_webroot" ] && exitinfo "No repo_webroot set. Check project_root/vars"
if [ "${repo_webroot::1}" != "/" ]; then
  repo_webroot=$(realpath -ms "$project_root/$repo_webroot")
fi
[ ! -d "$repo_webroot" ] || [ ! -w "$repo_webroot" ] && exitinfo "No access to $repo_webroot"

[ -z "$keyfile_cmdline" ] && [ -z "$secret_dir" ] && exitinfo "Cannot find private key. Check secret_dir in vars or provide a filename in command line"
keyfile=$(realpath -ms ${keyfile_cmdline:-"$project_root/$secret_dir/apt-repo/apt-repo.private"})
[ ! -f "$keyfile" ] || [ ! -r "$keyfile" ] && exitinfo "No access to keyfile $keyfile"

mkdir -p "$repo_webroot/dists/stable/main/binary-amd64" "$repo_webroot/pool/main" || exitinfo "Cannot create repo structure"
cp "$project_root/packages/"*.deb "$repo_webroot/pool/main/" || exitinfo "Cannot copy .deb files"

cd "$repo_webroot/" && \
  apt-ftparchive packages --arch amd64 pool/ > dists/stable/main/binary-amd64/Packages && \
  gzip -fk9 dists/stable/main/binary-amd64/Packages && \
  lzma -fk9 dists/stable/main/binary-amd64/Packages && \
  xz -fk9 dists/stable/main/binary-amd64/Packages && \
  bzip2 -fk9 dists/stable/main/binary-amd64/Packages || \
  exitinfo "Cannot create $repo_webroot/dists/stable/main/binary-amd64/Packages or its archives"

apt-ftparchive \
 -o APT::FTPArchive::Release::Origin="my-repo" \
 -o APT::FTPArchive::Release::Label="my-repo" \
 -o APT::FTPArchive::Release::Suite="my-repo" \
 -o APT::FTPArchive::Release::Description="my-repo" \
 -o APT::FTPArchive::Release::Architectures="amd64" \
 -o APT::FTPArchive::Release::Components="main" \
 -o APT::FTPArchive::Release::Codename="stable" \
 release --arch amd64 dists/stable/ > dists/stable/Release

export GNUPGHOME=$(mktemp -d /tmp/repoXXXXXX) && \
  rm -rf $GNUPGHOME && \
  mkdir $GNUPGHOME && \
  chmod 700 $GNUPGHOME || exitinfo "Cannot create temp folder: $GNUPGHOME"

is_imported=""
is_signed=""

gpg --import $keyfile && \
  gpg --show-keys $keyfile | grep "apt-repo-key" -B 1 | head -n 1 | awk '{print $1":6:"}' | gpg --import-ownertrust && \
  is_imported="yes"

if [ -n "$is_imported" ]; then
  gpg --default-key apt-repo-key --yes --armor --sign --detach-sign --output dists/stable/Release.gpg dists/stable/Release && \
    gpg --default-key apt-repo-key --yes --armor --sign --detach-sign --clearsign --output dists/stable/InRelease dists/stable/Release && \
    is_signed="yes"
fi

gpgconf --kill all && rm -rf $GNUPGHOME
unset GNUPGHOME
[ -z "$is_imported" ] && exitinfo "Cannot import key"
[ -z "$is_signed" ] && exitinfo "Cannot sign repo"



#echo $current_dir
#echo $project_root
#echo $repo_webroot

