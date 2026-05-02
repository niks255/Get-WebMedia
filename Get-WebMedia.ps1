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
    Where downloaded files go.
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
    Falls back to best available if the minimum isn't met.
    Default: 0 (no minimum)
.PARAMETER MP4Output
    Force MP4 container with H.264 video and AAC audio for wide compatibility.
    Falls back to MKV with original codecs if H.264 isn't available.
.PARAMETER NoProxy
    Bypass all proxies completely.
.PARAMETER ProxyAddress
    Specific proxy server to route through.
    Also checks the YTDLP_PROXY environment variable and system proxy settings.
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
    Update yt-dlp, ffmpeg, and deno to their latest versions.
    Also checks for updates automatically once per day when YTDLP_CHECK_UPDATES=1.
.PARAMETER FullPlaylist
    Download the whole playlist instead of just the first video.
.PARAMETER Overwrite
    Replace existing files rather than skipping them.
.PARAMETER ExtraArgs
    Additional yt-dlp arguments passed straight through to the tool.
    Example: "--write-subs --sub-lang en --embed-thumbnail"
.EXAMPLE
    # Download a single video
    .\Get-WebMedia.ps1 "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
.EXAMPLE
    # Grab several videos at once
    .\Get-WebMedia.ps1 -Url "https://youtu.be/abc123", "https://youtu.be/def456"
.EXAMPLE
    # Work through a list of URLs from a file
    .\Get-WebMedia.ps1 -File "urls.txt"
.EXAMPLE
    # Audio only, converted to MP3
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -AudioOnly -AudioFormat mp3
.EXAMPLE
    # Audio only, best available quality (no conversion)
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -AudioOnly -AudioFormat best
.EXAMPLE
    # An entire playlist capped at 720p
    .\Get-WebMedia.ps1 "https://youtube.com/playlist?list=..." -FullPlaylist -MaxResolution 720
.EXAMPLE
    # 4K video saved as MP4
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -MaxResolution 2160 -MP4Output
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
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -ExtraArgs "--write-subs --sub-lang en --embed-thumbnail"
.EXAMPLE
    # Save to a custom folder
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -OutputDir "D:\Videos"
.EXAMPLE
    # Overwrite existing files instead of skipping
    .\Get-WebMedia.ps1 "https://youtu.be/abc123" -Overwrite
.EXAMPLE
    # Just update the tools, nothing else
    .\Get-WebMedia.ps1 -UpdateTools
.NOTES
    Filename: Get-WebMedia.ps1
    Requirements: PowerShell 5.1+ and winget
    Environment variables:
      YTDLP_CHECK_UPDATES - Set to 1 to enable automatic daily update checks
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

    [Parameter(HelpMessage="Minimum video resolution in pixels. Falls back to best available if not met.")]
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
    
    [Parameter(HelpMessage="Download entire playlist instead of just first video")]
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

function Print-Muted {
    param([string]$Message)
    Write-Host $Message -ForegroundColor DarkGray
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
    ) -join ';' -split ';' | Select-Object -Unique) -join ';'
}

# Helper function to install/update via winget
function Install-WithWinget {
    param(
        [string]$ToolName, 
        [string]$PackageName
    ) 
       
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Print-Info "Installing/updating ${ToolName}..."

        winget install $PackageName --accept-package-agreements --accept-source-agreements 2>&1 |
            Where-Object { $_.ToString().Trim() -ne '' -and $_ -notmatch '^\s*-+\s*$' } |
            Write-Debug
        $exitCode = $LASTEXITCODE
        Write-Debug "WinGet returned ${exitCode}"

        # Winget exit codes https://github.com/microsoft/winget-cli/blob/master/doc/windows/package-manager/winget/returnCodes.md
        $APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE = -1978335189
        $success = ($exitCode -eq 0 -or $exitCode -eq $APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE)

        if ($success) {
            if ($exitCode -eq 0) {
                Print-Success "  Successfully installed/updated ${ToolName}"
            } else {
                Print-Success "  ${ToolName} is already up to date"
            }
        } else {
            Print-Error "  Failed to install ${ToolName} (Exit code: ${exitCode})"
        }
        Update-Path
        return $success
    } else {
        Write-Warning "winget is not available."
        Print-Muted "Please install ${ToolName} manually:"
        switch ($ToolName) {
            "yt-dlp"  { Print-Muted "  https://github.com/yt-dlp/yt-dlp/releases/latest" }
            "deno"    { Print-Muted "  https://github.com/denoland/deno/releases/latest" }
            "ffmpeg"  { Print-Muted "  https://github.com/yt-dlp/FFmpeg-Builds/releases/latest" }
        }

        return $false
    }
}

function Install-Tool {
    param(
        [string]$ToolName, 
        [string]$PackageName
    )
    if (Get-Command $ToolName -ErrorAction SilentlyContinue) {
        if ($UpdateTools) {
            Print-Info "Checking for updates for ${ToolName}"
        } else {
            return $true
        }
    } else {
        Write-Warning "${ToolName} is not installed or not found in PATH"
    }

    return Install-WithWinget -ToolName $ToolName -PackageName $PackageName
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

if ($UpdateTools) { Print-Header "Checking/updating tools" }
Update-Path
$allToolsAvailable = (Install-Tool -ToolName "yt-dlp" -PackageName "yt-dlp.yt-dlp") -and `
                     (Install-Tool -ToolName "deno" -PackageName "DenoLand.Deno") -and `
                     (Install-Tool -ToolName "ffmpeg" -PackageName "yt-dlp.FFmpeg")
if ($UpdateTools) {    
    Print-Header "Tool check complete!"
} else {
    if (-not $allToolsAvailable) {
        Print-Error "Cannot proceed due to missing tools."
        Exit 1
    }
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
    '--progress', '--quiet', '--verbose',
    '--encoding', 'UTF-8', "--embed-metadata",
    "--paths", "temp:temp_files", "--paths", "`"${OutputDir}`""
)

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
            # Case 1: H.264 + AAC → MP4 with stream copy (no re-encode)
            "bestvideo${resolutionFilter}[vcodec^=avc1]+bestaudio[acodec^=mp4a]",
            # Case 2: H.264 + non-AAC audio → MP4 (video copied, audio → AAC)
            "bestvideo${resolutionFilter}[vcodec^=avc1]+bestaudio",
            # Case 3: No H.264 → MKV, no conversion at all
            "bestvideo${resolutionFilter}+bestaudio"
        ) -join '/'
        
        $ytArgs += @(
            "--format", "`"${formatString}`"",
            "--merge-output-format", "mp4/mkv"
        )

        if ($MinResolution -gt 0) {
            Print-Info "Downloading video (${MinResolution}p-${MaxResolution}p, preferring MP4 with H.264)..."
        } else {
            Print-Info "Downloading video (up to ${MaxResolution}p, preferring MP4 with H.264)..."
        }
    } else {
        $ytArgs += @(
            "--format", "`"bestvideo${resolutionFilter}+bestaudio`"",
            "--merge-output-format", "mkv"
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
