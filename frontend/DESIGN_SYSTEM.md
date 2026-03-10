# CLAiR Design System

## Color Palette

The CLAiR app uses a sophisticated, warm color palette that creates an inviting and professional learning environment:

```dart
Primary Colors:
- Dark Brown (#270708)  - Deep, rich primary text and backgrounds
- Crimson (#660810)     - Accent color for CTAs and highlights
- Tan (#D6C0B1)         - Subtle accents and secondary elements
- Off White (#F1EBEB)   - Main background color
```

## Typography

**Font Family:** Satoshi Variable
- Location: `assets/fonts/Satoshi-Variable.ttf`
- Usage: All text throughout the app

**Font Weights:**
- Light (300) - Greeting text
- Regular (400) - Body text, descriptions
- Semi-Bold (600) - Buttons, labels, card titles
- Bold (700) - Main headings

## Components

### Login Screen
- Clean, centered layout with ample whitespace
- Large app icon with shadow (120x120)
- Greeting text with hierarchy (Hello → Welcome Back!)
- Feature cards showcasing app capabilities
- Prominent Google Sign-In button

### Google Sign-In Button
- Height: 64px
- Background: Crimson (#660810)
- Border radius: 20px
- Shadow: Soft crimson glow
- Icon: Google 'G' in white badge

### Home Screen
- Personalized greeting header
- User avatar (56x56) with shadow
- Grid of lesson cards (2 columns)
- Progress indicators on each card
- Sign-out button at bottom

### Lesson Cards
- White background with colored shadows
- Circular icon container (60x60)
- Progress percentage
- Linear progress bar
- Border radius: 24px

## Spacing

- Screen padding: 24px
- Card spacing: 16px
- Element spacing: 8-40px (contextual)
- Border radius (large): 20-24px
- Border radius (medium): 16px
- Border radius (small): 10-12px

## Shadows

All shadows use the primary colors with low opacity (0.1-0.3) for a cohesive look:

```dart
BoxShadow(
  color: AppColors.crimson.withOpacity(0.3),
  blurRadius: 20,
  offset: Offset(0, 10),
)
```

## Assets

- App Icon: `assets/images/CLAiR-icon.png`
- Font: `assets/fonts/Satoshi-Variable.ttf`

## Clean Architecture Structure

```
lib/
├── core/
│   └── theme/
│       ├── app_colors.dart    # Color constants
│       └── app_theme.dart     # Theme configuration
├── features/
│   └── auth/
│       └── presentation/
│           ├── screens/
│           │   └── login_screen.dart
│           └── widgets/
│               └── google_sign_in_button.dart
```

## Usage Example

```dart
// Using colors
Container(
  color: AppColors.crimson,
  child: Text(
    'Hello',
    style: TextStyle(
      color: AppColors.offWhite,
      fontFamily: 'Satoshi',
      fontWeight: FontWeight.w600,
    ),
  ),
)

// Using theme
MaterialApp(
  theme: AppTheme.lightTheme,
  ...
)
```
