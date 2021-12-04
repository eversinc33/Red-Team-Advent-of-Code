# Advent of Code 2021

These are my Advent-Of-Code style challenges for red teaming / pentesting / IT-Security. 

The challenges are separated into different modules:
* Setup
* Reconaissance
* Phishing
* Exploitation
* Basic Windows Malware Development
* Antivirus Evasion

**DISCLAIMER**: Prior experience in programming and, for the later modules (especially AV evasion), pentesting and security is required. These are not beginner-challenges! So do not be discouraged if a challenge is too hard for you. Just follow along a tutorial or just read something about the topic instead. The point is to get your feet wet and let you dive into the topic, not to do these challenges without help.

I decided to take the opportunity to learn more about [Nim](https://github.com/nim-lang/Nim) this year by writing all challenges in nim.

### Day 1: Lab Setup

Since you will have to test your scripts on a Windows Host (and since you don't want to infect your own host with your malware), you should setup a VM environment as a lab.

Day | Challenge | Description 
---|---|---
1 | Setup a Lab | Create a Lab consisting of a Windows Pro host (use a evaluation iso) and a Kali machine.

### Day 2-6: Reconnaissance

In any pentest or engagement, reconnaissance is the first thing to do. Here we take some easy challenges to warm up. I recommend using either a scripting language such as Python or Ruby, or a high-performance language such as Go or Rust for these challenges, but any language is possible.

Day | Challenge | Description
---|---|---
[2](./02_Portscanner) | Port Scanner | Write a basic TCP port scanner. Bonus: Multithreading 
[3](./03_BannerGrab) | Banner grabbing | Add the functionality to grab the banner of every open port 
[4](./04_OSDetection) | OS Detection | Add the functionality to detect the OS (Linux/Windows/other) 
5 | Zombie Scanning | Add [Zombie Scanning/Idle Scanning](https://nmap.org/book/idlescan.html) 
6 | Directory Bruteforcer | Write a tool to discover valid pages on a webserver (think dirb, ffuf) 

### Day 7-8: Initial Access: Phishing

Since phishing is one of the easiest ways to get into a system, we need to give it some attention here. A scripting language with a templating system is probably the easiest choice here, my choice would be python. But as above, any language is possible.

Day | Challenge | Description
---|---|---
7 | Phishing Server | Write a script that clones a website (e.g. citrix login page) and hosts it. Record any Form submits to log credentials entered by victims. 
8 | Mail generator | Write a script that parses an Email-template and a list of victim data and fills in Names, Job Roles and the phishing URL and sends out a mail to the victims email address.

### Day 9-10: Exploitation

The following challenges are not coding challenges, but rather practical exeercises that aim at getting you into exploitation of vulnerabilities.

Day | Challenge | Description 
---|---|---
9 | Buffer Overflow Exploitation | Do a buffer overflow on a Boot-To-Root box (e.g. Vulnserver). Follow a tutorial if you have not done this before 
10 | HackTheBox | Try any box on [HackTheBox](https://www.hackthebox.eu)

### Day 11-14: Basic Windows Malware-Development/Post-Exploitation

This intro to malware development should mostly be done in a language that has access to the Windows APIs such as C, C++, C#, Powershell or Nim. The C2 can be written in any language.

Day | Challenge | Description
---|---|---
11 | Keylogger | Write a Keylogger that records keystrokes
12 | Screengrabber | Add the functionality that a screenshot is taken every X seconds. Optionally add Webcam shots too.
13 | Persistence | Add persistence (e.g. via adding to autostart)
14 | C2 Functionality | Create a basic Command and Control Server (C2) that serves commands to the keylogger. The keylogger asks each X seconds for what to do (e.g. take a screenshot, send recorded key inputs) on a set url (e.g. http://192.168.2.10/task).

### Day 15-22: Antivirus Evasion

You can check your keylogger from the previous module against virustotal, it likely won't be caught by many antivirus solutions. Getting C2 implants such as a meterpreter payload generated by msfvenom past AV is much harder though. Here we are gonna learn about techniques to obfuscate shellcode, inject it into processes and evade antivirus sandboxing. I highly recommend using C#, C++, C or Nim here. The encoders and AMSI bypass obfuscator can be written in any language.

As stated above, this is not beginner content. Feel free to slow down the pace or just read about these topics instead if you feel overwhelmed. Don't worry if you do not understand this stufd (yet :) ).

Day | Challenge | Description 
---|---|---
15 | Caesar Cipher | Write a tool that applies a Caesar Cipher to a binary payload 
16 | XOR Encoder | Write a tool that takes a key and applies an XOR cipher to a binary payload 
17 | Process Hollowing | Write a tool that takes a binary payload and spawns another process in which the payload is injected and executed 
18 | DLL Injection | Write a tool that creates a DLL and causes another application to load the DLL and execute its code
19 | Another injection technique | Lookup another technique and use it to inject shellcode
20 | Sandbox Detection | Add Antivirus-Evasion techniques to your injectors from Day 17/18, e.g. check if you are in sandbox by checking the amount of CPU cores or check if a sleep statement is actually execute or skipped by the AV's sandbox. Lookup "AV evasion sandbox detection".
21 | Meterpreter Injector | Use the above to get a meterpreter payload past Windows Defender. Check for sandboxing, then decrypt your (XOR or Caesar) encrypted shellcode and inject it into a process.
22 | AMSI Bypass Obfuscation Tool | Write a tool that takes Matt Graeber's One Line AMSI Bypass and obfuscates it randomly

### Day 23: Bonus Challenge

Day | Challenge | Description 
---|---|---
23 | Windows CVE PoC | Write a PoC for a Windows CVE (e.g. HiveNightmare/Serious Sam or PrintNightmare)

### Day 24: Celebrate

Day | Challenge | Description 
---|---|---
24 | Congratulate yourself | Congratulate yourself :)
