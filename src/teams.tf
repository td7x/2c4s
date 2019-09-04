data "external" "team_files" {
  program = ["bash", "${path.module}/find-files.sh"]

  query = {
    filter      = "*.yaml"
    search_path = "../teams"
  }
}

locals {
  team_config_files = split(" ", data.external.team_files.result["key"])
}

data "local_file" "team_configs" {
  count    = length(local.team_config_files)
  filename = local.team_config_files[count.index]
}

locals {
  teams_config = { for k, f in data.local_file.team_configs :
    k => yamldecode(f.content)
  }

  team_defaults = {
    description = "No one cared enough to add a description to this team"
    privacy     = "closed"
    members     = {}
    parent      = ""
  }

  teams = { for k, t in local.teams_config :
    k => merge(local.team_defaults, t)
  }
}

resource "github_team" "parentless" {
  for_each = { for k, t in local.teams :
    k => t
    if lookup(t, "parent", "") == ""
  }

  name        = title(lower(each.value.name))
  description = each.value.description
  privacy     = each.value.privacy
}

data "local_file" "state" {
  filename   = "${path.module}/terraform.tfstate"
  depends_on = [github_team.parentless]
}

locals {

  github_team_name_ids_from_state = { for t in flatten([for github_team in jsondecode(data.local_file.state.content)["resources"] :
    github_team.instances
    if github_team.type == "github_team" && github_team.name == "parentless"
    ]) :
    t.attributes.name => t.attributes.id
  }
}


resource "github_team" "children" {
  for_each = { for k, t in local.teams :
    k => t
    if lookup(t, "parent", "") != ""
  }
  name           = each.value.name
  description    = each.value.description
  privacy        = each.value.privacy
  parent_team_id = local.github_team_name_ids_from_state["${each.value.parent}"]
}

