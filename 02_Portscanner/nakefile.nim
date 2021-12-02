import nake

const
  ExeName = "portscan"
  with_threading = "--threads:on"
  as_release = "-d:release"

task "build", "Build executable in release mode":
  shell(nimExe, "c", with_threading, as_release, ExeName)