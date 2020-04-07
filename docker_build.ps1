#!pwsh

Write-Output "--- DOCKER CONTAINER BUILD ---"

[xml]$cs_proj = Get-Content -Path ../../bitbucket/test-team-bibliotheken/Kundenprojekte/DEOS.BACnet.Gateway/bacnet_nf/bacnet_nf.csproj

$version = $cs_proj.Project.PropertyGroup.IntVersion

docker build -t nastymorbol/fhem:latest-alpine -t nastymorbol/fhem:$version-alpine .

#docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t nastymorbol/fhem:latest-alpine -t nastymorbol/fhem:$version-alpine --push .

#docker buildx build --platform linux/arm/v7 -t nastymorbol/fhem:latest-alpine -t nastymorbol/fhem:$version-alpine .