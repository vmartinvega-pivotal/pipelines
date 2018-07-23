#!/usr/bin/python

import ruamel.yaml
from ruamel.yaml.util import load_yaml_guess_indent

import sys

if __name__ == "__main__":
  file_name = str(sys.argv[1])
  new_branch = str(sys.argv[2])
  repo_names = str(sys.argv[3]).split(',')

  config, ind, bsi = load_yaml_guess_indent(open(file_name))
  resources = config['resources']
  for resource in resources:
    if resource['source'] > 0:
      if resource['name'] in repo_names:
        resource['source']['branch'] = new_branch

  ruamel.yaml.round_trip_dump(config, open('output.yml', 'w'), indent=ind, block_seq_indent=bsi)
