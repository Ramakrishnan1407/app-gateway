resource "azurerm_resource_group" "default" {
  name     = "myaksclusternew"
  location = "westeurope"

  tags = {
    environment = "Test"
  }
}

resource "random_pet" "azurerm_kubernetes_cluster_dns_prefix" {
  prefix = "dns"
}

/*
resource "azurerm_kubernetes_cluster" "aks" {
  location                  = "westeurope"
  name                      = "myaksclusternew"
  resource_group_name       = azurerm_resource_group.default.name
  dns_prefix                = random_pet.azurerm_kubernetes_cluster_dns_prefix.id
  automatic_channel_upgrade = "rapid"
 #private_cluster_enabled   = true 
  

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    temporary_name_for_rotation = "temp"
    vm_size    = "standard_a2m_v2"
    node_count = 1
    enable_auto_scaling = false
  }

  storage_profile {
    blob_driver_enabled = true
  }

  network_profile {
    network_plugin    = "kubenet"
    network_policy    = "calico"
    load_balancer_sku = "standard"
  }

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Wednesday"
    start_time  = "22:10"
    utc_offset  = "+01:00"
  }
}

resource "azurerm_container_registry" "acr_platform_shared" {
  name                = "acrtest1407"
  resource_group_name = azurerm_resource_group.default.name
  location            = "westeurope"
  sku                 = "Standard"
  admin_enabled       = true
}

/*
resource "helm_release" "hello-world" {
name = "hello-world"
chart = "hello-world"
namespace = "hello-world"
create_namespace = "true"
repository = "oci://acrtest1407.azurecr.io/helm/hello-world"
version = "0.1.0"
wait = "true"
force_update = "true"
}*/

/*
resource "null_resource" "aks_upgrade" {
  
  provisioner "local-exec" {
    command = "az aks maintenanceconfiguration add -g ${azurerm_resource_group.default.name} --cluster-name ${azurerm_kubernetes_cluster.aks.name} --name aksManagedAutoUpgradeSchedule --day-of-week Tuesday --interval-weeks 1 --duration 4 --utc-offset +01:00 --start-time 14:30"
  }

  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}*/

resource "azurerm_resource_group" "example" {
  name     = "appgateway"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "example" {
  name                 = "example2"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.254.0.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example-pip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.example.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.example.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.example.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.example.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.example.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.example.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.example.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "example-appgateway2"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  
  firewall_policy_id   = azurerm_web_application_firewall_policy.example.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.example.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }
  
  /*
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }*/

  frontend_ip_configuration {
    name                          = "fip-private"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.254.0.11"
    subnet_id                     = azurerm_subnet.example.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = "fip-private"
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}  


resource "azurerm_application_gateway" "network2" {
  name                = "example-appgateway3"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  firewall_policy_id   = azurerm_web_application_firewall_policy.example.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.example.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.example.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}  


resource "azurerm_web_application_firewall_policy" "example" {
  name                = "example-wafpolicy"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  custom_rules {
    name      = "Rule1"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24", "10.0.0.0/24"]
    }

    action = "Block"
  }

  custom_rules {
    name      = "Rule2"
    priority  = 2
    rule_type = "MatchRule"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }

      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.0/24"]
    }

    match_conditions {
      match_variables {
        variable_name = "RequestHeaders"
        selector      = "UserAgent"
      }

      operator           = "Contains"
      negation_condition = false
      match_values       = ["Windows"]
    }

    action = "Block"
  }

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }
    exclusion {
      match_variable          = "RequestCookieNames"
      selector                = "too-tasty"
      selector_match_operator = "EndsWith"
    }

    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rule {
          id      = "920300"
          enabled = true
          action  = "Log"
        }

        rule {
          id      = "920440"
          enabled = true
          action  = "Block"
        }
      }
    }
  }
}
