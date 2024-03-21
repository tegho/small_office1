#!/bin/bash

exit

IPS=`which ipset`
IPT=`which iptables`

function clearfw () {
  $IPT -t filter -F
  $IPT -t nat -F
  $IPT -t mangle -F

  $IPS -quiet destroy vpnnets
  $IPS create vpnnets hash:net -exist

  # default policy
  $IPT -t filter -P INPUT ACCEPT
  $IPT -t filter -P OUTPUT ACCEPT
  $IPT -t filter -P FORWARD ACCEPT
}

if [ ! -f "$IPT" ] || [ ! -x "$IPT" ] || [ ! -f "$IPS" ] || [ ! -x "$IPS" ] ; then
  echo "Need iptables and ipset installed"
  exit 1
fi

if [ "$1" == "clearfw" ] ; then
  clearfw
  exit 0
fi

######## IPV4 ##############

clearfw

$IPS add vpnnets 192.168.192.0/22

$IPT -t filter -A FORWARD -m set --match-set vpnnets src -j ACCEPT

$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state ESTABLISHED  -j ACCEPT
$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state RELATED  -j ACCEPT
$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state INVALID  -j DROP
$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -j DROP

$IPT -t nat -A POSTROUTING -m set --match-set vpnnets src -m set ! --match-set vpnnets dst -j MASQUERADE

exit 0
