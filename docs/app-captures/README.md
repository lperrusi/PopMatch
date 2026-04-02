# App captures (web run)

## What’s here

| File | Description |
|------|-------------|
| `01-onboarding.png` | PopMatch web after load — onboarding “Swipe to match” frame. |
| `02-after-next.png` | Same flow after a canvas tap (minor visual change in this run). |
| `onboarding_walkthrough.gif` | Short animated loop (2.5s per frame) between the two PNGs — lightweight stand-in for a screen recording. |

## How these were produced

1. **Web support** was added with `flutter create . --platforms=web`.
2. The app was run as **`flutter run -d web-server --web-port=9201 --web-hostname=127.0.0.1`** (see IDE terminal; press `q` to stop).
3. **Browser automation** opened `http://127.0.0.1:9201` and took screenshots.

## Limits (Flutter Web + automation)

The UI is drawn on a **CanvasKit / HTML canvas**, so accessibility nodes are minimal (`flutter-view` only). **Taps don’t reliably hit** in-app buttons (e.g. onboarding “next”), so we could not fully drive **Discover**, **For You**, **Profile**, etc. through the browser tool alone.

For **full-flow screenshots or real video**:

- Run **`flutter run -d chrome`** or on a **device/simulator**, then use **QuickTime Player → File → New Screen Recording** (macOS) or **OBS**.
- Or add **`integration_test`** and drive gestures with `tester.tap` / `tester.drag`, optionally with **golden file** images.

## MP4 video

No MP4 was generated here (`ffmpeg` was not available in the environment). Use screen recording as above, or install **ffmpeg** and convert the GIF:  
`ffmpeg -i onboarding_walkthrough.gif -movflags faststart -pix_fmt yuv420p onboarding_walkthrough.mp4`
