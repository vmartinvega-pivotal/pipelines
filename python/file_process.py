#!/usr/bin/python

import sys
import os
import re
import json
import uuid

if __name__ == "__main__":

  try:
      #Check argument number
      #if len(sys.argv) > 12 or len(sys.argv) < 12:
      #    print("Invalid argument number. Usage: file_process.py list_file(path) template_file(path) output_file(path) template_collaudo_file(path) template_collaudo_file_output(path) template_prod_file(path) template_prod_file_output(path) template_systemtest_file(path) template_systemtest_file_output(path) file_maven_binaries(path)")
      #    sys.exit()
      if len(sys.argv) > 10 or len(sys.argv) < 10:
          print("Invalid argument number. Usage: file_process.py list_file(path) template_file(path) output_file(path) template_collaudo_file(path) template_collaudo_file_output(path) template_prod_file(path) template_prod_file_output(path)  file_maven_binaries(path)")
          sys.exit()

      listfile = str(sys.argv[1])
      templatefile = str(sys.argv[2])
      resultfile = str(sys.argv[3])
      template_collaudo_file = str(sys.argv[4])
      output_collaudo_file = str(sys.argv[5])
      template_prod_file = str(sys.argv[6])
      output_prod_file = str(sys.argv[7])
      #template_systemtest_file = str(sys.argv[8])
      #output_systemtest_file = str(sys.argv[9])
      output_maven_binaries_file = str(sys.argv[8])

      temporary_template_collaudo_file = template_collaudo_file
      output_collaudo_temp_name = "/tmp/" + str(uuid.uuid4())[:8]

      temporary_template_prod_file = template_prod_file
      output_prod_temp_name = "/tmp/" + str(uuid.uuid4())[:8]

      #temporary_template_systemtest_file = template_systemtest_file
      #output_systemtest_temp_name = "/tmp/" + str(uuid.uuid4())[:8]


      # Open and get through it line by line
      with open(templatefile) as tf:
           for line in tf:
               # Search and match valid Regex line
               line_tf_match = re.search('(.+?)\.(.+?)=https://(.+?)/jar/(.+?)-#VERSION#\.jar', line)
               if line_tf_match:
                    template_line = "(.+?):" + line_tf_match.group(4) + ":jar:(.+?):compile" 
                    app_name = line_tf_match.group(1).upper() + "_" + line_tf_match.group(2).upper().replace('-', '_') + "_VERSION" 
                    
                    #print("Dependency line found: " + line)

                    with open(listfile) as lf:
                         # Search template line in the dependencies list file

                         for line_lf in lf:
                             line_lf_match = re.search(template_line, line_lf)
                             if line_lf_match:
                                 version = line_lf_match.group(2)

                                 with open(output_maven_binaries_file, 'a') as outputmavenbinariesfile:                                 
                                      outputmavenbinariesfile.write(line_tf_match.group(1) + ":" + line_tf_match.group(2) + ":" + version + ":jar" '\n')
                                 

                                 with open(resultfile, 'a') as outputfile:
                                      outputfile.write(line_tf_match.group(1) + "." + line_tf_match.group(2) + "=https://" + line_tf_match.group(3) + "/jar/" + line_tf_match.group(4) + "-" + version + ".jar" '\n')
                                                             
                                 #-- COLLAUDO TEMPLATE
                                 with open(temporary_template_collaudo_file) as tcf:
                                      for line_tcf in tcf:
                                           line_tcf_match = re.search(app_name.strip() + "=\"#VERSION#\"", line_tcf)
                                           if line_tcf_match:
                                                with open(output_collaudo_temp_name, 'a') as outputcollaudofile:
                                                     outputcollaudofile.write(app_name.strip() + "=\"" + version + "\"" '\n')
                                           else:
                                                with open(output_collaudo_temp_name, 'a') as outputcollaudofile:
                                                     outputcollaudofile.write(line_tcf)                
                                      if not tcf.closed:
                                           tcf.close()

                                      temporary_template_collaudo_file = output_collaudo_temp_name
                                      output_collaudo_temp_name = "/tmp/" + str(uuid.uuid4())[:8]
                                 #-- COLLAUDO TEMPLATE

                                 #-- PRODUCTION TEMPLATE
                                 with open(temporary_template_prod_file) as tpf:
                                      for line_tpf in tpf:
                                           line_tpf_match = re.search(app_name.strip() + "=\"#VERSION#\"", line_tpf)
                                           if line_tpf_match:
                                                with open(output_prod_temp_name, 'a') as outputprodfile:
                                                     outputprodfile.write(app_name.strip() + "=\"" + version + "\"" '\n')
                                           else:
                                                with open(output_prod_temp_name, 'a') as outputprodfile:
                                                     outputprodfile.write(line_tpf)                
                                      if not tpf.closed:
                                           tpf.close()

                                      temporary_template_prod_file = output_prod_temp_name
                                      output_prod_temp_name = "/tmp/" + str(uuid.uuid4())[:8]
                                 #-- PRODUCTION TEMPLATE

                                 #-- SYSTEMTEST TEMPLATE
                                 #with open(temporary_template_systemtest_file) as tstf:
                                 #     for line_tstf in tstf:
                                 #          line_tstf_match = re.search(app_name.strip() + "=\"#VERSION#\"", line_tstf)
                                 #          if line_tstf_match:
                                 #               with open(output_systemtest_temp_name, 'a') as outputsystemtestfile:
                                 #                    outputsystemtestfile.write(app_name.strip() + "=\"" + version + "\"" '\n')
                                 #          else:
                                 #               with open(output_systemtest_temp_name, 'a') as outputsystemtestfile:
                                 #                    outputsystemtestfile.write(line_tstf)                
                                 #     if not tstf.closed:
                                 #          tstf.close()

                                 #     temporary_template_systemtest_file = output_systemtest_temp_name
                                 #     output_systemtest_temp_name = "/tmp/" + str(uuid.uuid4())[:8]
                                 #-- SYSTEMTEST TEMPLATE

                         # Close files
                         if not lf.closed:
                             lf.close()
               else:
                   with open(resultfile, 'a') as outputfile:
                       outputfile.write(line)

      # Close files
      if not tf.closed:
        tf.close()

      #-- COLLAUDO OUTPUT
      with open(temporary_template_collaudo_file) as ocf:
           for line_ocf in ocf:
                with open(output_collaudo_file, 'a') as outputcollaudofile:
                     outputcollaudofile.write(line_ocf)
           if not ocf.closed:
                ocf.close() 

      #-- PRODUCTION OUTPUT
      with open(temporary_template_prod_file) as opf:
           for line_opf in opf:
                with open(output_prod_file, 'a') as outputprodfile:
                     outputprodfile.write(line_opf)
           if not opf.closed:
                opf.close()               

      #-- SYSTEMTEST OUTPUT
      #with open(temporary_template_systemtest_file) as ostf:
      #     for line_ostf in ostf:
      #          with open(output_systemtest_file, 'a') as outputsystemtestfile:
      #               outputsystemtestfile.write(line_ostf)
      #     if not ostf.closed:
      #          ostf.close() 

  except Exception as e:
      print (e)



