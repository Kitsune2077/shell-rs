# The portable package: a folder to unzip anywhere and carry along. Its
# data stays beside the program, in `data` (src/app/paths.rs finds it
# there), so the folder leaves nothing in %APPDATA% or the cache. The data
# folder carries a README so it survives zipping and says what it holds.
#
#   packaging/windows/portable.ps1 -Version 0.2.0
#     [-BuildDir <repo>\target\release] [-OutDir <repo>\dist]
#
# Build the `shellrs` and `shellrs-cli` binaries first. The zip holds one
# folder, ShellRS, so unzipping it cannot scatter files.
param(
    [Parameter(Mandatory = $true)] [string]$Version,
    [string]$BuildDir = "",
    [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"

$repo = Join-Path $PSScriptRoot "..\.."
if (-not $BuildDir) { $BuildDir = Join-Path $repo "target\release" }
if (-not $OutDir) { $OutDir = Join-Path $repo "dist" }

$app = "ShellRS"
$stage = Join-Path $repo "target\portable\$app"

if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Path (Join-Path $stage "data") -Force | Out-Null

foreach ($name in "shellrs.exe", "shellrs-cli.exe") {
    $from = Join-Path $BuildDir $name
    if (-not (Test-Path $from)) {
        Write-Error "Build first: $from is missing. This package needs both binaries."
    }
    Copy-Item $from $stage
}

# UTF-8, so both languages read right in Notepad and anywhere else.
$readme = @'
ShellRS 便携版 <version>
========================

解压到任意文件夹即可运行 shellrs.exe，无需安装。程序的全部数据都保存
在旁边的 data 文件夹里，整个文件夹可以随意移动或拷贝到 U 盘。

两点须知：
- 密码仍然保存在 Windows 的「凭据管理器」里，不随 data 文件夹移动；
  换一台电脑使用时需要重新输入。
- 便携版不会自动更新。想升级时，从官网下载新的压缩包解压，然后把
  data 文件夹整个拷到新的文件夹里即可。

想用命令行工具的话，把本文件夹加进 PATH，命令名叫 shellrs-cli（就
是旁边的 shellrs-cli.exe，它认得 data 文件夹）。设置 › 外部 CLI 的安
装按钮不适合便携版：装出去的副本会去找安装版。

ShellRS portable <version>
==========================

Unzip this folder anywhere and run shellrs.exe; nothing is installed.
Everything the program keeps between runs stays in the data folder beside
it, so the whole folder can be moved or carried on a USB stick.

Two things to know:
- Passwords stay in Windows' Credential Manager, which does not move with
  the data folder; on another computer they are asked for again.
- The portable edition does not update itself. To upgrade, download the
  new zip from the website, unzip it, and copy your data folder into it.

For the command line, put this folder on the PATH: the command is
`shellrs-cli` (the shellrs-cli.exe beside the app, which finds the data
folder). 设置 › 外部 CLI's install button does not suit a portable copy:
the copy it puts on the PATH looks for an installed ShellRS.
'@.Replace("<version>", $Version)
Set-Content -Path (Join-Path $stage "README.txt") -Value $readme -Encoding utf8

$dataNote = @'
此文件夹存放 ShellRS 的全部数据：主机、设置、私钥、known_hosts 等。
删除它，程序就回到全新状态。

This folder holds all of ShellRS's data: hosts, settings, private keys,
known_hosts and the rest. Delete it and the program starts fresh.

携带或备份这个文件夹时请注意：私钥和 known_hosts 是敏感数据。
When you carry or back this folder up, mind that the private keys and
known_hosts in it are sensitive data.
'@
Set-Content -Path (Join-Path $stage "data\README.txt") -Value $dataNote -Encoding utf8

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$zip = Join-Path $OutDir "ShellRS-$Version-windows-x86_64-portable.zip"
Compress-Archive -Path $stage -DestinationPath $zip -Force
Write-Host "$zip"
