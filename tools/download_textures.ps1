$ErrorActionPreference = 'Stop'
# Recursos CC0. A execução do jogo não depende da rede; os arquivos vão no ZIP.
$projectRoot = Split-Path -Parent $PSScriptRoot
$textureRoot = Join-Path $projectRoot 'textures/polyhaven'
New-Item -ItemType Directory -Path $textureRoot -Force | Out-Null
$assets = @(
    @{ Id = 'plywood'; ColorMap = 'Diffuse' },
    @{ Id = 'fabric_pattern_05'; ColorMap = 'col_01' },
    @{ Id = 'plastered_wall_02'; ColorMap = 'Diffuse' }
)
$manifest = @()
foreach ($asset in $assets) {
    $info = Invoke-RestMethod -Uri "https://api.polyhaven.com/info/$($asset.Id)"
    $catalog = Invoke-RestMethod -Uri "https://api.polyhaven.com/files/$($asset.Id)"
    $directory = Join-Path $textureRoot $asset.Id
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $maps = @(
        @{ Key = $asset.ColorMap; Format = 'jpg'; File = 'color.jpg' },
        @{ Key = 'nor_gl'; Format = 'png'; File = 'normal.png' },
        @{ Key = 'Rough'; Format = 'jpg'; File = 'roughness.jpg' }
    )
    $entries = @()
    foreach ($map in $maps) {
        $source = $catalog.($map.Key).'1k'.($map.Format)
        if (!$source.url.StartsWith('https://dl.polyhaven.org/')) { throw 'Fonte inesperada.' }
        $destination = Join-Path $directory $map.File
        if (!(Test-Path -LiteralPath $destination)) {
            Invoke-WebRequest -Uri $source.url -OutFile $destination
        }
        $md5 = (Get-FileHash -LiteralPath $destination -Algorithm MD5).Hash.ToLowerInvariant()
        if ($md5 -ne $source.md5) { throw "Checksum incorreto: $destination" }
        $entries += @{ file = $map.File; source_map = $map.Key; url = $source.url; md5 = $md5; sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant(); bytes = (Get-Item -LiteralPath $destination).Length }
    }
    $manifest += @{ id = $asset.Id; name = $info.name; authors = $info.authors; dimensions_mm = $info.dimensions; resolution = '1k'; page = "https://polyhaven.com/a/$($asset.Id)"; license = 'CC0-1.0'; license_url = 'https://polyhaven.com/license'; maps = $entries }
    Write-Output "Verificado: $($asset.Id) (3 mapas)"
}
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $textureRoot 'sources.json') -Encoding utf8
