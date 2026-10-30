# Spendly — Settings design

Import `manifest.json` through **Figma → Plugins → Development → Import plugin from manifest**, then run **Spendly · Editable Settings**. Inter must be available in Figma.

Creates native editable layers rather than flattened screenshots:

- Three 393 × 852 frames: Light, Dark, and System Default selection states.
- Auto Layout sections and cards, named vector icons, theme preview, reusable setting-row/button components, and On/Off switch variants.
- Clickable theme navigation, interactive switch variants, preference selection frames, security detail screens, and separate destructive confirmation flows with Cancel and confirm actions.
- Bottom navigation: Home, Settings, Budgets, Categories, Profile. Settings is active. The complete screen scrolls vertically.

The main screen's accent swatches are editable visual choices. The native prototype does not execute settings, exports, backups, authentication, or data deletion. Preference option flows demonstrate selection screens and return to the default Settings screen; Flutter implements the actual session selection state.

Flutter source: `lib/screens/settings_screen.dart`. Theme/accent and switches work in the local app. Currency/language/day/date choices are session preferences; currency conversion, translated copy, notification scheduling, authentication, and production account services are not connected. CSV export copies actual current expenses. Backup and restore use a session-only snapshot. Clear App Data removes the in-memory transaction list after confirmation.

Typography: Inter. Primary `#14213D`; accent `#10B981`; background `#FFFFFF`; secondary background `#F5F7FA`; destructive `#EF4444`. Cards: 16 px corners; screen margin: 20 px; section gap: 24 px; rows: at least 56 px. Outline icons use 1.7 px strokes.

The generator is JavaScript syntax checked but has not been run inside Figma. No cloud Figma file has been created. To review the implemented UI, see `test/goldens/settings_screen.png` and `test/goldens/settings_dark.png`.
