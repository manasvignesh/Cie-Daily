# Breakpoint cold-start experience

`SplashExperience` is mounted once in the MaterialApp builder above the real
GoRouter child. The `/` screen selects the existing authenticated destination.
It does not delay routing, and the overlay's two clipped panels reveal the actual
screen. No destination screen is duplicated or represented by a screenshot.

- Full: 3.35s point / stretch / fracture / wordmark / vector world, a restrained
  0.8s final-composition hold, then a deliberate 1.2s opening.
- Returning: 0.9s title sequence and 0.4s opening.
- Reduced motion: 0.5s gentle wordmark and 0.3s opacity handoff.
- Delayed auth: hold the final composition without a looping animation until
  a destination exists. Auth errors reveal the retry UI instead of holding forever.
- Backgrounding pauses controllers. Resuming continues, and never starts a new intro.

SharedPreferences stores `breakpoint.lastSeenSplashVersion` after a completed full
experience. Increment `SplashPreferences.experienceVersion` only for an intentional
major intro update. Storage has a bounded read and cannot block navigation.

Artwork is deterministic vector geometry; Outfit is bundled locally under the SIL
Open Font License. The font alias is splash-specific, leaving other typography alone.
Android native startup uses a black background and an 8dp signal point. There is no
iOS project in this checkout; Flutter composition is platform-independent.

Optional `onSoundCue` hooks are silent by default. Any future audio adapter must use
local assets, honor silent mode, and avoid blocking. No placeholder sound is shipped.

Verification: `flutter test test/splash_experience_test.dart`. Set `SPLASH_CAPTURE=1`
to export deterministic sequence frames into `build/splash-review` for review.
The tests cover persistence, full/quick timing, slow initialization, reduced motion,
resume and narrow/tall/tablet rendering. Physical GPU frame pacing and OS startup
must be checked on a connected device; widget tests cannot certify 60/120Hz performance.
