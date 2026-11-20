// Infrastructure for https://elrod.id
//
// Scope: resource group `elrod-id_group` (westus2).
// Contents:
//   - Azure Static Web Apps (Free) `elrod-id-website` in East US 2. The app
//     already exists (created in the portal), so this template ADOPTS it and
//     restates its current settings exactly. See docs/infrastructure.md.
//   - Azure DNS public zone `elrod.id`, with the records the site and the
//     domain's mail need (apex alias, www CNAME, Google Workspace MX, SPF).
//   - Custom domains `elrod.id` and `www.elrod.id` on the static web app.
//     Static Web Apps issues and renews the TLS certificates for them.
//
// Not in this template (documented one-time manual steps in
// docs/infrastructure.md): the GoDaddy nameserver change, and setting
// `elrod.id` as the static web app's default domain, which is what makes
// `www` redirect to the bare domain.

targetScope = 'resourceGroup'

@description('Name of the existing static web app.')
param staticWebAppName string = 'elrod-id-website'

@description('Region of the static web app. Must stay eastus2: a different value would try to move the app.')
param staticWebAppLocation string = 'eastus2'

@description('The apex domain. Also the name of the Azure DNS zone.')
param domainName string = 'elrod.id'

@description('GitHub repository linked to the static web app.')
param repositoryUrl string = 'https://github.com/john-elrod/elrod.id'

@description('Branch linked to the static web app.')
param branch string = 'main'

@description('''
Bind elrod.id and www.elrod.id to the static web app. Static Web Apps
validates the domains over public DNS, so on a rebuild from nothing set this
to false until public DNS holds the validation records, then true.
''')
param bindCustomDomains bool = false

@description('Default TTL, in seconds, for the DNS records.')
param ttl int = 3600

var wwwHost = 'www.${domainName}'

// ---------------------------------------------------------------------------
// Static Web App (adopted). Values mirror `az staticwebapp show` taken on
// 2026-11-20. repositoryToken is deliberately absent: it is a secret, and the
// existing GitHub link and deployment token are already in place. Read-only
// and undocumented fields (stableInboundIP, trafficSplitting,
// deploymentAuthPolicy) are not set; what-if lists them as removals, which is
// noise. Check them with the before/after snapshot in docs/infrastructure.md.
// ---------------------------------------------------------------------------
resource staticWebApp 'Microsoft.Web/staticSites@2024-11-01' = {
  name: staticWebAppName
  location: staticWebAppLocation
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  tags: {}
  properties: {
    repositoryUrl: repositoryUrl
    branch: branch
    provider: 'GitHub'
    allowConfigFileUpdates: true
    stagingEnvironmentPolicy: 'Enabled'
    enterpriseGradeCdnStatus: 'Disabled'
  }
}

// ---------------------------------------------------------------------------
// Azure DNS zone and records
// ---------------------------------------------------------------------------
resource zone 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: domainName
  location: 'global'
}

// Apex: alias record to the static web app, so no IP address is hard-coded.
resource apexAlias 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: zone
  name: '@'
  properties: {
    TTL: ttl
    targetResource: {
      id: staticWebApp.id
    }
  }
}

// www: CNAME to the static web app's default hostname.
resource wwwCname 'Microsoft.Network/dnsZones/CNAME@2018-05-01' = {
  parent: zone
  name: 'www'
  properties: {
    TTL: ttl
    CNAMERecord: {
      cname: staticWebApp.properties.defaultHostname
    }
  }
}

// Mail: Google Workspace MX records, carried over unchanged from GoDaddy.
resource mx 'Microsoft.Network/dnsZones/MX@2018-05-01' = {
  parent: zone
  name: '@'
  properties: {
    TTL: ttl
    MXRecords: [
      { preference: 1, exchange: 'aspmx.l.google.com' }
      { preference: 5, exchange: 'alt1.aspmx.l.google.com' }
      { preference: 5, exchange: 'alt2.aspmx.l.google.com' }
      { preference: 10, exchange: 'alt3.aspmx.l.google.com' }
      { preference: 10, exchange: 'alt4.aspmx.l.google.com' }
    ]
  }
}

// Apex TXT records, carried over unchanged from GoDaddy:
//   - the SPF policy (it includes the GoDaddy-hosted SPF record below)
//   - the ownership token Static Web Apps checked when the apex was bound
resource apexTxt 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  parent: zone
  name: '@'
  properties: {
    TTL: ttl
    TXTRecords: [
      { value: ['v=spf1 include:dc-aa8e722993._spfm.${domainName} ~all'] }
      { value: ['_yg07rdq8n1fo0jxxrxho2qxvistv35p'] }
    ]
  }
}

// SPF include target that the apex SPF record refers to (Google's SPF).
resource spfInclude 'Microsoft.Network/dnsZones/TXT@2018-05-01' = {
  parent: zone
  name: 'dc-aa8e722993._spfm'
  properties: {
    TTL: ttl
    TXTRecords: [
      { value: ['v=spf1 include:_spf.google.com ~all'] }
    ]
  }
}

// ---------------------------------------------------------------------------
// Custom domains. Free managed TLS certificates are issued and renewed by
// Static Web Apps once a domain is bound; there is no certificate resource.
// ---------------------------------------------------------------------------
resource apexDomain 'Microsoft.Web/staticSites/customDomains@2024-11-01' = if (bindCustomDomains) {
  parent: staticWebApp
  name: domainName
  properties: {
    validationMethod: 'dns-txt-token'
  }
  dependsOn: [
    apexAlias
    apexTxt
  ]
}

resource wwwDomain 'Microsoft.Web/staticSites/customDomains@2024-11-01' = if (bindCustomDomains) {
  parent: staticWebApp
  name: wwwHost
  properties: {
    validationMethod: 'cname-delegation'
  }
  dependsOn: [
    wwwCname
  ]
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('Set these four nameservers at GoDaddy (bootstrap step).')
output nameServers array = zone.properties.nameServers

@description('Default hostname of the static web app.')
output staticWebAppHostname string = staticWebApp.properties.defaultHostname
