terraform {
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "~> 1.0.0"
    }
    sakuracloud = {
      source  = "sacloud/sakuracloud"
      version = "2.17.0"
    }
  }
}

provider "sakuracloud" {
  token  = "YOUR_TOKEN"
  secret = "YOUR_TOKEN_SECRET"
  zone   = "tk1a"
}

variable "password" {
  default = "P@ssw0rd"
}

data "sakuracloud_archive" "ubuntu" {
  os_type = "ubuntu2004"
}

resource "sakuracloud_disk" "web_server" {
  name              = "Web Server"
  source_archive_id = data.sakuracloud_archive.ubuntu.id
}

resource "sakuracloud_server" "web_server" {
  name        = "Web Server"
  disks       = [sakuracloud_disk.web_server.id]
  core        = 1
  memory      = 2
  description = "nginx"

  network_interface {
    upstream = "shared"
  }

  disk_edit_parameter {
    hostname        = "web-server"
    password        = var.password
    ssh_key_ids     = [sakuracloud_ssh_key.key.id]
    disable_pw_auth = true
  }
}

resource "sakuracloud_ssh_key" "key" {
  name       = "key"
  public_key = file("./id_rsa.pub")
}

resource "ansible_host" "web_server" {
  name   = sakuracloud_server.web_server.ip_address
  groups = ["web"]
  variables = {
    ansible_user                 = "ubuntu",
    ansible_ssh_private_key_file = "./id_rsa",
    ansible_python_interpreter   = "/usr/bin/python3"
    ansible_become               = "yes"
    ansible_become_method        = "sudo"
    ansible_become_pass          = var.password
  }
}
