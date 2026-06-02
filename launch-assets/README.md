# launch-assets

Promotional assets generated from the example app screen recording on
2026-06-02. Source video (`launch-source.mov`, 47MB) is git-ignored to keep
the repo light.

| File | Dimensions | Size | Where to use |
|---|---|---|---|
| `hud-demo.gif` | 1200×780, 15fps, 12s | 7.9 MB | Twitter, README hero, dev.to |
| `hud-demo-small.gif` | 720×468, 12fps, 12s | 2.9 MB | Reddit, Mastodon, anywhere with stricter size caps |
| `hud-static.png` | 1200×630 | 180 KB | LinkedIn post, Hacker News thumbnail, OG card |
| `hud-zoom.png` | 800×480 | 114 KB | README HUD section, inline tweet replies |

## Regenerating

```bash
SRC="launch-source.mov"

# Demo GIF — 1200px, 15fps, 12s window starting at t=20s
ffmpeg -y -ss 20 -t 12 -i "$SRC" \
  -vf "fps=15,scale=1200:-1:flags=lanczos,palettegen=max_colors=192:stats_mode=diff" \
  /tmp/pal.png
ffmpeg -y -ss 20 -t 12 -i "$SRC" -i /tmp/pal.png \
  -lavfi "fps=15,scale=1200:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
  launch-assets/hud-demo.gif

# Static OG — pick a populated-HUD frame, scale, bottom-anchor crop
ffmpeg -y -ss 28 -i "$SRC" -vframes 1 -vf "scale=1200:-1:flags=lanczos" /tmp/full.png
ffmpeg -y -i /tmp/full.png -vf "crop=1200:630:0:150" launch-assets/hud-static.png

# HUD close-up — native res crop, scale to 800px
ffmpeg -y -ss 28 -i "$SRC" -vframes 1 /tmp/native.png
ffmpeg -y -i /tmp/native.png \
  -vf "crop=620:380:2280:1450,scale=800:-1:flags=lanczos" \
  launch-assets/hud-zoom.png
```
