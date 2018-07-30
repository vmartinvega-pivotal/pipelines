#!/usr/bin/python

from xml.etree import ElementTree as et

import sys

if __name__ == "__main__":
  ns = "http://maven.apache.org/POM/4.0.0"

  #for filename in sys.argv[1:len(sys.argv)]:
  filename = str(sys.argv[1])
  outfile = str(sys.argv[2])

  tree = et.parse(filename)
  root = tree.getroot()

  for dependency in root.findall("./{%s}dependencies/{%s}dependency" % (ns, ns)):
    groupId = dependency.find("{%s}groupId" % ns).text
    artifactId = dependency.find("{%s}artifactId" % ns).text
    version = dependency.find("{%s}version" % ns).text
    with open(outfile, 'a') as outputfile:
      outputfile.write(groupId + ":" + artifactId + ":jar:" + version + ":compile" + '\n')
    
    