#!/usr/bin/python

# This program checks that all versions in the pom.xml (Resolved versions for logical microservice) file
# match the regular expression "\d+\.\d+\.\d+"

from xml.etree import ElementTree as et
import re 

import sys

if __name__ == "__main__":
  ns = "http://maven.apache.org/POM/4.0.0"

  #for filename in sys.argv[1:len(sys.argv)]:
  filename = str(sys.argv[1])
  
  tree = et.parse(filename)
  root = tree.getroot()

  result = True

  for dependency in root.findall("./{%s}dependencies/{%s}dependency" % (ns, ns)):
    groupId = dependency.find("{%s}groupId" % ns).text
    artifactId = dependency.find("{%s}artifactId" % ns).text
    version = dependency.find("{%s}version" % ns).text
    regex = re.compile("\d+\.\d+\.\d+")

    if not regex.match(version):
      result = False
      break

  if result:
    print "true"
  else:
    print "false"
