@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

set "HINT_SHOWN=0"
set "YTDLP_CHECK_UPDATES=1"
set "LINKS_FILE=%USERPROFILE%\Downloads\links.txt"

:: ===== EXTRACT EMBEDDED POWERSHELL SCRIPT TO TEMP =====
set "PSFILE=%TEMP%\Get-WebMedia.ps1"

echo Extracting Get-WebMedia.ps1...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$lines = Get-Content '%~f0'; $start = 0; for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -eq '###EMBEDDED_PS1_START###') { $start = $i + 1; break } }; $lines[$start..($lines.Count - 1)] | Out-File -FilePath '%PSFILE%' -Encoding UTF8 -Force"

:: Detect language
set "LANG=EN"
reg query "HKCU\Control Panel\International" /v LocaleName 2>nul | findstr /i "ru" >nul
if !errorlevel! equ 0 set "LANG=RU"

:: UNBLOCK script files - both the batch file itself and the PowerShell script
powershell.exe -Command "Unblock-File -Path '%~f0'" 2>nul
powershell.exe -Command "Unblock-File -Path '%PSFILE%'" 2>nul

:: Text messages
if "!LANG!"=="RU" (
    set "MSG_ENTER_URL=Вставьте ссылку на видео или аудио: "
    set "MSG_LINKS_HINT=ПОДСКАЗКА: Хотите скачать сразу несколько видео или аудио файлов? Создайте файл links.txt в папке Загрузки, вставьте в него ссылки и снова запустите скрипт."
    set "MSG_SELECT_MODE=ВЫБЕРИТЕ РЕЖИМ СКАЧИВАНИЯ"
    set "MSG_MODE_VIDEO=[1] Видео (MP4/MKV, макс. 1080p) - по умолчанию"
    set "MSG_MODE_AUDIO=[2] Аудио (MP3)"
    set "MSG_SELECT_MODE_PROMPT=Выберите режим (1 или 2, Enter = 1): "
    set "MSG_SELECT_BROWSER=ВЫБЕРИТЕ БРАУЗЕР ДЛЯ КУКИ"
    set "MSG_COOKIE_INFO=Куки могут потребоваться для обхода защиты от ботов или доступа к контенту с возрастными ограничениями"
    set "MSG_BROWSER_WARNING=ВНИМАНИЕ: Браузер должен быть ПОЛНОСТЬЮ ЗАКРЫТ чтобы извлечение куки сработало корректно!"
    set "MSG_FIREFOX=[1] Firefox"
    set "MSG_OPERA=[2] Opera"
    set "MSG_BRAVE=[3] Brave"
    set "MSG_VIVALDI=[4] Vivaldi"
    set "MSG_YANDEX=[5] Яндекс"
    set "MSG_NOCOOKIES=Нажмите Enter чтобы пропустить"
    set "MSG_SELECT=Выберите браузер (1-5) или Enter для пропуска: "
    set "MSG_INVALID_MODE=Неверный выбор. Используйте 1 или 2."
    set "MSG_INVALID=Неверный выбор. Используйте 1-5 или Enter."
    set "MSG_DOWNLOADING_AUDIO=Загрузка аудио (MP3)..."
    set "MSG_DOWNLOADING_VIDEO=Загрузка видео (MP4, 1080p)..."
    set "MSG_NO_URL=Ссылка не введена. Попробуйте снова."
    set "MSG_FOUND_LINKS=Найден файл links.txt в папке Загрузки. Использовать его? [Y/N]: "
) else (
    set "MSG_ENTER_URL=Paste video or audio URL: "
    set "MSG_LINKS_HINT=HINT: To download multiple files at once, save all the links in a file called links.txt in your Downloads folder, then run the script again."
    set "MSG_SELECT_MODE=SELECT DOWNLOAD MODE"
    set "MSG_MODE_VIDEO=[1] Video (MP4/MKV, max 1080p) - default"
    set "MSG_MODE_AUDIO=[2] Audio (MP3)"
    set "MSG_SELECT_MODE_PROMPT=Select mode (1 or 2, Enter = 1): "
    set "MSG_SELECT_BROWSER=SELECT BROWSER FOR COOKIES"
    set "MSG_COOKIE_INFO=Cookies may be required to bypass bot protection or access age-restricted content"
    set "MSG_BROWSER_WARNING=WARNING: The browser MUST be COMPLETELY CLOSED before continuing!"
    set "MSG_FIREFOX=[1] Firefox"
    set "MSG_OPERA=[2] Opera"
    set "MSG_BRAVE=[3] Brave"
    set "MSG_VIVALDI=[4] Vivaldi"
    set "MSG_YANDEX=[5] Yandex"
    set "MSG_NOCOOKIES=Press Enter to skip"
    set "MSG_SELECT=Select browser (1-5) or Enter to skip: "
    set "MSG_INVALID_MODE=Invalid choice. Please use 1 or 2."
    set "MSG_INVALID=Invalid choice. Please use 1-5 or Enter."
    set "MSG_DOWNLOADING_AUDIO=Downloading audio (MP3)..."
    set "MSG_DOWNLOADING_VIDEO=Downloading video (MP4, 1080p)..."
    set "MSG_NO_URL=No URL entered. Please try again."
    set "MSG_FOUND_LINKS=Found links.txt in Downloads. Use it? [Y/N]: "
)

:: ===== CHECK FOR links.txt IN DOWNLOADS =====
if exist "%LINKS_FILE%" (
    set "FOUND_LINKS=%LINKS_FILE%"
) else if exist "%LINKS_FILE%.txt" (
    set "FOUND_LINKS=%LINKS_FILE%.txt"
)

if defined FOUND_LINKS (
    echo.
    set "HINT_SHOWN=1"
    set "USE_LINKS="
    set /p "USE_LINKS=!MSG_FOUND_LINKS!"
    if /i "!USE_LINKS!"=="Y" goto MODE_MENU
)

goto URL_INPUT

:URL_INPUT
cls
if "!HINT_SHOWN!"=="0" (
    echo !MSG_LINKS_HINT!
    echo.
    set "HINT_SHOWN=1"
)
set "URL="
set /p "URL=!MSG_ENTER_URL!"

if "!URL!"=="" (
    echo.
    echo !MSG_NO_URL!
    echo.
    pause
    goto URL_INPUT
)

set "USE_LINKS="
goto MODE_MENU

:MODE_MENU
cls
echo ================================
echo    !MSG_SELECT_MODE!
echo ================================
echo.
echo !MSG_MODE_VIDEO!
echo !MSG_MODE_AUDIO!
echo.

set "MODE="
set /p "MODE=!MSG_SELECT_MODE_PROMPT!"

if "!MODE!"=="" set "MODE=1"
if "!MODE!"=="1" goto MODE_SELECTED
if "!MODE!"=="2" goto MODE_SELECTED

echo.
echo !MSG_INVALID_MODE!
echo.
pause
goto MODE_MENU

:MODE_SELECTED
if "!MODE!"=="1" set "DOWNLOAD_MODE=Video"
if "!MODE!"=="2" set "DOWNLOAD_MODE=Audio"

:BROWSER_MENU
cls
echo ================================
echo    !MSG_SELECT_BROWSER!
echo ================================
echo.
echo !MSG_COOKIE_INFO!
echo.
echo !MSG_BROWSER_WARNING!
echo.
echo !MSG_FIREFOX!
echo !MSG_OPERA!
echo !MSG_BRAVE!
echo !MSG_VIVALDI!
echo !MSG_YANDEX!
echo.
echo !MSG_NOCOOKIES!
echo.

set "INPUT="
set /p "INPUT=!MSG_SELECT!"

if not defined INPUT goto NOCOOKIES
if "!INPUT!"=="" goto NOCOOKIES

if "!INPUT!"=="1" set "BROWSER=firefox" & goto RUN
if "!INPUT!"=="2" set "BROWSER=opera" & goto RUN
if "!INPUT!"=="3" set "BROWSER=brave" & goto RUN
if "!INPUT!"=="4" set "BROWSER=vivaldi" & goto RUN
if "!INPUT!"=="5" set "BROWSER=yandex" & goto RUN

echo.
echo !MSG_INVALID!
echo.
pause
goto BROWSER_MENU

:RUN
echo.

:: Build source argument
if defined USE_LINKS (
    set "SOURCE_ARG=-File "!FOUND_LINKS!""
) else (
    set "SOURCE_ARG=-Url "!URL!""
)

if "!DOWNLOAD_MODE!"=="Video" (
    echo !MSG_DOWNLOADING_VIDEO!
    powershell.exe -ExecutionPolicy Bypass -File "%PSFILE%" !SOURCE_ARG! -MaxResolution 1080 -MP4Output -CookiesFrom "!BROWSER!" -SkipBrowserPrompt
) else (
    echo !MSG_DOWNLOADING_AUDIO!
    powershell.exe -ExecutionPolicy Bypass -File "%PSFILE%" !SOURCE_ARG! -AudioOnly -AudioFormat mp3 -CookiesFrom "!BROWSER!" -SkipBrowserPrompt
)
goto END

:NOCOOKIES
echo.

:: Build source argument
if defined USE_LINKS (
    set "SOURCE_ARG=-File "!FOUND_LINKS!""
) else (
    set "SOURCE_ARG=-Url "!URL!""
)

if "!DOWNLOAD_MODE!"=="Video" (
    echo !MSG_DOWNLOADING_VIDEO!
    powershell.exe -ExecutionPolicy Bypass -File "%PSFILE%" !SOURCE_ARG! -MaxResolution 1080 -MP4Output
) else (
    echo !MSG_DOWNLOADING_AUDIO!
    powershell.exe -ExecutionPolicy Bypass -File "%PSFILE%" !SOURCE_ARG! -AudioOnly -AudioFormat mp3
)
goto END

:END
echo.
set "USE_LINKS="
set "FOUND_LINKS="
pause
goto URL_INPUT

###EMBEDDED_PS1_START###
<#
.SYNOPSIS
    Download videos and audio from YouTube and hundreds of other sites with yt-dlp.
.DESCRIPTION
    A PowerShell wrapper for yt-dlp that makes downloading media simple with smart defaults.
    
    What it does:
    • Grabs the best quality video up to your chosen resolution
    • Extracts audio in your preferred format (MP3, M4A, FLAC, etc.)
    • Outputs MP4/H.264/AAC for best compatibility (Default: original format)
    • Works through proxies and detects system proxy settings automatically
    • Pulls cookies from your browser for age-restricted or members-only content
    • Handles batch downloads from text files or multiple URLs
    • Installs and updates required tools via winget

    Tools it uses (installs automatically if missing):
    • yt-dlp - The download engine
    • ffmpeg - Media processing
    • deno - JavaScript runtime for site-specific extractors
.PARAMETER Url
    One or more video, playlist, or channel URLs to download.
    
    Examples:
    -Url "https://youtube.com/watch?v=..."
    -Url "url1", "url2", "url3"
.PARAMETER File
    Path to a text file with URLs listed one per line.
.PARAMETER OutputDir
    Where downloaded and temporary files go.
    Default: $env:USERPROFILE\Downloads\yt-dlp
.PARAMETER AudioOnly
    Download just the audio track (video gets tossed).
.PARAMETER AudioFormat
    Audio format when using -AudioOnly.
    Options: best, mp3, m4a, aac, opus, flac, wav, vorbis
    Default: best
.PARAMETER MaxResolution
    Maximum video height in pixels (144-4320).
    Common picks: 480, 720, 1080, 2160
    Default: 1080
.PARAMETER MinResolution
    Minimum video height in pixels (144-4320).
    Download will fail if the minimum isn't met.
    Default: 0 (no minimum)
.PARAMETER MP4Output
    Prefer MP4 container with H.264 video and AAC audio for wide compatibility.
    If AAC audio isn't available, the best audio track will be downloaded and re-encoded.
    Falls back to MKV with best available audio and video if H.264 video isn't available.
.PARAMETER NoProxy
    Bypass all proxies completely and force direct connection.
    Both the YTDLP_PROXY environment variable and system proxy settings will be ignored
.PARAMETER ProxyAddress
    Specific proxy server to route through.
    Examples: http://proxy:8080, socks5://127.0.0.1:1080
.PARAMETER CookiesFrom
    Browser name to extract cookies from for authentication.
    
    Browsers you can pull from: brave, chrome, chromium, edge, firefox, opera, vivaldi, whale, yandex
    Heads up: Chrome/Chromium cookie extraction is currently broken (see GitHub issue #10927)
    
    The browser needs to be closed when you use this option.
.PARAMETER SkipBrowserPrompt
    Skip the "close browser" prompt when using -CookiesFrom.
    Useful for scripting and automation.
.PARAMETER UpdateTools
    Force update checks for yt-dlp, ffmpeg and deno before download.
    Can be used with or without -Url argument. Useful for automation.
.PARAMETER FullPlaylist
    Download the whole playlist when a link to a video in the playlist is passed.
    Default: off
.PARAMETER Overwrite
    Replace existing files rather than skipping them.
.PARAMETER ExtraArgs
    Additional yt-dlp arguments passed straight through to the tool.
    May produce misleading output or unexpected errors. Use carefully.
    Example: "--write-subs --embed-thumbnail"
.EXAMPLE
    # Download a single video
    .\Get-WebMedia.ps1 "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
.EXAMPLE
    # Grab several videos at once
    .\Get-WebMedia.ps1 -Url "https://youtu.be/abc123", "https://youtu.be/def456"
.EXAMPLE
    # Work through a list of URLs from a file
    .\Get-WebMedia.ps1 -File "links.txt"
.EXAMPLE
    # Audio only, converted to MP3
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -AudioOnly -AudioFormat mp3
.EXAMPLE
    # Audio only, best available quality (no conversion)
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -AudioOnly -AudioFormat best
.EXAMPLE
    # An entire playlist capped at 720p
    .\Get-WebMedia.ps1 "https://youtube.com/playlist?list=..." -MaxResolution 720
.EXAMPLE
    # 720 video saved as MP4 if possible
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -MaxResolution 720 -MP4Output
.EXAMPLE
    # Video at minimum 720p, maximum 1080p
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -MinResolution 720 -MaxResolution 1080
.EXAMPLE
    # Age-restricted content using Firefox cookies (skipping the prompt)
    .\Get-WebMedia.ps1 "https://youtu.be/restricted" -CookiesFrom firefox -SkipBrowserPrompt
.EXAMPLE
    # Route traffic through a SOCKS5 proxy
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -ProxyAddress "socks5://127.0.0.1:1080"
.EXAMPLE
    # Include subtitles and cover art
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -ExtraArgs "--write-subs --embed-thumbnail"
.EXAMPLE
    # Save to a custom directory
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -OutputDir "D:\Videos"
.EXAMPLE
    # Overwrite existing files instead of skipping
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -Overwrite
.EXAMPLE
    # Update tools and exit
    .\Get-WebMedia.ps1 -UpdateTools
.NOTES
    Filename: Get-WebMedia.ps1

    Requirements:
        - Windows 10 or higher
        - Windows PowerShell 5.1 (built into Windows) or cross-platform PowerShell
        - WinGet (built into Windows)

    Environment variables:
      YTDLP_CHECK_UPDATES - Set to 1 to enable automatic update checks (at every script launch, but no more often than 1 day)
      YTDLP_PROXY - Proxy address (overrides system proxy, superseded by -ProxyAddress)

.LINK
    https://github.com/yt-dlp/yt-dlp
#>

param(
    [Parameter(Mandatory=$false, Position=0, HelpMessage="URL of the video, playlist, or channel to download")]
    [string[]]$Url,
    
    [Parameter(HelpMessage="File containing URLs to download (one per line)")]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$File,

    [Parameter(HelpMessage="Custom output directory. Default: `$env:USERPROFILE\Downloads\yt-dlp")]
    [string]$OutputDir = "$env:USERPROFILE\Downloads\yt-dlp",
    
    [Parameter(HelpMessage="Download audio only, discarding video")]
    [switch]$AudioOnly,
    
    [Parameter(HelpMessage="Target audio format when using -AudioOnly")]
    [ValidateSet("best", "mp3", "m4a", "aac", "opus", "flac", "wav", "vorbis")]
    [string]$AudioFormat = "best",
    
    [Parameter(HelpMessage="Maximum video resolution in pixels (144-4320)")]
    [ValidateRange(144, 4320)]
    [int]$MaxResolution = 1080,

    [Parameter(HelpMessage="Minimum required video resolution in pixels.")]
    [ValidateRange(144, 4320)]
    [int]$MinResolution = 0,

    [Parameter(HelpMessage="Produce MP4 output with H.264 video and AAC audio if possible")]
    [switch]$MP4Output,
    
    [Parameter(HelpMessage="Disable proxy usage entirely")]
    [switch]$NoProxy,
    
    [Parameter(HelpMessage="Custom proxy address (HTTP, HTTPS, SOCKS4, SOCKS5)")]
    [string]$ProxyAddress,

    [Parameter(HelpMessage = "Import cookies from specified browser")]
    [ValidateSet("brave", "chrome", "chromium", "edge", "firefox", "opera", "vivaldi", "whale", "yandex", IgnoreCase = $true)]
    [string]$CookiesFrom,

    [Parameter(HelpMessage = "Skip the 'close browser' prompt when using -CookiesFrom")]
    [switch]$SkipBrowserPrompt,

    [Parameter(HelpMessage="Update yt-dlp, ffmpeg, and deno to latest versions")]
    [switch]$UpdateTools,

    [Parameter(HelpMessage="Download entire playlist.")]
    [switch]$FullPlaylist,

    [Parameter(HelpMessage="Force overwrite of existing files")]
    [switch]$Overwrite,

    [Parameter(HelpMessage="Additional yt-dlp arguments passed directly to the tool")]
    [string]$ExtraArgs
)

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 or higher is required."
    exit 1
}

$DebugMode = @('Inquire','Continue') -contains $DebugPreference

function Print-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Print-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Print-Diag {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Magenta
}

function Print-Error {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Print-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
    Write-Host ""
}

function Update-Path {
    $env:PATH = (@(
        [System.Environment]::GetEnvironmentVariable("Path", "Machine")
        [System.Environment]::GetEnvironmentVariable("Path", "User")
        $PSScriptRoot
    ) -join ';' -split ';' | Select-Object -Unique) -join ';'
}

function IsUpdTime {
    if ($env:YTDLP_CHECK_UPDATES -ne 1) { return $false }

    $updateCheckFile = Join-Path -Path $env:TEMP -ChildPath "gwm_upd_check"

    if (Test-Path $updateCheckFile) {
        try {
            $lastCheck = Get-Content $updateCheckFile -Raw
            $lastCheckDate = [DateTime]::ParseExact($lastCheck.Trim(), "yyyy-MM-dd", $null)
            $today = [DateTime]::Today
            
            if ($today -gt $lastCheckDate) {
                $today.ToString("yyyy-MM-dd") | Out-File -FilePath $updateCheckFile -Encoding UTF8 -Force
                return $true
            }

            return $false
        } catch {
            (Get-Date).ToString("yyyy-MM-dd") | Out-File -FilePath $updateCheckFile -Encoding UTF8 -Force
            return $true
        }
    } else {
        (Get-Date).ToString("yyyy-MM-dd") | Out-File -FilePath $updateCheckFile -Encoding UTF8 -Force
        return $true
    }
}

# Helper function to install/update via winget
function Install-WithWinget {
    param(
        [string]$ToolName, 
        [string]$PackageName
    ) 
       
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install $PackageName --accept-package-agreements --accept-source-agreements 2>&1 |
            Where-Object { $_.ToString().Trim() -ne '' -and $_ -notmatch '^\s*-+\s*$' } |
            Write-Debug
        $exitCode = $LASTEXITCODE

        Write-Debug "WinGet returned ${exitCode}"

        # Winget exit codes https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md
        $UPDATE_NOT_APPLICABLE = -1978335189
        $SUCCESS = 0
        Update-Path

        switch ($exitCode) {
            $SUCCESS {
                Print-Success "SUCCESS: ${ToolName} (Installed/updated successfully)"
                return $true
            }
            $UPDATE_NOT_APPLICABLE {
                Print-Success "SUCCESS: ${ToolName} (Already up-to-date)"
                return $true
            }
            default {
                Print-Error "ERROR: ${ToolName} failed to download/install (WinGet exit code: ${exitCode})"
                return $false
            }
        }
    } else {
        Print-Error "ERROR: ${ToolName} failed to download/install (WinGet is not available)"
        return $false
    }
}

function Install-Tools {
    param(
        [switch]$Update
    )

    Update-Path

    $Tools = @(
        @{
            Name = "yt-dlp"
            PkgName = "yt-dlp.yt-dlp"
            URL = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
            ExeNames = @("yt-dlp.exe")
        },
        @{
            Name = "deno"
            PkgName = "DenoLand.Deno"
            URL = "https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip"
            ExeNames = @("deno.exe")
        },
        @{
            Name = "ffmpeg"
            PkgName = "yt-dlp.FFmpeg"
            URL = "https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip"
            ExeNames = @("ffmpeg.exe", "ffprobe.exe")
        }
    ) | ForEach-Object {
        $available = $true
        $missingExes = @()
        foreach ($exe in $_.ExeNames) {
            if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
                $available = $false
                $missingExes += $exe
            }
        }
        
        [PSCustomObject]@{
            Name        = $_.Name
            PkgName     = $_.PkgName
            URL         = $_.URL
            ExeNames    = $_.ExeNames
            MissingExes = $missingExes
            Available   = $available
        }
    }

    if (-not $Update) {
        $Tools = $Tools | Where-Object { -not $_.Available }
    }

    if (@($Tools).Count -eq 0) {
        return $true
    }

    if ($Update) {
        Print-Header "Checking/updating tools"
    } else {
        $allMissingExes = $Tools | ForEach-Object { $_.MissingExes } | Where-Object { $_ }
        $exeList = ($allMissingExes | ForEach-Object { $_ }) -join ', '
        $exeCount = @($allMissingExes).Count
        $exeWord = if ($exeCount -eq 1) { "executable is" } else { "executables are" }
        Print-Diag "The following ${exeWord} not found in PATH: ${exeList}"
        Print-Header "Installing missing tools"
    }

    $allInstalled = $true

    foreach ($tool in $Tools) {
        if (-not (Install-WithWinget -ToolName $tool.Name -PackageName $tool.PkgName)) {
            $allInstalled = $false
        }
    }

    if ($allInstalled) {
        if ($Update) { 
            Print-Header "Install/update complete!"
        } else {
            Print-Header "Install complete!"
        }
    } else {
        Print-Error "Failed to install the required tools!"
        Print-Header "Please download the following tools manually"

        $missing = @()
        foreach ($tool in $Tools) {
            # Re-check which specific exes are still missing after winget attempt
            $stillMissing = @()
            foreach ($exe in $tool.ExeNames) {
                if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
                    $stillMissing += $exe
                }
            }
            if ($stillMissing.Count -gt 0) {
                Print-Info " $($tool.Name): $($tool.URL)"
                $missing += $stillMissing
            }
        }

        $exeList = $missing -join ', '
        $exeCount = @($missing).Count
        $isAre = if ($exeCount -eq 1) { "is" } else { "are" }

        Print-Header "Then ensure that ${exeList} ${isAre} in the script folder or added to PATH"
    }

    return $allInstalled
}

function Get-ProxyAddress {
    param([string]$TargetUrl)

    if ($ProxyAddress) {
        Print-Diag "Custom proxy address passed: ${ProxyAddress}"
        return $ProxyAddress
    }

    if ($env:YTDLP_PROXY -and $env:YTDLP_PROXY.Trim() -ne '') {
        Print-Diag "Proxy from environment variable: ${env:YTDLP_PROXY}"
        return $env:YTDLP_PROXY
    } else {
        try {
            $SystemProxy = [System.Net.WebRequest]::GetSystemWebProxy().GetProxy($TargetUrl).AbsoluteUri
            if ($SystemProxy -and ($SystemProxy -ne $TargetUrl)) {
                Print-Diag "System proxy detected: ${SystemProxy}"
                return $SystemProxy
            }
        } catch {
            Write-Warning "Failed to detect system proxy: $_"
            return $null
        }
    }

    Print-Diag "Not using proxy - none detected and none supplied"
    Print-Diag "See help for more info on how to supply the proxy address"
    return $null
}

# Parse URLs from file or single URL parameter
if ($File) {
    Print-Info "Reading URLs from: ${File}"
    $fileUrls = Get-Content $File | Where-Object { $_ -match '\S' } | ForEach-Object { $_.Trim() }
    Print-Info "Found URLs in file: $($fileUrls.Count)"

    if ($fileUrls.Count -eq 0) {
        Print-Error "No URLs found in file: ${File}"
    } else {
        $Url += $fileUrls
    }
}

$UpdateTools = ($UpdateTools -or (IsUpdTime))

Print-Info "Checking if required tools are present"
$ToolsAvailable = if ($UpdateTools) { Install-Tools -Update } else { Install-Tools }

if ($ToolsAvailable) {
    Print-Info "All tools are present!"
} else {
    Print-Error "Cannot proceed due to missing tools."
    Exit 1
}

# Check if URL is provided for download
if (-not $Url -or $Url.Count -eq 0) {
    if ($UpdateTools) { Exit 0 }
    Print-Error "URL is required for downloading!"
    Print-Info "Use -UpdateTools to update tools without downloading."
    Exit 1
}

$OutputDir = $OutputDir.Trim()

try {
    [System.IO.Directory]::SetCurrentDirectory($PWD.Path)

    $OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
    $OutputDir = $OutputDir.TrimEnd(' ', '.', '\')
    
    if (Test-Path -Path $OutputDir) {
        $resolved = Resolve-Path -Path $OutputDir
        $OutputDir = if ($resolved.ProviderPath) { 
            $resolved.ProviderPath 
        } else { 
            $resolved.Path 
        }
    }
} catch {
    Print-Error "Invalid path: ${OutputDir}"
    Print-Error "Error: $($_.Exception.Message)"
    exit 1
}

$TempPath = Join-Path -Path $OutputDir -ChildPath 'temp_files'

try {
    $created = New-Item -ItemType Directory -Path $TempPath -Force -ErrorAction Stop
    $TempPath = $created.FullName
    Print-Diag "Output: ${OutputDir}"
} catch {
    Print-Error "Failed to create directory: ${TempPath}"
    Print-Error "Error: $($_.Exception.Message)"
    exit 1
}

# Base arguments
$ytArgs = @(
    '--progress', '--verbose',
    '--encoding', 'UTF-8',
    "--paths", "temp:temp_files", 
    "--paths", "`"${OutputDir}`""
)

if (-not $DebugMode) {
    $ytArgs += @('--quiet')
}

if ($AudioOnly) {
    $ytArgs += @('--output', "`"%(title)s.%(ext)s`"")
} else {
    $ytArgs += @('--output', "`"%(title)s_%(resolution)s.%(ext)s`"")
}

if ($FullPlaylist) {
    Write-Host "The entire playlist will be downloaded"
    $ytArgs += @('--yes-playlist')
} else {
    $ytArgs += @('--no-playlist')
}

if ($Overwrite) {
    Write-Warning "Existing files will be overwritten!"
    $ytArgs += @('--force-overwrites')
}

if ($NoProxy) {
    $ytArgs += @("--proxy", '""')
} else {
    $Proxy = Get-ProxyAddress -TargetUrl $Url[0]
    Write-Debug "Proxy returned by Get-ProxyAddress: ${Proxy}"
    if ($Proxy) { $ytArgs += @("--proxy", "`"$Proxy`"") }
}

# Add cookies if browser is specified
if ($CookiesFrom) {
    Print-Diag "Using cookies from: ${CookiesFrom}"

    if ($CookiesFrom -ne "firefox") {
        Write-Warning "Cookie extraction may be broken for this browser due to Chromium security features."
        Write-Warning "If it doesn't work, consider using Mozilla Firefox instead."
        Print-Info "For more information, see: https://github.com/yt-dlp/yt-dlp/issues/10927"
    }

    if (-not $SkipBrowserPrompt) {
        Write-Host ""
        Write-Warning "To extract cookies from $CookiesFrom, the browser must be completely closed."
        Write-Host "Close the browser and press Enter to continue... " -ForegroundColor Yellow -NoNewline
        Read-Host
    }

    if ($CookiesFrom -eq 'yandex') {
        $ytArgs += @("--cookies-from-browser", "`"chromium:${env:LOCALAPPDATA}\Yandex\YandexBrowser\User Data`"")
    } else {
        $ytArgs += @("--cookies-from-browser", $CookiesFrom)
    }
}

# Audio-only specific arguments
if ($AudioOnly) {
    $ytArgs += @("--extract-audio", "--audio-format", $AudioFormat)
    
    if ($AudioFormat -eq "best") {
        Print-Info "Downloading audio only (best quality)..."
    } else {
        Print-Info "Downloading audio only (converting to ${AudioFormat})..."
    }
} else {

    if ($MinResolution -gt $MaxResolution) {
        Print-Diag "MaxResolution is smaller than MinResolution"
        Print-Diag "Setting MaxResolution to ${MinResolution}"
        $MaxResolution = $MinResolution
    }

    # Build resolution filter string
    $resolutionFilter = if ($MinResolution -gt 0) {
        "[height>=${MinResolution}][height<=${MaxResolution}]"
    } else {
        "[height<=${MaxResolution}]"
    }

    if ($MP4Output) {
        $formatString = @(
            "bestvideo${resolutionFilter}[vcodec^=avc1]+bestaudio[acodec^=mp4a]",
            "bestvideo${resolutionFilter}[vcodec^=avc1]+bestaudio",
            "bestvideo${resolutionFilter}+bestaudio",
            "best${resolutionFilter}"
        ) -join '/'
        
        $ytArgs += @(
            "--format", "`"${formatString}`"",
            "--merge-output-format", "mp4/mkv",
            "--remux-video", "mp4/mkv"
        )

        if ($MinResolution -gt 0) {
            Print-Info "Downloading video (${MinResolution}p-${MaxResolution}p, preferring MP4 with H.264)..."
        } else {
            Print-Info "Downloading video (up to ${MaxResolution}p, preferring MP4 with H.264)..."
        }
    } else {
        $ytArgs += @(
            "--format", "`"bestvideo${resolutionFilter}+bestaudio/best${resolutionFilter}`"",
            "--merge-output-format", "mkv",
            "--remux-video", "mkv"
        )
        
        if ($MinResolution -gt 0) {
            Print-Info "Downloading video (${MinResolution}p-${MaxResolution}p, best available format)..."
        } else {
            Print-Info "Downloading video (up to ${MaxResolution}p, best available format)..."
        }
    }
}

$LogFile = Join-Path -Path $OutputDir -ChildPath "yt-dlp_error.txt"

if ($ExtraArgs) {
    Print-Diag "Using extra arguments: ${ExtraArgs}"
    Write-Warning "Extra arguments are passed as-is, without any extra parsing."
    Write-Warning "This may result in misleading output messages or unexpected errors"
    $ytArgs += $ExtraArgs
}

Write-Debug "Arguments string: ${ytArgs}"

if ($Url.Count -gt 1) {
    Print-Header "Total number of URLs to download: $($Url.Count)"
}

$item = 0; $successCount = 0; $failCount = 0

foreach ($currentUrl in $Url) {
    $item++
 
    Write-Debug "URL: ${currentUrl}"
    
    # Create a unique temp file for each download's stderr
    $stderrFile = Join-Path $env:TEMP "ytdlp_stderr_${item}_$(Get-Random).txt"
 
    try {
        $finalArgs = $ytArgs + @($currentUrl)

        $process = Start-Process -FilePath "yt-dlp.exe" `
            -ArgumentList $finalArgs `
            -RedirectStandardError $stderrFile `
            -NoNewWindow -Wait `
            -PassThru

        $exitCode = $process.ExitCode

        if ($exitCode -eq 0) {
            if ($Url.Count -gt 1) {
                Print-Success "${item}. ${currentUrl}"
            }
            $successCount++
        } else {
            # Append this error to the master log
            if (Test-Path $stderrFile) {
                $utf8NoBom = New-Object System.Text.UTF8Encoding $false
                $stderr = [System.IO.File]::ReadAllText($stderrFile, $utf8NoBom)
                if ($stderr) {
                    $writer = New-Object System.IO.StreamWriter($LogFile, $true, $utf8NoBom)
                    
                    $writer.WriteLine("================================================================")
                    $writer.WriteLine("URL: ${currentUrl}")
                    $writer.WriteLine("Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
                    $writer.WriteLine("Exit Code: ${exitCode}")
                    $writer.WriteLine("================================================================")
                    $writer.WriteLine()
                    $writer.WriteLine($stderr)
                    
                    $writer.Dispose()
                }
            }
            
            if ($Url.Count -gt 1) {
                Print-Error "${item}. ${currentUrl}"
            } else {
                Print-Error "Download error!"
            }
            $failCount++
        }
    } catch {
        if ($Url.Count -gt 1) {
            Print-Error " Error!"
            Write-Debug "$_"
        }
        $failCount++
    } finally {
        # Clean up temp file
        if (Test-Path $stderrFile) {
            Remove-Item $stderrFile -Force -ErrorAction SilentlyContinue
        }
    }
}

Remove-Item -Path $TempPath -Recurse -Force -ErrorAction SilentlyContinue | Out-Null

# Summary for batch downloads
if ($Url.Count -gt 1) {
    Print-Header "Batch Download Summary"
    Write-Host "Total Url: $($Url.Count)"
    Print-Success "Successful: ${successCount}"
    if ($failCount -gt 0) {
        Write-Host "Failed: ${failCount}" -ForegroundColor Red
        Print-Info "See error log: ${LogFile}"
        Exit 1
    } else {
        Exit 0
    }
} else {
    if ($successCount -eq 1) {
        Print-Success "Download completed successfully!"
    } else {
        Print-Info "See error log: ${LogFile}"
        Exit 1
    }
}
