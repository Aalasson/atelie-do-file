$ErrorActionPreference = 'Stop'
# Recuperação opcional do recurso. O jogo utiliza a cópia local e funciona offline.
$projectRoot = Split-Path -Parent $PSScriptRoot
$musicRoot = Join-Path $projectRoot 'audio/music'
$pageUrl = 'https://opengameart.org/content/etirwer'
$page = Invoke-WebRequest -Uri $pageUrl
$source = $page.Links | Where-Object { $_.href -match 'Etirwer.*\.ogg$' } | Select-Object -First 1 -ExpandProperty href
if (!$source) { throw 'Arquivo Etirwer não encontrado na página do autor.' }
$sourceUri = [Uri]::new([Uri]$pageUrl, $source)
if ($sourceUri.Scheme -ne 'https' -or $sourceUri.Host -ne 'opengameart.org') { throw 'Origem inesperada para a música.' }
New-Item -ItemType Directory -Path $musicRoot -Force | Out-Null
$destination = Join-Path $musicRoot 'etirwer-loop.ogg'
if (!(Test-Path -LiteralPath $destination)) {
    Invoke-WebRequest -Uri $sourceUri.AbsoluteUri -OutFile $destination
}
$sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
if ($sha256 -ne '382c02bfb3d9abe1c9f432606dd95f27bcef28ac22097ccdcef12a8c608b421b') {
    throw 'O arquivo difere da versão da música verificada para o projeto.'
}
$manifest = [ordered]@{
    title = 'Etirwer'; author = 'Kistol'; page = $pageUrl
    download_url = $sourceUri.AbsoluteUri; file = 'etirwer-loop.ogg'
    license = 'CC0-1.0'; license_url = 'https://creativecommons.org/publicdomain/zero/1.0/'
    sha256 = $sha256
    bytes = (Get-Item -LiteralPath $destination).Length
    modifications = 'Arquivo original preservado. Repetição e volume controlados pela Godot.'
    cultural_context = 'Trilha instrumental de apoio. Não é apresentada como música tradicional de Alagoas.'
}
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $musicRoot 'sources.json') -Encoding utf8
Write-Output ($manifest | ConvertTo-Json -Compress)
