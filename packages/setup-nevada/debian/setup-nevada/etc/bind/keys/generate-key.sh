#!/bin/sh

#exit
keyname="vpn-update"
/usr/sbin/rndc-confgen -a -c /etc/bind/keys/${keyname}.key -k ${keyname}-key -u bind





