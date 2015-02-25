#!/bin/bash
#
# Copyright (C) 2015 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# This script aims to generate Ansible playbooks.
# Usage: ./test-upgrade.sh -c config -g global.yml
#

ORIG=$(cd $(dirname $0); pwd)

function show_help() {
  echo "usage: ./test-upgrade.sh -c config -g global.yml"
  echo "-c: config file, present in /etc/config-tools/config on install-server"
  echo "-g: global YAML file, present in /etc/config-tools/global.yml on install-server"
  exit 0
}

while getopts "c:g:h" opt; do
  case $opt in
    c ) CONFIG=$OPTARG;;
    g ) GLOBAL=$OPTARG;;
    h ) show_help;;
    * ) echo "Bad parameter" ; exit 1 ;;
  esac
done

if [ ! "$CONFIG" ]; then
  echo "-c parameter is empty, this parameter is required"
  exit 1
fi

if [ ! "$GLOBAL" ]; then
  echo "-g parameter is empty, this parameter is required"
  exit 1
fi

source $CONFIG

# cleanup
rm -rf $ORIG/ansible
rm -rf $ORIG/config-tools

git clone git@github.com:enovance/config-tools.git

mkdir -p $ORIG/ansible
for p in $PROFILES; do
  mkdir -p $ORIG/ansible/roles/$p/tasks $ORIG/ansible/roles/$p/files
  cp $ORIG/files/* $ORIG/ansible/roles/$p/files/
  cat $ORIG/snippets/edeploy.yaml > $ORIG/ansible/roles/${p}/tasks/main.yaml
  for role in $($ORIG/config-tools/extract.py -a "profiles.${p}.steps.*" $GLOBAL); do
    for class in $(echo "$role" | fgrep cloud | tr -d "'{}[],"); do
      for snippet in $($ORIG/config-tools/extract.py -a "${class}.snippet" $ORIG/upgrade.yaml); do
        cat $ORIG/snippets/${snippet}.yaml >> $ORIG/ansible/roles/${p}/tasks/main.yaml
      done
    done
  done
done

# test-upgrade.sh ends here
