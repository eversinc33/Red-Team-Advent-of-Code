import std/smtp
import std/os
import std/streams
import std/strformat
import argparse

let 
    USERNAME = getEnv("MAIL_USER", "")
    PASSWORD = getEnv("MAIL_PW", "")
    SMTP_SERVER = getEnv("MAIL_SRV", "")

type
    victim = ref object
        first_name: string
        last_name: string
        job_title: string
        company: string
        email: string

var 
    p = newParser:
        arg("targets")
        arg("mail")

proc parse_targets_file(targets_file_csv: string): seq[victim] =
    var victims: seq[victim] = @[]

    let f = open(targets_file_csv, fmRead)
    defer: f.close()
    
    if not isNil(f):
        var victim_data = f.readAll.split(',')
        victims.add(victim(
            first_name: victim_data[0],
            last_name: victim_data[1],
            job_title: victim_data[2],
            company: victim_data[3],
            email: victim_data[4],
        ))

    return victims


proc parse_template(victim: victim, template_file: string): string =
    let f = open(template_file, fmRead)
    defer: f.close()
    
    if not isNil(f):
        return cast[string](
            f.readAll()
        ).replace(
            "$first_name", victim.first_name
        ).replace(
            "$last_name", victim.last_name
        ).replace(
            "$job_title", victim.job_title
        ).replace(
            "$company", victim.company
        )
    else:
        echo fmt"[!] Could not open file {template_file}"
        quit(1)

proc send_mail(victim: victim, msg_body: string) =  
    echo fmt"[*] Sending mail to {victim.last_name}, {victim.first_name} ({victim.job_title}@{victim.company}): {victim.email}..."

    var msg = createMessage(
        "Hi there",
        msg_body,
        @[victim.email]
    )
    let smtpConn = newSmtp(debug=true)
    smtpConn.connect(SMTP_SERVER, Port 2525)
    smtpConn.startTls()
    smtpConn.auth(USERNAME, PASSWORD)
    smtpConn.sendmail("username@gmail.com", @["foo@gmail.com"], $msg)

proc run_campaign(targets_file_csv: string, mail_template_file: string) =
    echo "[*] starting campaign..."
    for victim in parse_targets_file(targets_file_csv):
        var msg = parse_template(victim, mail_template_file)
        send_mail(victim, msg)
    echo "[*] campaign finished. good luck"

when isMainModule:
    stdout.write dedent """
<>< <>< <>< <>< <>< <>< <><
""" & "\n"
    try:
        if SMTP_SERVER == "" or PASSWORD == "" or USERNAME == "":
            echo "[!] You need to supply SMTP_SERVER, PASSWORD and USERNAME as environment variables to send mails"  
            quit(1)
        let opts = p.parse()
        run_campaign(opts.targets, opts.mail);
    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
        quit(1)
    except UsageError:
        echo p.help
        echo getCurrentExceptionMsg()
        quit(1)