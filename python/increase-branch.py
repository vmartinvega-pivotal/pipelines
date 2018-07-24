#!/usr/bin/python

import sys

if __name__ == "__main__":
  branch = str(sys.argv[1])

  major,minor = branch.split('.')

  print major + "." + str((int(minor) + 1))
