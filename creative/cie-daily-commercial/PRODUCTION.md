# CIE Daily — Signal

Production package for a 15-second vertical commercial. This is an edit specification, not a rendered video. Final footage, voiceover, screen captures and audio mix are still required.

## Master

1080 × 1920, 9:16, 30 fps, exactly 450 frames / 15.000 seconds. Deliver H.264 MP4, Rec.709, stereo AAC 48 kHz. Finish audio and picture together at frame 450. Use 2160 × 3840 acquisition where available. No speed changes on the final export.

The visual idea is a change of attention: restless scrolling gives way to deliberate discovery. Keep one consistent, unbranded graphite smartphone throughout. Real glass, rounded screen, physical side buttons, stable camera geometry. No floating screens or simulated holograms.

## Frame-accurate edit

All out points below are exclusive.

| Frames | Time | Picture | Type / sound |
| --- | --- | --- | --- |
| 0–54 | 0.00–1.80 | Close over-shoulder shot of a young adult scrolling one-handed in a dark room. Three quick swipes. Reflected screen changes provide the visual noise; no elaborate background props. | Soft, irregular swiping ticks over a restrained low pulse. No recognizable social-media brands or private messages. |
| 54–90 | 1.80–3.00 | Freeze on the last swipe. Hold the person, hand and phone absolutely still. | “Too much noise?” resolves sharply. One short bass hit at frame 54; scrolling sound cuts immediately. |
| 90–132 | 3.00–4.40 | Match the phone position into a warm-white studio. A narrow edge reflection reveals the graphite body. Ease toward the real CIE Daily Discover screen. | “Discover what actually matters.” appears as two compact lines. Music opens into a spare, brighter rhythm. |
| 132–210 | 4.40–7.00 | Move closer as the real Discover deck swipes twice. Feature clear, actually published AI / engineering / startup stories with their relevant images. Secondary tech/project topics can appear in the visible feed; do not cram five unreadable cards into this beat. | Keep the headline overlay fixed. Two quiet, tactile swipe accents. |
| 210–240 | 7.00–8.00 | Three-quarter macro of a Swipe Deck card settling flush with the screen. | Voiceover begins: “Tech.” One dry rhythmic accent. |
| 240–270 | 8.00–9.00 | Match cut to the same article opening into its full story. Let headline and section hierarchy settle. | “Ideas.” |
| 270–300 | 9.00–10.00 | Tight frontal view of current Spaces / community discovery. Preserve the real availability state. If nothing is live, show the honest “Opening soon” view, never a fabricated live room. | “People.” |
| 300–330 | 10.00–11.00 | Real in-app share action with a consenting test recipient; cut on successful share confirmation. Keep private content and names out of frame. | “One place.” Music reaches its modest peak. |
| 330–354 | 11.00–11.80 | Phone eases upright over a charcoal seamless background. Its home screen stays visible. Gentle edge light, grounded contact shadow. | Music simplifies. Phone settles rather than spins. |
| 354–378 | 11.80–12.60 | Current CIE Daily logo fades in below the phone, followed by the brand name. Keep screen and logo geometry unchanged. | “CIE Daily”. Short clean tonal resolve. |
| 378–408 | 12.60–13.60 | Hold the composition. | “Stay curious. Stay ahead.” |
| 408–450 | 13.60–15.00 | Final locked hero. Screen remains bright enough to identify Discover. | “Download now”. Subtle two-note logo sound at 14.10; decay ends by 15.00. |

## Art direction grounded in the repository

- Accent: `#FF5A1F`; dark background `#08080A`; surface `#141419`; warm-white text `#F5F5F7`; light background `#F6F6F4`.
- Type: existing Inter for ad copy, Outfit for brand heading when matching the app. White/ink only, orange reserved for accents. No imitation Apple/Nothing marks or wordmarks.
- Current logo reference: `app/assets/icons/app_logo.png` — the orange/black bookmark mascot. Use this real asset, not the earlier compass logo. Its warm-white background can appear as a small, deliberately framed app icon on the dark end card. Do not generate a replacement logo.
- The app UI stays the real app UI even when the surrounding set switches from dark to bright.
- At 1080 width use approximately 64 px headlines, 42 px tagline and 36 px CTA. Keep essential copy inside x=96…900, y=210…1570 to allow social-player overlays. Screen detail may extend outside this copy area.
- Final composition: phone around x=365…715, y=225…985; icon/brand lockup around y=1100; tagline around y=1290; CTA around y=1420. Adjust optically, preserving breathing room.
- Lens character: restrained 50–85 mm equivalent; soft large key; negative fill; crisp edge light. Avoid excessive depth blur that makes the UI unreadable.
- Motion: slow 8–12° camera orbit, controlled dolly, eased arrival; no full revolutions. Fast editing provides energy, not exaggerated camera animation.

## Capture checklist

Capture these from the current Flutter app on a clean test account. Preserve current app navigation and copy. Select published stories; do not fabricate headlines, metrics, sessions or endorsements.

1. `01-discover.mp4`: 6 seconds, settled Discover screen followed by two completed deck swipes. Relevant article photos visible. No debug overlays.
2. `02-full-story.mp4`: 3 seconds, open a card into that same article; show its real full-story hierarchy.
3. `03-spaces.mp4`: 3 seconds, current Spaces page and its truthful live/soon state. The saved `device-screen*.png` files are historical test data and must not be used as final screens.
4. `04-share.mp4`: 3 seconds, share with a consenting test recipient. Use a dedicated test conversation; exclude personal messages and email addresses.
5. `05-home-still.png`: clean current Discover screen for the closing hold.

Capture at native resolution, ideally 60 fps for retiming. Allow one second of stillness at both ends. Disable notification interruptions during capture. Composite these recordings onto tracked phone screens; do not ask a video model to redraw legible app text.

## Footage prompts

Generate silent visual plates separately, with several seconds of handles. Add exact text, real UI, logo, voice and sound in the edit. Reuse one approved phone/person reference for consistency.

### A — problem plate

Vertical 9:16 photographic technology commercial. Close over the shoulder of a young adult in an ordinary dark interior, casually holding one graphite smartphone vertically. Natural hand anatomy, believable grip, thumb makes three quick scrolling gestures. Changing phone light subtly crosses the fingertips and face edge. Abstract, unbranded social feed shapes on the screen, to be replaced in post. The background feels restless through shallow focus and changes in reflected light, not clutter. Black wardrobe, neutral tones, soft practical sidelight. High-end live-action cinematography, believable skin texture and glass reflections. Stable screen corners for tracking. No text overlays, no logos, no music, no floating UI, no warped fingers, no morphing phone. Frame to leave negative space for the later question. Freeze is added editorially at 1.80 seconds.

### B — reveal plate

Vertical 9:16 luxury smartphone product cinematography. The same unbranded graphite smartphone, straight screen plane and coherent physical thickness, upright at a slight three-quarter angle against a warm-white seamless studio. Large soft key light, fine edge reflection, subtle contact shadow. Camera makes a slow controlled push and shallow orbit while the device stays stable. Screen is evenly lit with a neutral dark tracking surface; preserve all corners and keep reflections weak over the screen so real app footage can be composited. Photographic materials, realistic specular rolloff, no excessive glow, no floating graphical elements, no text, no logos. Calm precise movement suitable for a hard match cut from a handheld phone shot.

### C — experience plates

Create consistent variations of the reveal plate: first a three-quarter macro of the front glass; second a nearly frontal close-up; third a slightly lower angle with the whole display legible; fourth a hand naturally tapping the phone screen once. Preserve the same phone silhouette, lens character and light source. Use subtle movement and stable geometry. Each will carry a real CIE Daily screen recording. No generated interface text. No dramatic tilting that hides the display. No fingers occluding the key content area for more than a few frames.

### D — closing plate

Vertical 9:16 photographic smartphone hero shot on a minimal charcoal seamless studio background. Same graphite smartphone standing vertically in the upper-center, soft grounded shadow, understated warm-white edge highlights, neutral dark screen prepared for post-production replacement. Slow camera settles into a straight, symmetrical hold with the phone in the upper half. Leave the lower half uncluttered for an existing app logo and three short lines of copy. Premium, quiet, tactile product photography. No neon, no particles, no added typography, no imaginary branding. Hold the last composition perfectly still.

## Voice and sound

Voiceover verbatim: “Tech. Ideas. People. One place.” Warm, composed adult voice with natural conversational delivery. Seven words across frames 212–323; slight pauses after each sentence, no announcer hype. Confirm the recorded delivery fits 3.7 seconds without unnatural speed-up.

Use original or cleared instrumental audio: restrained pulse, tactile clicks, small percussive lift and a warm sustained tone. No stock corporate ukulele, epic trailer drums, vocal chops or copied brand sonic signatures. Duck the instrumental approximately 5 dB during speech. Target approximately -14 LUFS integrated, true peak at or below -1 dBTP; judge clarity on a phone speaker. Bass hit must remain audible through a short mid-frequency component. Keep final decay within the 15-second master.

## Final verification

Inspect every cut, and pause at each screen for correct logos, titles and navigation. Verify no invented product state, no warped phone/fingers, no private user details and no double-exposure UI. Ensure sharing is clearly an in-app action. Check the first two seconds without audio, then listen on phone speakers. Check the finish at native resolution and small social-player scale. Verify exactly 450 frames, 1080×1920, 30 fps, 15.000 seconds and no trailing black/audio frames. The production package is not evidence that these checks passed; perform them on the final rendered MP4.
