#!/usr/bin/python

import sys

if __name__ == "__main__":
  tag = str(sys.argv[1])
  version = str(sys.argv[2])

  if tag.endswith(version):
    print "true"
  else:
    print "false"
