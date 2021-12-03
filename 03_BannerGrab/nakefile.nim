import nake
import std/os

const
  ExeName = "portscan"
  as_release = "-d:release"

task "build", "Build executable in release mode":
  shell(nimExe, "c", as_release, ExeName)

task "clean", "Remove all build executables":
  when system.hostOS == "windows":
    if existsFile(ExeName & ".exe"):
      shell("rm", ExeName & ".exe")
  when system.hostOS == "linux" or system.hostOS == "macosx":
    if existsFile(ExeName):
      shell("rm", ExeName)