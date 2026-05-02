# Get-WebMedia

A user-friendly media downloader for YouTube and hundreds of other sites. Powered by [yt-dlp](https://github.com/yt-dlp/yt-dlp).

## 📦 What's in this repo?

You have two options — pick the one that suits you:

| File | Best for |
|------|----------|
| `Get-WebMedia.cmd` | Everyone. Double-click, follow the prompts, done. |
| `Get-WebMedia.ps1` | Power users. Pass parameters directly for full control. |

> **Both files are completely self-contained.** The `.cmd` file embeds the PowerShell script inside itself — no extra files needed. You only need the one you choose.

## 🖱️ .cmd vs ⌨️ .ps1 — What's the difference?

| | `Get-WebMedia.cmd` | `Get-WebMedia.ps1` |
|--|--------------------|--------------------|
| **How it works** | Interactive — double-click, follow prompts | Parameter-based — pass arguments directly |
| **Interface language** | Bilingual (auto-detects Russian or English) | English only |
| **Video format** | Prefers MP4 (H.264/AAC) | Best available (MKV, original codecs) |
| **Audio format** | MP3 | Best available (no conversion) |
| **Resolution** | Up to 1080p | Up to 1080p (adjustable) |
| **Batch downloads** | Drop a `links.txt` in Downloads | `-File "path\to\urls.txt"` |
| **Cookies** | Choose from a menu | `-CookiesFrom firefox` |
| **Tool updates** | Automatic, once per day | Opt-in via environment variable |

> **In short:** `.cmd` guides you through it. `.ps1` expects you to know what you want.

## ⚡ Quick Start (For Everyone)

1. **Download `Get-WebMedia.cmd`** and save it anywhere
2. **Double-click it**
3. **Paste a video URL** when prompted
4. **Choose your mode:**
   - `[1]` Video (prefers MP4, up to 1080p)
   - `[2]` Audio (MP3)
5. **Optionally select a browser** for cookies (needed for age-restricted content)
6. **Done!** Files land in `Downloads\yt-dlp`

### 💡 Batch Downloads
To download multiple videos at once:
1. Create a file called `links.txt` in your Downloads folder
2. Paste your URLs (one per line)
3. Run `Get-WebMedia.cmd` — it will detect the file and ask if you want to use it

## 🔧 Requirements

- **Windows 10 or higher**
- **Windows PowerShell 5.1** (built into Windows) or cross-platform **[PowerShell](https://github.com/PowerShell/PowerShell)**
- **[WinGet](https://github.com/microsoft/winget-cli)** (built into modern Windows 10/11)

The script automatically installs these tools on the first run through WinGet:
- **[yt-dlp](https://github.com/yt-dlp/yt-dlp)** — Download engine
- **[FFmpeg](https://ffmpeg.org/)** — Media processing
- **[Deno](https://deno.land/)** — JavaScript runtime for site-specific extractors

## ✨ Features

- Grabs the best quality video up to your chosen resolution
- Extracts audio in your preferred format (MP3, M4A, FLAC, etc.)
- Outputs MP4/H.264/AAC for best compatibility, or keeps the original format
- Works through proxies and detects system proxy settings automatically
- Pulls cookies from your browser for age-restricted or members-only content
- Handles batch downloads from text files or multiple URLs
- Automatically installs and updates required tools via winget

## 📖 Advanced Usage (`Get-WebMedia.ps1`)

If you prefer the PowerShell script directly, here are some examples:

```powershell
# Download a single video
.\Get-WebMedia.ps1 "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Grab several videos at once
.\Get-WebMedia.ps1 -Url "https://youtu.be/abc123", "https://youtu.be/def456"

# Work through a list of URLs from a file
.\Get-WebMedia.ps1 -File "links.txt"

# Audio only, converted to MP3
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -AudioOnly -AudioFormat mp3

# Audio only, best available quality (no conversion)
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -AudioOnly -AudioFormat best

# An entire playlist capped at 720p
.\Get-WebMedia.ps1 "https://youtube.com/playlist?list=..." -MaxResolution 720

# 720p video saved as MP4 if possible
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -MaxResolution 720 -MP4Output

# Video at minimum 720p, maximum 1080p
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -MinResolution 720 -MaxResolution 1080

# Age-restricted content using Firefox cookies (skipping the prompt)
.\Get-WebMedia.ps1 "https://youtu.be/restricted" -CookiesFrom firefox -SkipBrowserPrompt

# Route traffic through a SOCKS5 proxy
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -ProxyAddress "socks5://127.0.0.1:1080"

# Include subtitles and cover art
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -ExtraArgs "--write-subs --embed-thumbnail"

# Save to a custom directory
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -OutputDir "D:\Videos"

# Overwrite existing files instead of skipping
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -Overwrite

# Update tools and exit
.\Get-WebMedia.ps1 -UpdateTools