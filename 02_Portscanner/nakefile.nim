import nake

const
  ExeName = "portscan"
  as_release = "-d:release"

task "build", "Build executable in release mode":
  shell(nimExe, "c", as_release, ExeName)