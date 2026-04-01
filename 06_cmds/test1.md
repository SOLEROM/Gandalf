---
name: my-command
description: Runs a specific bash command
context: fork
allowed-tools:
  - Bash
---
#!/bin/bash
# Your bash script goes here
echo "Running my custom bash command!"
###./my_script.sh