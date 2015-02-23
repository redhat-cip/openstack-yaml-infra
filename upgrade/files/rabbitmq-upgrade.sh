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

# Manage RabbitMQ-server upgrade

set -e
set -x

erlang_cookie_env=$1
erlang_cookie_real=$(cat /var/lib/rabbitmq/.erlang.cookie)

if [ -z "$erlang_cookie_env" ]; then
  echo "erlang_cookie is a new required parameter in your environment."
  echo "Please read carefully http://spinalstack.enovance.com/en/latest/deploy/components/rabbitmq.html#upgrade-from-i-1-3-0-to-j-1-0-0"
  exit 1
elif [ "$erlang_cookie_env" != "$erlang_cookie_real" ]; then
  echo "erlang_cookie from your env is different from the cookie already in place."
  # stop the service properly
  service rabbitmq-server stop || true
  # ensure no process is still running so we can delete the cookie & restart the process later
  for bin in epmd rabbitmq-server beam.smp
  do
    pkill -9 $bin || true
    echo $erlang_cookie_env>/var/lib/rabbitmq/.erlang.cookie
  done
fi

exit 0
