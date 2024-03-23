#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))

container_file="$current_dir/pki-montana.bin"
ca_pwd_file="$current_dir/ca_key_password"
pki_pwd_file="$current_dir/pki_password"

crl_file1="$my_export_dir/crl.pem"
crl_file2="/var/www/crl-pki-montana/crl.pem"


if [ ! -s "$ca_pwd_file" ] || [ ! -s "$pki_pwd_file" ] || [ ! -s "$container_file" ] ; then
  echo "Some files are missing"
  exit 1
fi

ret=0
export CTKEY=$(cat "$pki_pwd_file")
EASYRSA_PASSIN="file:$ca_pwd_file" crypt-pki "$container_file" --crl --file "$crl_file1" && \
cp -f "$crl_file1" "$crl_file2" || ret=1


if [ $ret -eq 0 ]; then
  echo "CRL generation succeeded"
else
  echo "ERROR. CRL generation failed"
fi


exit $ret
