#!/usr/bin/python

import sys

if __name__ == "__main__":
  branch = str(sys.argv[1])
  action = str(sys.argv[2])

  major,minor = branch.split('.')

  if action == 'increase':
    print major + "." + str((int(minor) + 1))
  
  if action == 'decrease':
    print major + "." + str((int(minor) - 1))