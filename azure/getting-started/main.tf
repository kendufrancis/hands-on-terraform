resource "azurerm_resource_group" "terra_ref_rg" {
  name     = "${var.res_grp_name}-tf-res-grp"
  location = var.res_grp_locale
  tags = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name = "${var.prefix}-vnet"
  address_space = ["10.0.0.0/16"]
  location = var.res_grp_locale
  resource_group_name = azurerm_resource_group.terra_ref_rg.name
  tags = var.tags
}
resource "azurerm_subnet" "subnet" {
  name = "${var.prefix}-tf-subnet"
  address_prefixes = [ "10.0.1.0/24" ]
  resource_group_name = azurerm_resource_group.terra_ref_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "publicip" {
  name = "${var.prefix}-tf-pub-ip"
  location = var.res_grp_locale
  resource_group_name = azurerm_resource_group.terra_ref_rg.name
  allocation_method = "Dynamic"
  tags = var.tags
}

resource "azurerm_network_security_group" "nsg" {
  name = "${var.prefix}-tf-vm-nsg"
  location = var.res_grp_locale
  resource_group_name = azurerm_resource_group.terra_ref_rg.name
  tags = var.tags

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic" {
  name = "${var.prefix}-vm-nic"
  location = var.res_grp_locale
  resource_group_name = azurerm_resource_group.terra_ref_rg.name
  tags = var.tags

  ip_configuration {
    name = "${var.prefix}-vm-nic-cfg"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = azurerm_public_ip.publicip.id
  }
}

resource "azurerm_virtual_machine" "vm" {
  name = "${var.prefix}-az-tf-vm"
  location = var.res_grp_locale
  resource_group_name = azurerm_resource_group.terra_ref_rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size = var.az_vm_size
  tags = var.tags

  storage_os_disk {
    name = "${var.prefix}-tf-os-disk"
    caching = "ReadWrite"
    create_option = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "18.04-LTS"
    version = "latest"
  }

  os_profile {
    computer_name = "${var.prefix}-az-tf-vm"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}