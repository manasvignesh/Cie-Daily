# CieDaily — Development Evidence Mapping Document

## Overview
This document provides an objective, verifiable mapping between the technical development milestones of **CieDaily** and their underlying digital evidence. Every claim in this documentation is anchored in version control records (Git logs), source code artifacts, system build outputs, or stored project context.

---

## Evidence Mapping Matrix

| Claim / Milestone | Evidence Type | Exact Source / Reference | Confidence Level | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Initial UI & Feed Concept** | System Artifact | `media__1785864353835.jpg` (2026-08-04 17:26:04 UTC) | **High** | Earliest stored UI mockup demonstrating campus feed layout prior to Git tracking. |
| **Source Code Baseline Archive** | System Artifact | `app_source_code.zip` & `tree.txt` (2026-08-05 13:29:13 UTC) | **High** | Complete snapshot of initial Flutter application code structure before first Git commit. |
| **Git Tracking Setup** | Git Commit | Hash `671bc613675fb00e4f4f9bcdb2db1f4467cce1b3` (2026-08-05 20:49:27 +0530) | **High** | First tracked commit containing 72 files and initial Flutter architecture. |
| **Firestore Schema Design** | System Artifact | `firestore_schema.md` (2026-08-06 08:13:52 UTC) | **High** | Formal document specifying collections for `/users`, `/posts`, `/conversations`, and `/spaces`. |
| **Admin RBAC Specifications** | System Artifact | `admin_panel_plan.md` (2026-08-08 15:42:14 UTC) | **High** | Role specifications defining Main Admin (`manasvig43@gmail.com`), Creators, and Student access controls. |
| **Admin Panel & Security Rules** | Git Commit | Hash `de1d4f70e18e1dcd6905c16b78df5a2a33037591` (2026-08-08 21:34:39 +0530) | **High** | Git commit implementing Admin screens and security rules in `firestore.rules`. |
| **Production UI/UX Redesign** | System Artifact | `implementation_plan.md` (2026-08-15 16:40:42 UTC) | **High** | Design overhaul specification covering 8 design phases and custom swipe navigation shell. |
| **Swipe Navigation & Layout Fixes** | Source Code & Log | `lib/core/router/app_router.dart` & `walkthrough.md` (2026-08-15 17:11:12 UTC) | **High** | Fixed `999746px` overflow using `StackFit.expand` and eliminated `_dependents.isEmpty` assertion error. |
| **Google Sign-In OAuth Fix** | Build Log | CLI Task 7858 & `android/app/google-services.json` (2026-08-15 23:20:42 +0530) | **High** | Resolved `ApiException 10` by adding Web OAuth client ID and debug SHA-1 to Firebase. |
| **Dark Theme Preservation** | Source Code | `lib/app.dart` & `lib/core/theme/app_theme.dart` (2026-08-16 00:00:55 +0530) | **High** | Enforced `ThemeMode.dark` in `MaterialApp.router` and aliased `lightTheme` to `darkTheme`. |
| **Application ID Migration** | Build Log & Source | `android/app/build.gradle.kts` & CLI Task 8007 (2026-08-16 00:26:08 +0530) | **High** | Migrated package name from `com.example.cie_connect` to production `com.ciedaily.app`. |
| **Production Keystore Generation** | Build Log & Keystore | `android/app/upload-keystore.jks` & Task 8099 (2026-08-16 01:17:39 +0530) | **High** | Generated 2048-bit RSA release key and added release SHA-1 (`94:76:7F:90:14:...`) to Firebase. |
| **Release App Bundle (.aab)** | Build Artifact | `build/app/outputs/bundle/release/app-release.aab` (2026-08-16 01:24:02 +0530) | **High** | Compiled 81.9 MB production release-signed Android App Bundle. |
| **Version Code Increment (v10)** | Source & Build | `pubspec.yaml` (v1.0.9+10) & Task 8149 (2026-08-16 02:09:30 +0530) | **High** | Rebuilt release App Bundle with `versionCode: 10` for Google Play Console submission. |
| **Edit Profile Blank Screen Fix** | Source Code | `lib/features/profile/screens/profile_screen.dart` (2026-08-16 10:47:11 +0530) | **High** | Refactored `_showEditProfileSheet` to use `StatefulBuilder` and `ref.invalidate(userProfileProvider)`. |

---

## Technical Credentials & Fingerprints (Sanitized Record)

- **Package Name / Application ID**: `com.ciedaily.app`
- **Firebase Project ID**: `cie-connect`
- **Web OAuth Client ID**: `226102698550-fkcmj8it32dpfvqree9msc44vv57sfgj.apps.googleusercontent.com`
- **Debug Keystore SHA-1**: `84:BE:33:E9:1E:88:27:5E:3A:11:92:DC:06:B4:C0:9F:76:3F:F9:26`
- **Release Keystore SHA-1**: `94:76:7F:90:14:89:73:28:9F:F6:0A:D0:20:EE:9C:0E:8B:E6:A5:A9`
