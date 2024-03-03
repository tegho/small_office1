#!/bin/bash

IPS=`which ipset`
IPT=`which iptables`

######## IPV4 ##############

$IPT -t filter -F
$IPT -t nat -F
$IPT -t mangle -F

$IPS -quiet destroy vpnnets
$IPS create vpnnets hash:net -exist
$IPS add vpnnets 192.168.56.0/24
$IPS add vpnnets 192.168.57.0/24

# default policy
$IPT -t filter -P INPUT ACCEPT
$IPT -t filter -P OUTPUT ACCEPT
$IPT -t filter -P FORWARD ACCEPT

#    ipsec debug
#    tcpdump -s 0 -n -i nflog:4
#  $IPT -t filter -I INPUT -m addrtype --dst-type LOCAL -m policy --pol ipsec --dir in -j NFLOG --nflog-group 4
#  $IPT -t filter -I FORWARD -m addrtype ! --dst-type LOCAL -m policy --pol ipsec --dir in -j NFLOG --nflog-group 4
#  $IPT -t filter -I OUTPUT -m policy --pol ipsec --dir out -j NFLOG --nflog-group 4

$IPT -t filter -A FORWARD -m set --match-set vpnnets src -j ACCEPT

$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state ESTABLISHED  -j ACCEPT
$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state RELATED  -j ACCEPT
$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -m state --state INVALID  -j DROP
$IPT -t filter -A FORWARD -m set --match-set vpnnets dst -j DROP

$IPT -t nat -A POSTROUTING -m set --match-set vpnnets src -m set ! --match-set vpnnets dst -j MASQUERADE
