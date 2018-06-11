#!/usr/bin/python

import re   
import sys

if __name__ == "__main__":
  reg = str(sys.argv[1])
  val = str(sys.argv[2])
  action = str(sys.argv[3])

  if action == "match":
    regex = re.compile(reg)

    if regex.match(val):
      print "true"
    
    else:
      print "false"
  
  if action == "find":
    index = int(sys.argv[4])
    
    m = re.search(reg, val)
    if m:
      print m.group(index)
    else:
      print "false"
