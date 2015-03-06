# Ansible snippets

## Best practices

* The snippet title should match a snippet in upgrade.yaml.
* Each task should contain a tag.
* If you need to run a task only on a specific hostgroup member use this syntax:
  groups['fakehostgroup'][-1] for example. The "fakehostgroup" will be replaced
by the right profile name during the generate step.

## Tags

* 1: Reserved for first actions
* 2: Resources evacuation
* 3: OpenStack stop (if needed)
* 4: Infra services stop (if needed)
* 5 (reserved): eDeploy upgrade only.
* 6: Infra services start
* 7: OpenStack
* 8: OpenStack
* 9: reserved for last actions

Infra services: HAproxy, Keepalived, MySQL, MongoDB, memcached, Redis
