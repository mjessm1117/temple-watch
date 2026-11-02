# INSTALL ON WINDOWS — Temple Watch (Godot desktop build)

Written so a person or an AI assistant on the Windows laptop can follow it step by step.
Every link below always points at the **newest** build.

- Build in this zip: {{BUILD}}
- Release page (newest): https://github.com/mjessm1117/temple-watch/releases/latest
- Zip name: `TempleWatch-Windows.zip` (about 100 MB)
- Direct download (newest): https://github.com/mjessm1117/temple-watch/releases/latest/download/TempleWatch-Windows.zip
- Install folder: `%USERPROFILE%\Games\TempleWatch`
- Needs: Windows 10 or 11 (64-bit) and up-to-date graphics drivers. No admin rights.

## Option 1 — one PowerShell script (recommended; also updates an existing install)

1. Press Win+R, type `powershell`, press Enter.
2. Paste this whole block into the window and press Enter:

```powershell
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$url  = 'https://github.com/mjessm1117/temple-watch/releases/latest/download/TempleWatch-Windows.zip'
$dest = Join-Path $env:USERPROFILE 'Games\TempleWatch'
$zip  = Join-Path $env:TEMP 'TempleWatch-Windows.zip'
Get-Process TempleWatch -ErrorAction SilentlyContinue | Stop-Process -Force
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $dest -Force
Get-ChildItem -Path $dest -Recurse | Unblock-File
$exe = Join-Path $dest 'TempleWatch.exe'
$lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Temple Watch.lnk'
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = $exe; $s.WorkingDirectory = $dest; $s.IconLocation = "$exe,0"; $s.Save()
Remove-Item $zip -Force
Write-Host "Installed to $dest  |  Desktop shortcut: $lnk"
Start-Process $exe
```

3. The game opens. After that, double-click **Temple Watch** on the desktop. To update later, run the same block again. Your saves are kept.

## Option 2 — by hand

1. Open the release page above. Under **Assets**, click `TempleWatch-Windows.zip`.
2. In Downloads, right-click the zip → **Extract All…** → choose `C:\Users\<you>\Games\TempleWatch` → **Extract**.
3. Double-click `TempleWatch.exe`. For a shortcut, right-click it → **Send to → Desktop (create shortcut)**.

## If Windows SmartScreen appears ("Windows protected your PC")

This is expected, because the game is not code-signed.

1. Click **More info**.
2. Click **Run anyway**.

If antivirus quarantines the exe, restore or allow it, then run it again.

## Troubleshooting

- **Black screen, or the window closes right away:** update your graphics driver. Or try compatibility mode:
  `& "$env:USERPROFILE\Games\TempleWatch\TempleWatch.exe" --rendering-driver opengl3`
- **Game is slow:** on the title screen, set **GRAPHICS** to **Low**, then restart the game.
- **Where saves live:** `%APPDATA%\Godot\app_userdata\` (the Temple Watch folder).
- **Uninstall:** delete `%USERPROFILE%\Games\TempleWatch` and the desktop shortcut.

This is a preview of the Godot rebuild. The website temple-watch.mjessm1117.workers.dev still runs the older HTML version.
