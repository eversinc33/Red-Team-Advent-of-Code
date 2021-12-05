#!/bin/env python

# did not find any way to do this in nim, so I had to use python here :(

import os
import sys
from scapy.layers.inet import TCP, IP, sr1

def scan(target_ip, zombie_ip, port):
    # 1) get ip_id of zombie with a synack
    ip_packet = sr1(IP(dst=zombie_ip)/TCP(sport=1337,dport=(7331),flags="SA"), verbose=3)
    initial_ip_id = ip_packet.id
    
    print(f"[*] Zombie's IP ID: {initial_ip_id}")

    # spoof zombie ip and send syn to target
    sr1(IP(dst=target_ip,src=zombie_ip)/TCP(sport=138, dport=(int(port)), flags="S"), verbose=3, timeout=5)
    # synack to the zombie and check if id incremented
    ip_packet = sr1(IP(dst=zombie_ip)/TCP(sport=1339    , dport=(7331), flags="SA"), verbose=3, timeout=5)
    current_ip_id = ip_packet.id

    print(f"[*] Zombie's new IP ID: {current_ip_id}")

    if current_ip_id - initial_ip_id > 1:
        print(f"[*] Port {port} on {target_ip} is open")
    else:
        print(f"[-] Port {port} on {target_ip} is closed")

if __name__ == '__main__':

    print('''
      o$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$o
   o$$$$$$$$        $$$$$$$$$        $$$$$$$$$o
  $$$$$$$$$$$      $$$$$$$$$$$      $$$$$$$$$$$$
 $$$$$$$$$$$$$$    $$$$$$ $$$$$$    $$$$$$$$$$$$$$
o$$$$$$$$$$$$$$$ $$$$$$$   $$$$$$$ $$$$$$$$$$$$$$$
o$$$$$$$$$$$$$$$$$$$$$$     $$$$$$$$$$$$$$$$$$$$$$$
$$$$$  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$   o$$
 $$$$    $$$$  ""$$$$$$$$$$$$$$$$$""  $$$$   o$$$
  "$$$$o         $$$$  $$$$$   $$$          o$$$
    $$$$o   .     ""  """""   ""       .  $$$"
       "$$$$$$$$$    o$$$$   $$$$   $$$$$""
          ""$$$$$$ooo$$$$$ooo$$$$$$$$$""
''')
    if len(sys.argv) != 4:
        print("Usage: zombiescan.py <TARGET_IP> <ZOMBIE_IP> <PORT>")
        sys.exit(1)

    print(f"[ooOOooo] Starting zombie scan on zombie {sys.argv[2]}...")
    scan(sys.argv[1], sys.argv[2], sys.argv[3])