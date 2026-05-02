# Get-WebMedia

A user-friendly media downloader for YouTube and hundreds of other sites. Powered by [yt-dlp](https://github.com/yt-dlp/yt-dlp).

## 📦 What's in this repo?

You have two options — pick the one that suits you:

| File | Best for |
|------|----------|
| `Get-WebMedia.cmd` | Everyone. Double-click, paste a link, done. |
| `Get-WebMedia.ps1` | Power users who want full control via command-line parameters. |

> **Both files are completely self-contained.** The `.cmd` file embeds the PowerShell script inside itself — no extra files needed. You only need the one you choose.

## ⚡ Quick Start (For Everyone)

1. **Download `Get-WebMedia.cmd`** and save it anywhere
2. **Double-click it**
3. **Paste a video URL** when prompted
4. **Choose your mode:**
   - `[1]` Video (MP4, up to 1080p)
   - `[2]` Audio only (MP3)
5. **Optionally select a browser** for cookies (needed for age-restricted content)
6. **Done!** Files land in `Downloads\yt-dlp\`

### 💡 Batch Downloads
To download multiple videos at once:
1. Create a file called `links.txt` in your Downloads folder
2. Paste your URLs (one per line)
3. Run `Get-WebMedia.cmd` — it will detect the file and ask if you want to use it

## 🔧 Requirements

- **Windows 10/11**
- **PowerShell 5.1** (built into Windows)
- **[winget](https://github.com/microsoft/winget-cli)** (built into modern Windows 10/11)

The script automatically installs these tools on first run:
- **[yt-dlp](https://github.com/yt-dlp/yt-dlp)** — Download engine
- **[FFmpeg](https://ffmpeg.org/)** — Media processing
- **[Deno](https://deno.land/)** — JavaScript runtime for site-specific extractors

## ✨ Features

- **Bilingual interface** — Automatically detects Russian or English
- **Auto-updating tools** — Checks for updates once per day
- **Cookie extraction** — Firefox, Opera, Brave, Vivaldi, Yandex (for age-restricted content)
- **Batch downloads** — From `links.txt` or multiple URLs
- **Resolution control** — 144p through 8K, with min/max limits
- **Format selection** — MP4/H.264/AAC or original codecs
- **Audio extraction** — MP3, M4A, AAC, Opus, FLAC, WAV, Vorbis
- **Playlist support** — Single video or full playlist
- **Proxy support** — Automatic system proxy detection or manual config
- **Error logging** — Detailed logs for troubleshooting

## 📖 Advanced Usage (`Get-WebMedia.ps1`)

If you prefer the PowerShell script directly, here are some examples:

```powershell
# Single video (default: up to 1080p, original format)
.\Get-WebMedia.ps1 "https://www.youtube.com/watch?v=dQw4w9WgXcQ"

# Multiple videos
.\Get-WebMedia.ps1 -Url "https://youtu.be/abc123", "https://youtu.be/def456"

# From a text file
.\Get-WebMedia.ps1 -File "urls.txt"

# 4K video forced to MP4
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -MaxResolution 2160 -MP4Output

# Audio only, converted to MP3
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -AudioOnly -AudioFormat mp3

# Entire playlist at 720p
.\Get-WebMedia.ps1 "https://youtube.com/playlist?list=..." -FullPlaylist -MaxResolution 720

# Age-restricted content (Firefox must be closed)
.\Get-WebMedia.ps1 "https://youtu.be/restricted" -CookiesFrom firefox

# Custom output folder
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -OutputDir "D:\Videos"

# With subtitles and embedded cover art
.\Get-WebMedia.ps1 "https://youtu.be/abc123" -ExtraArgs "--write-subs --sub-lang en --embed-thumbnail"

# Update tools only, no download
.\Get-WebMedia.ps1 -UpdateTools