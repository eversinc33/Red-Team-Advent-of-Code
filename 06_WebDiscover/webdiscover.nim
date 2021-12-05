import std/asyncdispatch
import std/httpclient
import std/streams
import std/strformat
import std/times
import argparse

type 
    HttpResult = ref object
        url: string
        state: int

var 
    p = newParser:
        arg("target")
        arg("wordlist")

proc get_async(url: string): Future[HttpResult] {.async.} = 
    let client = newAsyncHttpClient()
    let future = client.get(url)
    yield future
    if future.failed:
        echo fmt"[!] error connecting to {url}"
        return HttpResult(url: url, state: 0)
    else:
        let resp = future.read()
        if resp.code != Http404:
            echo fmt"[{resp.code}] {url}"
        return HttpResult(url: url, state: int(resp.code)) 

proc discover(target: string, wordlist: string) =
    echo fmt"[*] Starting scan on {target}" & "\n"
    let time = cpuTime()

    var futures = newSeq[Future[HttpResult]]()
    
    let f = newFileStream(wordlist, fmRead)
    defer: f.close()

    var line = ""
    if not isNil(f):
        while f.readLine(line):
            futures.add(get_async(target & "/" & line))
    else:
        echo fmt"[!] Could not open file {wordlist}"
        quit(1)

    discard waitFor all(futures)
    echo "\n" & fmt"[*] Finished scanning {len(futures)} URLs in {cpuTime() - time}s" & "\n"


when isMainModule:
    stdout.write dedent """
     /___/\_
    _\   \/_/\__  
  __\       \/_/\ 
  \   __    __ \ \                    
 __\  \_\   \_\ \ \   __           
/_/\\   __   __  \ \_/_/\          
\_\/_\__\/\__\/\__\/_\_\/         
   \_\/_/\       /_\_\/          
      \_\/       \_\/     
...grabbing links for you...
""" & "\n"
    try:
        let opts = p.parse()
        discover(opts.target, opts.wordlist)
    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
        quit(1)
    except UsageError:
        echo p.help
        echo getCurrentExceptionMsg()
        quit(1)