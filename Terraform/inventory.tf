# Make hosts and ssh-config for bastion
/*
locals {
  ## Customization for different clouds (can be moved to variables)
  # Should be something convenient or human readable
  name_attribute = "name"
  # Map of tags or labels with "ansible_groups" key existing with comma separated list of Ansible groups
  group_tag = "labels"
  # List of instances created
  instances = concat(
    [for virtm in yandex_compute_instance.vm : virtm]
      # [for virtm in yandex_compute_instance_group.ig-1.instance_template : virtm]
  )
  ## Calculation
  group_hosts = {
    for target in local.instances :
    target[local.name_attribute] => merge({ for k, v in target : k => v }, tomap({"ansible_host" = target.network_interface.0.ip_address}))
    if(target[local.group_tag] != null ? lookup(target[local.group_tag], "ansible_groups", "") != "" : false)
  }
  no_group_hosts = {
    for target in local.instances :
    target[local.name_attribute] => merge({ for k, v in target : k => v }, tomap({"ansible_host" = target.network_interface.0.ip_address}))
    if(target[local.group_tag] != null ? lookup(target[local.group_tag], "ansible_groups", "") == "" : true)
  }
  groups = distinct(flatten([
    for target, data in local.group_hosts : [
      for group in split(",", data[local.group_tag]["ansible_groups"]) : group
    ]
  ]))

  ## Inventory generation in YAML Format
  inventory = {
    all = {
      hosts = local.no_group_hosts
      children = {
        for group in local.groups : group => {
          hosts = {
            for target, data in local.group_hosts : target => data
            if contains(split(",", data[local.group_tag]["ansible_groups"]), group)
          } } } } }
}
*/
/*
#Create hosts
resource "local_file" "inventory" {
  for_each = {
    #yaml = yamlencode(local.inventory)
    ini = templatefile(
      format("%s/templates/inventory.ini.hcl", path.module),
      {
        hosts  = local.inventory.all.hosts
        groups = local.inventory.all.children
      }
    )
  }
  content  = each.value
  filename = pathexpand("~/dip-zabb/Ansible/hosts")
}
output "inventory_files" {
  value = { for ext, file in local_file.inventory : ext => file.filename }
}
*/
/*
#Create config
resource "local_file" "config" {
  for_each = {
    #yaml = yamlencode(local.inventory)
    ini = templatefile(
      format("%s/templates/config.ini.hcl", path.module),
      {
        hosts  = local.inventory.all.hosts
        groups = local.inventory.all.children
      }
    )
  }
  content  = each.value
  filename = pathexpand("~/.ssh/config")
}
output "config_files" {
  value = { for ext, file in local_file.config : ext => file.filename }
}
*/