#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import json
import socket


def get_host_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('114.114.114.114', 80))
        ip = s.getsockname()[0]
    finally:
        s.close()
    return ip

ip = get_host_ip()
os.environ['ip'] = str(ip)

cmd1 = os.popen("""netstat -nlpt | grep -v -w - | grep -v rpc | awk -F "[ :]+" '{if($4 ~ /0.0.0.0/ || $4 ~ /127.0.0.1/ || $4 ~ /'$ip'/) print $5}'""")
cmd2 = os.popen("""netstat -nlpt  | grep -Po ':::\K\d+'""")

ports = []
tmp_ports = []
new_ports = []
for cmd in cmd1,cmd2:
    for port in cmd.readlines():
        tmp_ports.append(port.strip())

for port in tmp_ports:
    if port not in new_ports:
        new_ports.append(port)

for i in new_ports:
    ports += [{'{#PORT}':i}]

print json.dumps({'data': ports}, sort_keys=True, indent=4, separators=(',', ':'))
