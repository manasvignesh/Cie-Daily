# BREAKPOINT — Worth stopping for.

A 29-second, 1080 × 1920, 60 fps launch film built in Remotion/React. All product imagery is captured from the real Android app, version 1.1.21 (32), on a physical device. No product UI is generated or reconstructed.

## Install / preview / render

Node.js 22+ and npm are required. FFmpeg is needed only to prepare replacement footage and make social exports; the Remotion renderer manages its own browser/video dependencies.

```powershell
npm ci
npm run preview
npm run render
npm run still
node finish.cjs
node verify.cjs
```

The first render may download Chrome Headless Shell. Do not expose the preview server publicly. Remotion's own commercial-license terms apply to the organization using the source: https://www.remotion.dev/license

## Deliverables

- `out/breakpoint_launch_master_1080x1920_60fps.mp4`
- `out/breakpoint_launch_social.mp4`
- `out/breakpoint_launch_poster.png`
- `src/`: complete editable composition and reusable components
- `review/`: render-review frames and technical verification (not advertising assets)

## Source and reusable components

- `src/Launch.tsx`: shot timing, editorial composition, exported EndCard
- `src/system.tsx`: Phone, Wordmark, Dot, OrangeWipe, Copy, Breakout, Environment and easing
- `src/index.tsx`: 1740-frame composition at 60 fps
- `public/footage/`: real device recordings and exact crops
- `public/Outfit.ttf`: locally bundled app typeface; license in `public/OFL-Outfit.txt`
- `sound.cjs`: original stereo synthesis and event timing
- `prepare.cjs`: deterministic cropping and constant-frame-rate preparation
- `finish.cjs` / `verify.cjs`: social/poster/review-frame exports and technical checks
- `capture.ps1`: isolated ADB short-take helper; review gestures before reusing on another device

The delivery ZIP includes all playback-ready footage, fonts and audio needed to render. Raw takes and private review/UI dumps are intentionally excluded. `prepare.cjs` is provided for preparing **new replacement recordings**; it does not need to be run to render the delivered source.

## Replacing captures

Capture the real production-like app at 1080 × 2340 with safe test content. The current crop removes only the OS bars: `crop=1080:2080:0:110`. Adapt this if the device resolution changes; do not stretch mismatched UI. Update names and shot trims in `src/Launch.tsx`.

```powershell
# Optional if FFmpeg is not on PATH:
$env:FFMPEG_PATH = 'C:\path\to\ffmpeg.exe'
node prepare.cjs
node sound.cjs
ffmpeg -i public/soundtrack.wav -af "loudnorm=I=-17:TP=-1.5:LRA=6" -ar 48000 -c:a pcm_s24le public/soundtrack-master.wav
npm run render
```

ADB screen recordings are variable-frame-rate and may stop writing frames while the UI is static. Preparation explicitly holds the last real frame and converts to 60 fps. Camera motion/compositing runs at native 60 fps; source app/video frames are not falsely claimed to be captured at 60 fps. No optical-flow-generated UI frames are used.

The Connect source uses only the editor-approved `abcd2` conversation. A short demonstration message was sent successfully. The finished composition uses a tight crop of that message and its composer; old test chatter is excluded. A cut from the recorded sending state to the real captured sent state compresses the wait without inventing a delivery indicator. No new incoming response is fabricated. Replacing this take must retain that privacy boundary. Do not capture personal chats, connection codes or notifications.

Spaces shows the real no-live-session state. The film does not fabricate a live event. The Reel is actual in-app content and its original audio is muted. Confirm that the app owner has the necessary promotional rights/participant releases for any in-app article photography and Reel used in a public campaign.

## Audio source / license

`public/soundtrack.wav` is an original, deterministic synthesized score created for this campaign by `sound.cjs`. `soundtrack-master.wav` is its loudness-mastered version used in the film. It contains no downloaded music, sampled recordings, voiceover or third-party sound effects. It may be used and edited with this campaign without a stock-music license. The audio source is included for replacement/re-timing.

Key sound events: breakpoint stop at frame 55; Discover 135; deck 345; Listen 600; Spaces 780; Connect 1020; Reels 1260; crescendo 1440; brand payoff 1602. Stereo PCM source is 48 kHz; exports use AAC.

## Safety / provenance

No Flutter, backend, authentication or notification code was edited for this film. The installed app already matched the latest local release, so no reinstall was necessary. Capture temporarily changed screen timeout from 30 seconds to 10 minutes and enabled Do Not Disturb. Restoration commands returned successfully after capture (30 seconds / notifications allowed); the phone disconnected before a later read-back verification. No font/display scaling or permanent device customization was performed.

The supplied ConversBank reference was used for analysis only. None of its footage, audio, logo, copy or product artwork is included. The end-card uses plain “Available on Google Play” text, not an invented official store badge.

## Exporting a social copy

```powershell
ffmpeg -i out/breakpoint_launch_master_1080x1920_60fps.mp4 -c:v libx264 -preset slow -crf 22 -pix_fmt yuv420p -r 60 -c:a aac -b:a 192k -movflags +faststart out/breakpoint_launch_social.mp4
```

Do not upload the raw capture/review folder to marketing platforms. Use only the approved master, social copy and poster.
