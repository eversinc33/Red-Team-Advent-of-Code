import jester, asyncdispatch

var
  current_command = ""

router myrouter:
  get "/":
    resp current_command
  post "/":
    echo request.formData
    resp "Thank you fellow bot :)"
  put "/":
    current_command = request.formData["data"].body
    resp "OK"

when isMainModule:
  let jester_settings = newSettings(port=Port(8080))
  var j = initJester(myrouter, settings=jester_settings)
  j.serve()