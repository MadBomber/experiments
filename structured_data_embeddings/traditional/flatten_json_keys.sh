#!/usr/bin/env bash

jq -r 'def flatten_keys: to_entries | .[] | if .value | type == "object" then .value |
  flatten_keys | .key = "\(.key)." + .key else if .value | type == "array" then .value |
  to_entries | .[] | if .value | type == "object" then .value | flatten_keys | .key = "\(.key)["
  + "\(.key)" + "]" + "." + .key else "\(.key)[" + "\(.key) + "] = \(.value)" end end else
  "\(.key) = \(.value)" end; flatten_keys' input.json > output.txt