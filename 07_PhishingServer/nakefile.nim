import nake
import std/os

const
  ExeName    = "sheeple"
  as_release = "-d:release"
  danger     = "-d:danger"
  with_ssl   = "-d:ssl"

task "build", "Build executable in release mode":
  shell(nimExe, "c", as_release, danger, with_ssl, ExeName)

task "clean", "Remove all built executables":
  when system.hostOS == "windows":
    if existsFile(ExeName & ".exe"):
      shell("rm", ExeName & ".exe")
  when system.hostOS == "linux" or system.hostOS == "macosx":
    if existsFile(ExeName):
      shell("rm", ExeName)