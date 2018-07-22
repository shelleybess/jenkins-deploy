data "azurerm_resource_group" "foundations" {
  name = "${var.resource_group_name}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.network_name}"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.foundations.name}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  resource_group_name  = "${data.azurerm_resource_group.foundations.name}"
  address_prefix       = "10.0.0.0/24"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
}

resource "azurerm_public_ip" "jenkins_pip" {
  name                         = "Jenkins_Public_IP"
  location                     = "${var.location}"
  resource_group_name          = "${data.azurerm_resource_group.foundations.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "public_nic" {
  name                      = "Jenkins_Public_NIC"
  location                  = "${var.location}"
  resource_group_name       = "${data.azurerm_resource_group.foundations.name}"
  network_security_group_id = "${azurerm_network_security_group.jenkins_security.id}"

  ip_configuration {
    name                          = "jenkins-Private"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.jenkins_pip.id}"
  }
}

resource "azurerm_virtual_machine" "jenkins" {
  name                  = "${var.vm_name}"
  location              = "${var.location}"
  resource_group_name   = "${data.azurerm_resource_group.foundations.name}"
  network_interface_ids = ["${azurerm_network_interface.public_nic.id}"]
  vm_size               = "${var.vm_size}"

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "jenkins-pipeline"
    create_option     = "FromImage"
    managed_disk_type = "${var.virtual_machine_osdisk_type}"
  }

  os_profile {
    computer_name  = "${var.os_name}"
    admin_username = "${var.vm_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.vm_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_public_key_data}")}"
    }
  }

  connection {
    type        = "ssh"
    host        = "${azurerm_public_ip.jenkins_pip.ip_address}"
    user        = "${var.vm_username}"
    private_key = "${file("${var.ssh_private_key_data}")}"
  }

  provisioner "remote-exec" {
    inline = [
      # Build Essentials
      "sudo apt-get update",

      "sudo apt-get install build-essential -y",
      "sudo apt-get install unzip -y",
      "sudo apt-get install make -y",

      # Go (put in PATH) & Terraform (not put in PATH)
      "wget -q -O - https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz | sudo tar -C /usr/local -xz",

      "wget -q -O terraform_linux_amd64.zip https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip",
      "sudo unzip -d /usr/local/terraform terraform_linux_amd64.zip",
      "sudo sh -c 'echo \"PATH=\\$PATH:/usr/local/go/bin\" >> /etc/profile'",

      # Ruby & Bundler
      "sudo apt-add-repository -y ppa:brightbox/ruby-ng",

      "sudo apt-get update",
      "sudo apt-get install ruby2.4 ruby2.4-dev -y",
      "sudo gem install bundler",

      # Azure CLI
      "sudo sh -c 'echo \"deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main\" > /etc/apt/sources.list.d/azure-cli.list'",

      "sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893",
      "sudo apt-get install apt-transport-https",
      "sudo apt-get update && sudo apt-get install azure-cli -y",

      # Java
      "sudo apt-get install default-jre -y",

      # Jenkins
      "wget -q -O - https://pkg.jenkins.io/debian/jenkins-ci.org.key | sudo apt-key add -",

      "sudo sh -c 'echo \"deb http://pkg.jenkins.io/debian-stable binary/\" > /etc/apt/sources.list.d/jenkins.list'",
      "sudo apt-get update",
      "sudo apt-get install jenkins -y",
      "sudo sh -c 'echo \"jenkins ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'",
      "sudo reboot",
    ]
  }
}

resource "azurerm_network_security_group" "jenkins_security" {
  name                = "${var.security_group_name}"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.foundations.name}"

  security_rule {
    name                       = "AllowSshInBound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHttpsInBound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
