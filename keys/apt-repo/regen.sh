#!/bin/bash

#exit

function exitinfo() {
  echo $1
  exit 1
}

export GNUPGHOME=$(mktemp -d /tmp/repoXXXXXX) && \
  rm -rf $GNUPGHOME && \
  mkdir $GNUPGHOME && \
  chmod 700 $GNUPGHOME || exitinfo "Cannot create temp folder: $GNUPGHOME"

result=""
gpg --quick-generate-key apt-repo-key ed25519 sign never && \
  gpg --armor --export-secret-keys apt-repo-key > ./apt-repo.private && \
  gpg --export apt-repo-key > ./apt-repo.public && \
  result="true"

[ -n "$result" ] && gpg --list-keys

gpgconf --kill all
rm -rf $GNUPGHOME
unset GNUPGHOME

[ -z "$result" ] && exitinfo "Cannot generate or export keys"

echo "###########"
echo "NEXT:"
echo "  Rebuild my-repo package to update public key"
echo "  AND"
echo "  Update first install URL"
echo "  AND"
echo "  Rebuild and upload apt repository"

exit 0