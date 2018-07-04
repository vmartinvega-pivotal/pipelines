#!/usr/bin/python

import sys
import os
import re
import json

if __name__ == "__main__":

  try:
      #Check argument number
      if len(sys.argv) > 5 or len(sys.argv) < 5:
          print("Invalid argument number. Usage: file_process.py list_file(path) template_file(path) output_file(path) properties_output_file(path)")
          sys.exit()

      listfile = str(sys.argv[1])
      templatefile = str(sys.argv[2])
      resultfile = str(sys.argv[3])
      propertiesfile = str(sys.argv[4])

      # Check parameters
      if not os.path.isfile(listfile):
         print("List file {} does not exist. Exiting...".format(listfile))
         sys.exit()

      if not os.path.isfile(templatefile):
         print("Template file {} does not exist. Exiting...".format(templatefile))
         sys.exit()

      if os.path.isfile(resultfile):
         print("Output file already exist. Exiting...".format(resultfile))
         sys.exit()

      if os.path.isfile(propertiesfile):
         print("Properties file already exist. Exiting...".format(propertiesfile))
         sys.exit()

      # Open and get through it line by line
      with open(templatefile) as tf:
           for line in tf:
               # Search and match valid Regex line
               line_tf_match = re.search('(.+?)://(.+?):#VERSION#', line)
               line_tf_match = re.search('(.+?)\.(.+?)=maven://(.+?):#VERSION#', line)
               if line_tf_match:
                    template_line = line_tf_match.group(3)
                    init_line = line_tf_match.group(1) + "." + line_tf_match.group(2) + "=maven"
                    app_name = line_tf_match.group(2).upper().replace('-', '_') 
                    print("Template line found: " + template_line)

                    founded_version = False

                    with open(listfile) as lf:
                         # Search template line in the dependencies list file

                         for line_lf in lf:
                             line_lf_match = re.search(template_line, line_lf)
                             if line_lf_match:
                                 list_line = line_lf_match.group(0)
                                 print("List line found: " + list_line)
                                 reg_version = template_line + ':(.+?):(.+):'
                                 version_match = re.search(reg_version, line_lf)
                                 # If found it, get the version and write in the output file
                                 if version_match:
                                      version = version_match.group(2)
                                      print("Version for this line: " + version)
                                      output = template_line + ":" + version
                                      print("Output for this line: " + output)
                                      with open(resultfile, 'a') as outputfile:
                                          outputfile.write(init_line + "://" + output + '\n')
                                          founded_version = True
                                      with open(propertiesfile, 'a') as outputfile:
                                          outputfile.write(app_name + "=" + version + '\n')

                         # If not found the version for this line, write to the output file with special tag #VERSION#
                         if not founded_version:
                             print("Version for this line not found: " + template_line)
                             with open(resultfile, 'a') as outputfile:
                                 outputfile.write(init_line + "://" + template_line + ":#VERSION#" + '\n')

                         # Close files
                         if not lf.closed:
                             lf.close()
               else:
                   with open(resultfile, 'a') as outputfile:
                       outputfile.write( line)

      # Close files
      if not tf.closed:
        tf.close()

  except Exception as e:
      print( e)



