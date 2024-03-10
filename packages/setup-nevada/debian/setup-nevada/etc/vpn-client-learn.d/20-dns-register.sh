#!/bin/bash

DEBUG=0
# DEBUG=1

##############################
# Environment variables:
# ACT:
#   "UP4" or "UP6" - user connected or updated
#   "DN4" or "DN6" - user disconnected
# ADR:
#   user ip address. Can be ip4 or ip6.
# PTR:
#   in-addr.arpa string for ADR
# UNAME:
#   optional user name (certificate CN)
#
#  $ACT   $ADR   $UNAME
#  "UP4"  "ip4"  "name"
#  "UP6"  "ip6"  "name"
#  "DN4"  "ip4"  ["name"]
#  "DN6"  "ip6"  ["name"]
#
# MODE:
#   "UNKNOWN"
#   "OVPN"
#   "SWAN"
##############################



dns_ttl=300
host_suffix="-vpn"
domain="nevada"
keyfile="/etc/bind/keys/vpn-update.key"
dns_server="192.168.192.1"

##############################
function debugmessage () {
  # [ "$DEBUG" -ne 0 ] && logger "$1"
  [ "$DEBUG" -ne 0 ] && echo "$1"
}

##############################
function addrec () {

    local ACT="$1"
    local ADR="$2"
    local PTR="${3}."
    local UNAME="$4"

    local cmdstr=""
    local fqdn="$UNAME${host_suffix}.${domain}."

    cmdstr+="server $dns_server\n"
    cmdstr+="update add $PTR $dns_ttl PTR $fqdn\n"
    cmdstr+="\n"

    case "$ACT" in
      "UP4")
        cmdstr+="update del $fqdn A\n"
        cmdstr+="update add $fqdn $dns_ttl A $ADR\n"
      ;;

      "UP6")
        cmdstr+="update del $fqdn AAAA\n"
        cmdstr+="update add $fqdn $dns_ttl AAAA $ADR\n"
      ;;
    esac

    cmdstr+="send\n"

    debugmessage "$cmdstr"
    printf "$cmdstr" | nsupdate -k "$keyfile"
}

##############################
function delrec () {
    local ACT="$1"
    local ADR="$2"
    local PTR="${3}."
    local UNAME="$4"
    local cmdstr=""
    local p


    dig @"$dns_server" +short -x "$ADR" | while read p; do

        local cmdstr=""
        cmdstr+="server $dns_server\n"
        cmdstr+="update delete $p A\n"
        cmdstr+="update delete $p AAAA\n"
        cmdstr+="send\n"

        debugmessage "$cmdstr"
        printf "$cmdstr" | nsupdate -k "$keyfile"
    done

    cmdstr+="server $dns_server\n"
    cmdstr+="update delete $PTR PTR\n"
    cmdstr+="send\n"

    debugmessage "$cmdstr"
    printf "$cmdstr" | nsupdate -k "$keyfile"

}

##############################
case "$ACT" in

  "UP4"|"UP6")
    delrec "$ACT" "$ADR" "$PTR"
    addrec "$ACT" "$ADR" "$PTR" "$UNAME"
    ;;

  "DN4"|"DN6")
    delrec "$ACT" "$ADR" "$PTR"
    ;;

  *)
    debugmessage "Command not supported: $ACT"
    ;;
esac
