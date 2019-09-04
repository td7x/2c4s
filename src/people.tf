data "local_file" "people_config" {
  filename = "${path.module}/../people.yaml"
}


locals {
  people_config = yamldecode(data.local_file.people_config.content)
}


locals {

  members_defaults = {
    role = "member"
  }

  members = {
    for k, v in local.people_config :
    k => merge(local.members_defaults, v)
  }

}



resource "github_membership" "members" {
  for_each = local.members
  username = each.value.username
  role     = each.value.role
}
