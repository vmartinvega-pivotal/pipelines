#!/usr/bin/python

import sys
import os
import re
import json
import uuid

if __name__ == "__main__":

  try:
      if len(sys.argv) > 6 or len(sys.argv) < 6:
          print("Invalid argument number. Usage: file_process.py list_file(path) appdescriptor_template_file(path) appdescriptor_file(path) apps_versions_template_file(path) apps_versions_file(path)")
          sys.exit()

      listfile = str(sys.argv[1])
      templatefile = str(sys.argv[2])
      resultfile = str(sys.argv[3])
      apps_versions_template_file = str(sys.argv[4])
      apps_versions_file = str(sys.argv[5])

      temporary_app_versions_template_file = apps_versions_template_file
      output_app_versions_temp_name = "/tmp/" + str(uuid.uuid4())[:8]

      # Open and get through it line by line
      with open(templatefile) as tf:
           for line in tf:
               # Search and match valid Regex line
               line_tf_match = re.search('(.+?)\.(.+?)=maven://(.+?):(.+?):#VERSION#', line)
               if line_tf_match:
                    template_line = line_tf_match.group(3) + ":" + line_tf_match.group(4) + ":jar:(.+?):compile" 
                    app_name = line_tf_match.group(1).upper() + "_" + line_tf_match.group(2).upper().replace('-', '_') + "_VERSION" 
                    
                    #print("Dependency line found: " + line)

                    with open(listfile) as lf:
                         # Search template line in the dependencies list file

                         for line_lf in lf:
                             line_lf_match = re.search(template_line, line_lf)
                             if line_lf_match: 
                                 version = line_lf_match.group(1)
                     
                                 with open(resultfile, 'a') as outputfile:
                                      outputfile.write(line_tf_match.group(1) + "." + line_tf_match.group(2) + "=maven://" + line_tf_match.group(3) + ":" + line_tf_match.group(4) + ":" + "${" + app_name + "}" + '\n')
                                                             
                                 #-- APPS VERSION TEMPLATE
                                 with open(temporary_app_versions_template_file) as avf:
                                      for line_avf in avf:
                                           line_avf_match = re.search(app_name.strip() + "=\"#VERSION#\"", line_avf)
                                           if line_avf_match:
                                                with open(output_app_versions_temp_name, 'a') as outputfile:
                                                     outputfile.write(app_name.strip() + "=\"" + version + "\"" '\n')
                                           else:
                                                with open(output_app_versions_temp_name, 'a') as outputfile:
                                                     outputfile.write(line_avf)                
                                      if not avf.closed:
                                           avf.close()

                                      temporary_app_versions_template_file = output_app_versions_temp_name
                                      output_app_versions_temp_name = "/tmp/" + str(uuid.uuid4())[:8]
                                 #-- APPS VERSION TEMPLATE

                         # Close files
                         if not lf.closed:
                             lf.close()
               else:
                   with open(resultfile, 'a') as outputfile:
                       outputfile.write(line)

      # Close files
      if not tf.closed:
        tf.close()

      #-- APPS VERSION OUTPUT
      with open(temporary_app_versions_template_file) as ocf:
           for line_ocf in ocf:
                with open(apps_versions_file, 'a') as outputfile:
                     outputfile.write(line_ocf)
           if not ocf.closed:
                ocf.close() 

  except Exception as e:
      print (e)



