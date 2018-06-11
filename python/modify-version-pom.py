#!/usr/bin/python

from xml.etree import ElementTree as et

import sys

if __name__ == "__main__":
  ns = "http://maven.apache.org/POM/4.0.0"

  try:
    register_namespace = et.register_namespace
  except AttributeError:
    def register_namespace(prefix, uri):
      et._namespace_map[uri] = prefix

  namespace = "%s" % (ns)
  register_namespace('', namespace)

  filename = str(sys.argv[1])
  filenameout = str(sys.argv[2])
  new_version = str(sys.argv[3])

  group = artifact = version = ""

  tree = et.ElementTree()
  tree.parse(filename)

  tree.getroot().find("{%s}version" % ns).text = new_version

  tree.write(filenameout)
