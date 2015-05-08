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

# Migrate all instances from a compute server before upgrade

set -e
set -x

COMPUTE=$(cat /etc/hostname)
export OS_USERNAME=$1
export OS_TENANT_NAME=$2
export OS_PASSWORD=$3
export OS_AUTH_URL=$4
EXTRA_MIGRATE=

# number of time we loop to check if there are still servers
max_limit=10

if [ -z "$COMPUTE" ]; then
  echo "You have to provide the compute FQDN as a parameter."
  exit 1
fi

# Migrate all VM on another compute node
if ! fgrep "images_type=rbd" /etc/nova/nova.conf; then
  EXTRA_MIGRATE="--block-migrate"
fi

# Until compute has no more servers, we keep looping and migrate them,
# after full evacuation we disable nova-compute service to avoid new server
# scheduling.
compute_has_servers() {
  VMS=$(nova hypervisor-servers $COMPUTE | grep $COMPUTE | awk '{print $1}')
      if [ ! -z $VMS ]; then
          return 1
      else
          nova service-disable --reason upgrade $COMPUTE nova-compute
          return 0
      fi
}

migrate_servers() {
    local servers=$1
    for VM in $servers; do
        echo "Instance $VM is going to be migrated:"
        nova live-migration $EXTRA_MIGRATE $VM

        # test if the migration worked and the VM is still alive.
        if ! timeout 20 sh -c "while ! nova show $VM | grep status | grep -q ACTIVE; do sleep 1; done"; then
            echo "Instance $VM has failed to be migrated and is not active."
            exit 1
        fi
        if ! timeout 20  sh -c "while ! nova hypervisor-servers $COMPUTE | grep $COMPUTE | grep $VM; do sleep 1; done"; then
            echo "Instance $VM has failed to be migrated but is still active."
        else
            echo "Instance $VM has been successfully migrated and is active."
        fi
    done
}

# compute_has_servers function loop is here to avoid a race condition between
# end of scheduling and service disablement.
limit=0
while ! compute_has_servers; do
    # Avoid unlimited loop
    if [ "$limit" -gt "$max_limit" ]; then
        echo "After $max_limit loops, there are still servers scheduled on $COMPUTE node."
        echo "Fail here to avoid too long loop."
        exit 1
    fi
    # Extract all VMs hosted on this compute node
    VMS=$(nova hypervisor-servers $COMPUTE | grep $COMPUTE | awk '{print $2}')
    migrate_servers $VMS
    limit=$((limit + 1))
done

echo "All the instances have been migrated from $COMPUTE server."
exit 0
