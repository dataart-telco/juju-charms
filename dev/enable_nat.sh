#!/bin/bash

# guide - http://unix.stackexchange.com/questions/126595/iptables-forward-all-traffic-to-interface

sudo iptables -t nat -A POSTROUTING --out-interface eth1 -j MASQUERADE  
sudo iptables -A FORWARD --in-interface eth0 -j ACCEPT
