#!/usr/bin/python

from xml.etree import ElementTree as et

import sys

if __name__ == "__main__":
  ns = "http://maven.apache.org/POM/4.0.0"

  #for filename in sys.argv[1:len(sys.argv)]:
  filename = str(sys.argv[1])
  result = str(sys.argv[2])

  group = artifact = version = ""

  tree = et.ElementTree()
  tree.parse(filename)

  p = tree.getroot().find("{%s}parent" % ns)

  if p is not None:
    if p.find("{%s}groupId" % ns) is not None:
      group = p.find("{%s}groupId" % ns).text

    if p.find("{%s}version" % ns) is not None:
      version = p.find("{%s}version" % ns).text

    if p.find("{%s}artifactId" % ns) is not None:
      artifact = p.find("{%s}artifactId" % ns).text

  if tree.getroot().find("{%s}groupId" % ns) is not None:
    group = tree.getroot().find("{%s}groupId" % ns).text

  if tree.getroot().find("{%s}artifactId" % ns) is not None:
    artifact = tree.getroot().find("{%s}artifactId" % ns).text

  if tree.getroot().find("{%s}version" % ns) is not None:
    version = tree.getroot().find("{%s}version" % ns).text

  if result == 'version':
    print "%s" % (version)

  if result == 'artifact':
    print "%s" % (artifact)

  if result == 'group':
    print "%s" % (group)
