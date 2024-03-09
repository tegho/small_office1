#!/bin/bash

DEBUG=0
#DEBUG=1

#############################################################
# called by OPENVPN:
#
# learn.sh     add  ip  name
# learn.sh  update  ip  name
# learn.sh     del  ip
# learn.sh  delete  ip
#
#########
# called by SWANCTL:
#
# $PLUTO_VERB           up-host
# $PLUTO_VERB           up-client
# $PLUTO_VERB           up-host-v6
# $PLUTO_VERB           up-client-v6
#
# $PLUTO_VERB           down-host
# $PLUTO_VERB           down-host-v6
# $PLUTO_VERB           down-client
# $PLUTO_VERB           down-client-v6
#
# $PLUTO_PEER_CLIENT    ip
# $PLUTO_PEER_ID        "C=Brazil, OU=Sales, CN=user1"
#
#########
# RESULT:
#
# Sets ACT, ADDR, UNAME and MODE variables
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
#############################################################


##############################
function debugmessage () {
  # [ "$DEBUG" -ne 0 ] && logger "$1"
  [ "$DEBUG" -ne 0 ] && echo "$1"
}


##############################
function expandip6 () {
  # PARAMETERS:
  #   $1 - expect ip6
  # OUT:
  #   replace :: with zeros and print expanded ip6
  # EXAMPLE:
  #   expandip6 "2001:330:10:140::2"
  #   2001:330:10:140:0:0:0:2
  #   expandip6 "::3"
  #   0:0:0:0:0:0:0:3

  local ip6="$1"
  local colons=""
  local expanded=""

  # add 0 if : is 1st or last symbol
  ip6="$(echo "$ip6" | sed 's/^:/0:/')"
  ip6="$(echo "$ip6" | sed 's/:$/:0/')"

  # expand :: if any
  if [ -n $(echo "$ip6" | sed -n '/::/p') ]; then
    colons="$(echo "$ip6" | sed 's/[^:]//g')"
    expanded="$(echo ':::::::::' | sed "s/$colons//" | sed 's/:/:0/g' | sed -r 's/.?$//')"
    ip6="$(echo "$ip6" | sed -r "s/::([0-9a-fA-F])/$expanded\1/g")"
  fi

  echo "$ip6"
}


##############################
function validip6 () {
  # PARAMETERS:
  #   $1 - expect ip6
  # OUT:
  #   print ip6 if valid
  #   exit code 0 if valid

  local addr

  addr="$(echo "$1" | sed 's,/128$,,')"
  addr="$(expandip6 "$addr")"
  addr="$(echo "$addr" | sed -nr 's/^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4})$/\1/p')"
  [ -z "$addr" ] && return 1

  echo "$addr"
  return 0
}


##############################
function validip4 () {
  # PARAMETERS:
  #   $1 - expect ip4
  # OUT:
  #   print ip4 if valid
  #   exit code 0 if valid

  local addr

  addr="$(echo "$1" | sed 's,/32$,,')"
  addr="$(echo "$addr" | sed -nr 's/^((([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5])))$/\1/p')"
  [ -z "$addr" ] && return 1

  echo "$addr"
  return 0
}


#############################################################
ACT=""
ADR=""
PTR=""
UNAME=""
MODE="UNKNOWN"

if [ "$#" -ge 2 ]; then
  debugmessage "$# cmdline params: $*"
  debugmessage "Test for OPENVPN params"

  ovpn_cmd="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  ovpn_ip="$2"
  ovpn_name="$(echo "$3" | tr '[:upper:]' '[:lower:]')"

  case "$ovpn_cmd" in
    "add"|"update")
    ACT="UP"
    debugmessage "1st param (cmd) acts like: $ACT"
    ;;

    "del"|"delete")
    ACT="DN"
    debugmessage "1st param (cmd) acts like: $ACT"
    ;;

    *)
    debugmessage "1st param (cmd) unrecognized."
    ;;
  esac

  if [ "$ACT" == "UP" ] ; then
    if [ -n "$ovpn_name" ] ; then
      UNAME="$ovpn_name"
      debugmessage "3rd param (name): $UNAME"
    else
      ACT=""
      debugmessage "3rd param (name): empty."
    fi
  fi

  if [ -n "$ACT" ] ; then
    ADR="$(validip4 "$ovpn_ip")"
    if [ -n "$ADR" ] ; then
      debugmessage "2nd param (ip) v4 found: $ADR"
      ACT+="4"
      MODE="OVPN"
      PTR="$(echo "$ADR" | awk 'BEGIN{FS=".";OFS="."} {print $4,$3,$2,$1,"in-addr.arpa"}')"
    else
      ADR="$(validip6 "$ovpn_ip")"
      if [ -n "$ADR" ] ; then
        debugmessage "2nd param (ip) v6 found: $ADR"
        ACT+="6"
        MODE="OVPN"
        PTR="$(echo "$ADR" | awk 'BEGIN{FS=":";OFS="."} {print $8,$7,$6,$5,$4,$3,$2,$1,"ipv6.arpa"}')"
      else
        debugmessage "2nd param (ip). Invalid addr: $ovpn_addr"
        ADR=""
        ACT=""
        UNAME=""
      fi
    fi
  fi
fi

################################

if [ -z "$ACT" ] ; then

  debugmessage "Test for SWANCTL params"
  debugmessage "(1)PLUTO_VERB=${PLUTO_VERB}, (2)PLUTO_PEER_CLIENT=${PLUTO_PEER_CLIENT}, (3)PLUTO_XAUTH_ID=${PLUTO_XAUTH_ID}"

  swan_cmd="$(echo "$PLUTO_VERB" | tr '[:upper:]' '[:lower:]')"
  swan_ip="$PLUTO_PEER_CLIENT"
  swan_name="$(echo "$PLUTO_XAUTH_ID" | tr '[:upper:]' '[:lower:]')"

  case "$swan_cmd" in
    "up-host"|"up-client"|"up-host-v6"|"up-client-v6")
    ACT="UP"
    debugmessage "1st param (cmd) acts like: $ACT"
    ;;

    "down-host"|"down-client"|"down-host-v6"|"down-client-v6")
    ACT="DN"
    debugmessage "1st param (cmd) acts like: $ACT"
    ;;

    *)
    debugmessage "1st param (cmd) unrecognized."
    ;;
  esac

  if [ -n "$ACT" ] ; then
    ADR="$(validip4 "$swan_ip")"
    if [ -n "$ADR" ] ; then
      debugmessage "2nd param (ip) v4 found: ${ADR}"
      ACT+="4"
      MODE="SWAN"
      PTR="$(echo "$ADR" | awk 'BEGIN{FS=".";OFS="."} {print $4,$3,$2,$1,"in-addr.arpa"}')"
    else
      ADR="$(validip6 "$swan_ip")"
      if [ -n "$ADR" ] ; then
        debugmessage "2nd param (ip) v6 found: ${ADR}"
        ACT+="6"
        MODE="SWAN"
        PTR="$(echo "$ADR" | awk 'BEGIN{FS=":";OFS="."} {print $8,$7,$6,$5,$4,$3,$2,$1,"ipv6.arpa"}')"
      else
        ADR=""
        debugmessage "2nd param (ip). Invalid addr."
        ACT=""
        UNAME=""
      fi
    fi
  fi

  if [ -n "$swan_name" ] ; then
    if [ -n "$(echo "$swan_name" | sed -n '/=/p')" ] ; then
      UNAME="$(echo "$swan_name" | sed -n 's/.*cn[ \t]*=[ \t]*\([^,]\+\).*/\1/p' | sed 's/^[ \t]*//;s/[ \t]*$//')" #'
      [ -z "$UNAME" ] && UNAME="$(echo "$ADR" | sed 's/[\.:]/-/g')"
    else
      UNAME="$swan_name"
    fi

    debugmessage "3rd param (name): $UNAME"
  else
    ACT=""
    debugmessage "3rd param (name): empty."
  fi

fi

debugmessage "=========="
debugmessage "PARSED"
debugmessage "act:  $ACT"
debugmessage "addr: $ADR"
debugmessage "ptr:  $PTR"
debugmessage "user: $UNAME"
debugmessage "mode: $MODE"
debugmessage "=========="


if [ -n "$ACT" ] && [ -n "$ADR" ] ; then
  export ACT
  export ADR
  export PTR
  export UNAME
  export MODE

  ls /etc/vpn-client-learn.d/*.sh | while read fname; do
    bash "$fname"
  done
fi

# always exit 0 to allow any connection
# exit 1 cancels connection
exit 0

