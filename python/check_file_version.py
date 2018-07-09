#!/usr/bin/python

import sys

if __name__ == "__main__":

  try:
      file_to_check = str(sys.argv[1])

      contains_version = False

      #-- FILE TO CHECK
      with open(file_to_check) as opf:
           for line_opf in opf:
                if line_opf.find("#VERSION#") != -1:
                  contains_version = True
                  break
           if not opf.closed:
                opf.close()               

      if contains_version:
           print "true"
      else:
           print "false"

  except Exception as e:
      print (e)



