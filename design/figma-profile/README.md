# Spendly Profile — editable Figma source

Import `manifest.json` using **Figma → Plugins → Development → Import plugin from manifest**, then run **Spendly · Editable Profile** in a design file. Inter must be available in Figma.

The generator creates a **393 × 852** frame, scrollable content, fixed header and bottom navigation, native editable text and vector icons, a replaceable portrait image, Auto Layout frames, and reusable menu/button/statistic components. The full Account section is available by scrolling the prototype or selecting layers. No network access is used.

The Flutter implementation is `lib/screens/profile_screen.dart`. Financial figures are sample values. Profile edits and notification preferences are session-only; authentication and bank connections are not implemented.

Palette: Navy `#14213D`, Emerald `#10B981`, White `#FFFFFF`, Light Gray `#F5F7FA`. Cards use 16 px corners. Horizontal page padding is 20 px; section spacing is 24 px. Icons use editable 1.7 px outline vectors.

Portrait: [Unsplash sample photo](https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=256&h=256&fit=crop&crop=faces), bundled locally. Inter: Google Fonts, SIL Open Font License (see `assets/fonts/OFL.txt`).

This package has not been executed inside Figma; importing it creates the design in your chosen file. It does not represent an existing cloud Figma document.
