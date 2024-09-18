param serverName string
param location string = resourceGroup().location
param tags object = {}

param keyVaultName string

param databaseUser string = 'mysqladmin'
param databaseName string = 'rujchemsql'
@secure()
param databasePassword string

param allowAllIPsFirewall bool = false

resource mysqlServer'Microsoft.DBforMySQL/flexibleServers@2023-06-30' = {
  location: location
  tags: tags
  name: serverName
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '8.0.21'
    administratorLogin: databaseUser
    administratorLoginPassword: databasePassword
    storage: {
      storageSizeGB: 128
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }

  resource firewall_all 'firewallRules' = if (allowAllIPsFirewall) {
    name: 'allow-all-IPs'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }
}

resource database 'Microsoft.DBforMySQL/flexibleServers/databases@2023-06-30' = {
  parent: mysqlServer
  name: databaseName
  properties: {
    // Azure defaults to UTF-8 encoding, override if required.
    // charset: 'string' 
    // collation: 'string'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource dbPasswordKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'databasePassword'
  properties: {
    value: databasePassword
  }
}

output databaseHost string = mysqlServer.properties.fullyQualifiedDomainName
output databaseName string = databaseName
output databaseUser string = databaseUser
output databaseConnectionKey string = 'databasePassword'
output mysqlServerId string = mysqlServer.id
