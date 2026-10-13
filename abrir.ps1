param(
    [switch]$Editor,
    [string]$GodotPath
)
$ErrorActionPreference = 'Stop'

if ($GodotPath) {
    if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
        throw "Executável não encontrado: $GodotPath"
    }
    $godotExecutable = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $godotCommand = Get-Command godot4, godot -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($godotCommand) {
        $godotExecutable = $godotCommand.Source
    } else {
        $godotExecutable = Join-Path (Split-Path $PSScriptRoot -Parent) '.tools\godot-4.4.1\Godot_v4.4.1-stable_win64.exe'
        if (-not (Test-Path -LiteralPath $godotExecutable -PathType Leaf)) {
            throw 'Instale a Godot 4.4.1 e importe project.godot, ou use: .\abrir.ps1 -Editor -GodotPath "C:\caminho\Godot.exe"'
        }
    }
}
if ($Editor) { & $godotExecutable --editor --path $PSScriptRoot }
else { & $godotExecutable --path $PSScriptRoot }
