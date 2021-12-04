import std/strutils, std/strformat
import std/asyncnet
import std/times
import std/net
import std/os
import std/osproc
import std/asyncdispatch
import argparse

type
    PortState = ref object 
        port: int
        open: bool
        banner: string

const
    PORTS_TO_SCAN: int = 10_000
    SOCKET_TIMEOUT_SECONDS: int = 10

var 
    open_ports: seq[PortState]
    p = newParser:
        flag("-b", "--banner", help="Grab the banner for each open port.")
        flag("-o", "--os-detection", help="Guess the target's operating system based on its ping TTL.")
        arg("target")
    target: string
    grab_banner: bool
    detect_os: bool

proc scan_port_async(port: int): Future[PortState] {.async.} =
    var s = newAsyncSocket()

    let future = connect(s, target, Port(port))
    yield future
    
    if future.failed:
        s.close()
        return PortState(port:port, open:false)
    
    else:
        echo fmt"[*] found open port: {port}"

        var banner_grabbed: string
        if grab_banner:
            var banner = s.recvLine()
            if await withTimeout(banner, SOCKET_TIMEOUT_SECONDS*1000):
                banner_grabbed = await banner

        s.close()
        return PortState(port:port, open:true, banner:banner_grabbed)

proc detect_os_ttl(): string =
    echo "    Trying to detect OS..."
    var ping: tuple[output: string, exit_code: int]

    when system.hostOS == "windows":
        ping = execCmdEx("ping -n 1 " & target)
    else:
        ping = execShellCmd("ping -c 1 " & target)

    if ping.exit_code == 0:
        let ttl: int = parseInt(ping.output.toLower().split("ttl=")[1].split("\n")[0])
        echo fmt"    ...ping has TTL of {ttl}"

        # hops are assumed to be <30
        if 98 < ttl and ttl < 128:
            return "Windows"
        if 34 < ttl and ttl < 64:
            return "Linux"
        if 225 < ttl and ttl < 255:
            return "Linux"
    else:
        echo "[!] Host not responding to ping. Is it up?"
    
    return "Unknown"
    

proc scan() = 
    echo fmt"[*] Starting scan on {target}"

    var target_os = "Enable os detection with -o"
    if detect_os: 
        target_os = detect_os_ttl()

    let time = cpuTime()

    var futures = newSeq[Future[PortState]]()

    for port in 1..PORTS_TO_SCAN:
        futures.add(scan_port_async(port))
    
    open_ports = waitFor all(futures)
    echo fmt"[*] Finished scanning {PORTS_TO_SCAN} ports on {target} in {cpuTime() - time}s" & "\n"

    echo fmt"Results for {target}:"
    echo fmt"OS: {target_os} (guessing based on ping TTL)" & "\n"
    
    var t_header = "Port State"
    if grab_banner: t_header = t_header & " Banner"

    echo t_header
    for port in open_ports:
        if port.open:
            echo fmt"{port.port} open {port.banner}"

    echo ""
    

when isMainModule:
    stdout.write dedent """
⡆⣐⢕⢕⢕⢕⢕⢕⢕⢕⠅⢗⢕⢕⢕⢕⢕⢕⢕⠕⠕⢕⢕⢕⢕⢕⢕⢕⢕⢕
⢐⢕⢕⢕⢕⢕⣕⢕⢕⠕⠁⢕⢕⢕⢕⢕⢕⢕⢕⠅⡄⢕⢕⢕⢕⢕⢕⢕⢕⢕
⢕⢕⢕⢕⢕⠅⢗⢕⠕⣠⠄⣗⢕⢕⠕⢕⢕⢕⠕⢠⣿⠐⢕⢕⢕⠑⢕⢕⠵⢕
⢕⢕⢕⢕⠁⢜⠕⢁⣴⣿⡇⢓⢕⢵⢐⢕⢕⠕⢁⣾⢿⣧⠑⢕⢕⠄⢑⢕⠅⢕
⢕⢕⠵⢁⠔⢁⣤⣤⣶⣶⣶⡐⣕⢽⠐⢕⠕⣡⣾⣶⣶⣶⣤⡁⢓⢕⠄⢑⢅⢑
⠍⣧⠄⣶⣾⣿⣿⣿⣿⣿⣿⣷⣔⢕⢄⢡⣾⣿⣿⣿⣿⣿⣿⣿⣦⡑⢕⢤⠱⢐
⢠⢕⠅⣾⣿⠋⢿⣿⣿⣿⠉⣿⣿⣷⣦⣶⣽⣿⣿⠈⣿⣿⣿⣿⠏⢹⣷⣷⡅⢐
⣔⢕⢥⢻⣿⡀⠈⠛⠛⠁⢠⣿⣿⣿⣿⣿⣿⣿⣿⡀⠈⠛⠛⠁⠄⣼⣿⣿⡇⢔
⢕⢕⢽⢸⢟⢟⢖⢖⢤⣶⡟⢻⣿⡿⠻⣿⣿⡟⢀⣿⣦⢤⢤⢔⢞⢿⢿⣿⠁⢕
⢕⢕⠅⣐⢕⢕⢕⢕⢕⣿⣿⡄⠛⢀⣦⠈⠛⢁⣼⣿⢗⢕⢕⢕⢕⢕⢕⡏⣘⢕
⢕⢕⠅⢓⣕⣕⣕⣕⣵⣿⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣷⣕⢕⢕⢕⢕⡵⢀⢕⢕
⢑⢕⠃⡈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢃⢕⢕⢕
⣆⢕⠄⢱⣄⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢁⢕⢕⠕⢁
⣿⣦⡀⣿⣿⣷⣶⣬⣍⣛⣛⣛⡛⠿⠿⠿⠛⠛⢛⣛⣉⣭⣤⣂⢜⠕⢑⣡⣴⣿
   ~ open port best port ~
    """ & "\n"
    try:
        let opts = p.parse()
        target = opts.target
        if not isIpAddress(target):
            raise newException(UsageError, fmt"[!] {target} is not a valid IPv4 address")
        grab_banner = opts.banner
        detect_os = opts.os_detection
        scan()
    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
        quit(1)
    except UsageError:
        echo p.help
        echo getCurrentExceptionMsg()
        quit(1)