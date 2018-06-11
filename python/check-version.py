#!/usr/bin/python

import re   
import sys

if __name__ == "__main__":
  reg = str(sys.argv[1])
  val = str(sys.argv[2])
  branchname = str(sys.argv[3])

  m = re.search(reg, val)

  if m:
    if str(m.group(0)).startswith(branchname):
      print "true"
    else:
      print "false"
  else:
    print "false"
