import strutils, strformat
import std/asyncnet
import std/times
import std/net
import os
import asyncdispatch
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
        flag("-b", "--banner", help="Grab the banner for each open port")
        arg("target")
    target: string
    grab_banner: bool

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

proc scan() = 
    echo fmt"[*] Starting scan on {target}"
    let time = cpuTime()

    var futures = newSeq[Future[PortState]]()

    for port in 1..PORTS_TO_SCAN:
        futures.add(scan_port_async(port))
    
    open_ports = waitFor all(futures)

    echo "\n" & fmt"[!] Results for {target}:" & "\n"
    for port in open_ports:
        if port.open:
            echo fmt"{port.port} open {port.banner}"

    echo "\n" & fmt"[*] Finished scanning {PORTS_TO_SCAN} ports on {target} in {cpuTime() - time}s" & "\n"

when isMainModule:
    stdout.write dedent """
              ,             
    ._  _ ._.-+- __ _. _.._ 
    [_)(_)[   | _) (_.(_][ )
    |
    """ & "\n"
    try:
        let opts = p.parse()
        target = opts.target
        if not isIpAddress(target):
            raise newException(UsageError, fmt"[!] {target} is not a valid IPv4 address")
        grab_banner = opts.banner
        scan()
    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
        quit(1)
    except UsageError:
        echo p.help
        echo getCurrentExceptionMsg()
        quit(1)