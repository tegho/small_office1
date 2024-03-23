#!/bin/bash

current_dir=$(dirname $(realpath -ms $0))

ca_name="Montana vpn CA"
container_file="$current_dir/pki-montana.bin"
ca_pwd_file="$current_dir/ca_key_password"
pki_pwd_file="$current_dir/pki_password"
crl_url="http://montana.ajalo.com/crl"

vpn_server="nevada.ajalo.com"
export_vpn_file="$current_dir/server-vpn.zip"

office_server="ohio.ajalo.com"
export_office_file="$current_dir/server-office.zip"

pki_server="montana.ajalo.com"
my_export_dir="/etc/nginx/pki-montana"
export_pki_file="$my_export_dir/server-pki.zip"

crl_file1="$my_export_dir/crl.pem"
crl_file2="/var/www/crl-pki-montana/crl.pem"


# pki container is exist
if [ -s "$container_file" ] ; then
  echo "==========\nPKI container already exist.\n==========\n"
  exit 0
fi

# remove the container and password files if any exist
rm -f "$ca_pwd_file" "$pki_pwd_file" "$container_file"
if [ -f "$ca_pwd_file" ] || [ -f "$pki_pwd_file" ] || [ -f "$container_file" ] ; then
  echo "Can not delete files"
  exit 0
fi

# generate password for CA key
openssl rand -base64 18 > "$ca_pwd_file"
if [ ! -s "$ca_pwd_file" ] ; then
  echo "Cannot generate CA password"
  exit 0
fi
chmod 600 "$ca_pwd_file"

# create a new pki container
ctkey=$(crypt-pki "$container_file" --init --url "$crl_url") && [ -n "$ctkey" ] && echo "$ctkey" > "$pki_pwd_file"
if [ ! -s "$container_file" ] || [ ! -s "$pki_pwd_file" ] ; then
  echo "Cannot create PKI container"
  exit 0
fi

ret=0
if [ -s "$pki_pwd_file" ] && [ -s "$container_file" ] ; then
  chmod 600 "$container_file" "$pki_pwd_file"

  export CTKEY=$(cat "$pki_pwd_file")

  # create new CA and pki server cert
  EASYRSA_PASSIN="file:$ca_pwd_file" EASYRSA_PASSOUT="$EASYRSA_PASSIN" crypt-pki "$container_file" --exec --cmd "easy-rsa/easyrsa --req-cn=\"$ca_name\" build-ca" && \
    crypt-pki "$container_file" --newreq --internalname "$pki_server" --nopass && \
    EASYRSA_PASSIN="file:$ca_pwd_file" crypt-pki "$container_file" --signserver --internalname "$pki_server" && \
    crypt-pki "$container_file" --export-zip --internalname "$pki_server" --file "$export_pki_file" && \
    unzip "$export_pki_file" -d "$my_export_dir" && \
    rm -f "$export_pki_file" "$my_export_dir/ta.key" || ret=1

  # create new vpn server cert
  crypt-pki "$container_file" --newreq --internalname "$vpn_server" --nopass && \
    EASYRSA_PASSIN="file:$ca_pwd_file" crypt-pki "$container_file" --signserver --internalname "$vpn_server" && \
    crypt-pki "$container_file" --export-zip --internalname "$vpn_server" --file "$export_vpn_file" || ret=1

  # create new office server cert
  crypt-pki "$container_file" --newreq --internalname "$office_server" --nopass && \
    EASYRSA_PASSIN="file:$ca_pwd_file" crypt-pki "$container_file" --signserver --internalname "$office_server" && \
    crypt-pki "$container_file" --export-zip --internalname "$office_server" --file "$export_office_file" || ret=1

  # load templates
  crypt-pki "$container_file" --loadtemplate --file "$current_dir/templates/android-api" && \
    crypt-pki "$container_file" --loadtemplate --file "$current_dir/templates/android-in" && \
    crypt-pki "$container_file" --loadtemplate --file "$current_dir/templates/win-api" && \
    crypt-pki "$container_file" --loadtemplate --file "$current_dir/templates/win-in" || \
    ret=1

  # create CRL
  EASYRSA_PASSIN="file:$ca_pwd_file" crypt-pki "$container_file" --crl --file "$crl_file1" && \
  cp -f "$crl_file1" "$crl_file2" || ret=1
fi

if [ $ret -eq 0 ]; then
  echo -e "==========\nPKI container is ready. Now secure the passwords from $current_dir and copy $export_file to a vpn server.\n==========\n"
else
  echo "==========\nERROR. Some PKI operations are failed.\n==========\n"
fi


exit 0
