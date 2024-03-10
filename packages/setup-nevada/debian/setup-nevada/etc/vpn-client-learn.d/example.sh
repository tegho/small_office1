#!/bin/bash

exit

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




##############################
function debugmessage () {
  # [ "$DEBUG" -ne 0 ] && logger "$1"
  [ "$DEBUG" -ne 0 ] && echo "$1"
}

debugmessage "=========="
debugmessage "PARSED"
debugmessage "act:  $ACT"
debugmessage "addr: $ADR"
debugmessage "ptr:  $PTR"
debugmessage "user: $UNAME"
debugmessage "mode: $MODE"
debugmessage "=========="
