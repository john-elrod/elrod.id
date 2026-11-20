using 'main.bicep'

// Production values. Nothing secret lives here.
param staticWebAppName = 'elrod-id-website'
param staticWebAppLocation = 'eastus2'
param domainName = 'elrod.id'
param repositoryUrl = 'https://github.com/john-elrod/elrod.id'
param branch = 'main'

// Steady state: true. Set to false only when rebuilding from nothing, before
// the domain is reachable over public DNS. See docs/infrastructure.md.
param bindCustomDomains = true
