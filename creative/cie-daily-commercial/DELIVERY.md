# CIE Daily — Dark Mode commercial

Deliverable: `CIE-Daily-Dark-Mode-15s.mp4`

The user's supplied WhatsApp recording is the sole app-screen source. The edit emphasizes the authentic dark-mode Discover, Swipe Deck, Full Story, and Spaces screens. Spaces is explicitly labeled **Opening soon**; no active room is fabricated.

## Edit

- 0–3 seconds: abstract scrolling typography, freeze, “Too much noise?”
- 3–7 seconds: dark-mode phone reveal and actual Swipe Deck interaction.
- 7–11 seconds: Tech / Ideas / People / One place product cuts.
- 11–15 seconds: existing mascot logo, CIE Daily, tagline, and Download now.

This is a product-motion-graphics commercial, not generated live-action footage. The earlier PRODUCTION.md describes the original cinematic concept; this delivered version adapts it to the user's chosen no-AI-video-credit option and dark-mode request.

The source is 390 × 850 and was compressed by WhatsApp. Exporting at 1080 × 1920 does not recover missing source detail. App footage is kept inside a phone mockup; typography and surrounding graphics are rendered at delivery resolution.

The login, personal profile, contact screens, screen-recorder controls, Android status/navigation bars, and original source audio are excluded. The crop also removes the right-edge recorder dot. The existing logo is used without redrawing or recoloring it.

Audio is an original synthesized instrumental bed with subtle transition accents and a two-note finish. No third-party song or source-recording audio is used. There is no spoken voiceover; the requested phrase is presented as on-screen titles.

## Reproducibility

`render_dark_ad.py` renders 450 frames at 30 fps with Pillow and encodes H.264/AAC using a local imageio-ffmpeg dependency. `render-manifest.json` records source, dimensions, duration, logo, and audio provenance. `edit-contact.jpg` shows the reviewed composition at twelve moments.

All production files are isolated under `creative/cie-daily-commercial`. No Flutter code or backend behavior is changed.

## Verification performed

- Complete encoded MP4 decoded successfully with FFmpeg (exit 0).
- Exactly 450 decoded frames, 30 fps, 15.00 seconds, 1080 × 1920.
- H.264 video, stereo AAC audio at 48 kHz; fast-start MP4.
- Measured audio: -17.0 LUFS integrated, -1.5 dBFS true peak.
- Reviewed twelve full-resolution pre-encode compositions and a fifteen-frame contact sheet decoded from the delivered MP4.
- Output size: 3,913,471 bytes.
- Audio checked technically for levels/duration; no claim of a physical phone-speaker listening test.
