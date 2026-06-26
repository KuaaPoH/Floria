---
name: Premium Glassmorphism Desktop
colors:
  surface: '#f8f9fa'
  surface-dim: '#d9dadb'
  surface-bright: '#f8f9fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f5'
  surface-container: '#edeeef'
  surface-container-high: '#e7e8e9'
  surface-container-highest: '#e1e3e4'
  on-surface: '#191c1d'
  on-surface-variant: '#3b4a3d'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f2'
  outline: '#6b7b6c'
  outline-variant: '#bacbb9'
  surface-tint: '#006d35'
  primary: '#006d35'
  on-primary: '#ffffff'
  primary-container: '#00e676'
  on-primary-container: '#00612e'
  inverse-primary: '#00e475'
  secondary: '#006e2a'
  on-secondary: '#ffffff'
  secondary-container: '#5cfd80'
  on-secondary-container: '#00732c'
  tertiary: '#86521b'
  on-tertiary: '#ffffff'
  tertiary-container: '#ffba79'
  on-tertiary-container: '#794810'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#62ff96'
  primary-fixed-dim: '#00e475'
  on-primary-fixed: '#00210b'
  on-primary-fixed-variant: '#005226'
  secondary-fixed: '#69ff87'
  secondary-fixed-dim: '#3ce36a'
  on-secondary-fixed: '#002108'
  on-secondary-fixed-variant: '#00531e'
  tertiary-fixed: '#ffdcbf'
  tertiary-fixed-dim: '#fdb878'
  on-tertiary-fixed: '#2d1600'
  on-tertiary-fixed-variant: '#6a3c03'
  background: '#f8f9fa'
  on-background: '#191c1d'
  surface-variant: '#e1e3e4'
typography:
  display-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 72px
    fontWeight: '800'
    lineHeight: 84px
    letterSpacing: -0.02em
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 60px
    fontWeight: '800'
    lineHeight: 72px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  columns: '12'
  max-width: 1440px
  gutter: 24px
  margin: 80px
  base-unit: 8px
---

## Brand & Style

This design system is a sophisticated evolution from mobile to desktop, emphasizing a **Premium Glassmorphism** aesthetic. It targets a modern, tech-savvy audience that values clarity, openness, and high-end visual polish. The UI evokes an emotional response of freshness and precision, achieved through a "Pure White" environment punctuated by vibrant accents.

The style combines high-fidelity glass effects with a minimalist spatial logic. By utilizing translucent layers, subtle backdrop blurs, and generous negative space, the design system creates a sense of depth that feels airy rather than heavy. This is a "Light Mode" first experience, prioritizing legibility and a sense of "clean tech" luxury.

## Colors

The palette is centered around a singular, high-energy primary color: **#00e676**. This vibrant green represents growth and vitality, serving as the primary driver for actions and highlights.

- **Primary:** #00e676 (Spring Green) used for key CTAs, active states, and brand accents.
- **Surface:** The background is a crisp, Pure White (#FFFFFF).
- **Glass Layers:** Surfaces utilize a semi-transparent white (70-80% opacity) with a `backdrop-filter: blur(20px)` to create the signature glass effect.
- **Accents:** Neutral grays are kept cool and minimal to ensure the green remains the focal point.

## Typography

This design system leverages **Plus Jakarta Sans** for its contemporary, geometric feel that balances professional structure with friendly curves. For the desktop transition, headline scales have been significantly increased to command attention and organize complex information hierarchies.

- **Display & Headlines:** Use extra-bold weights and tighter letter spacing for a high-impact, editorial look.
- **Body Text:** Maintained at 16px to 18px for optimal readability on desktop monitors, utilizing a regular weight to contrast with the bold headers.
- **Hierarchy:** Use the Display XL and LG roles exclusively for hero sections and major landing moments.

## Layout & Spacing

The layout transitions from a vertical mobile stack to a robust **12-column fluid grid** for desktop.

- **Grid System:** A 12-column layout with 24px gutters ensures structural alignment. On large monitors, content is capped at a max-width of 1440px, centered on the screen.
- **Rhythm:** An 8px base unit governs all padding and margin decisions. 
- **Desktop Strategy:** Utilize the horizontal real estate to move from stacked cards to side-by-side layouts. Sidebars should be treated as fixed or semi-collapsible glass panels (column span: 2-3).
- **Margins:** Generous outer margins (80px+) are used to emphasize the premium, airy feel and prevent the UI from feeling "cramped."

## Elevation & Depth

Depth in this design system is achieved through **Optical Layering** rather than traditional heavy shadows.

- **The Glass Effect:** All primary containers use a white semi-transparent fill with a background blur. To define the edges, use a 1px solid white border with 40% opacity (inner glow effect).
- **Shadows:** Use extremely soft, high-diffusion shadows. For example: `0 8px 32px rgba(0, 0, 0, 0.04)`. The shadows should feel like an ambient glow rather than a dark drop-shadow.
- **Interaction Depth:** Upon hover, the backdrop blur intensity can increase, and the shadow can slightly expand to simulate the element "floating" closer to the user.

## Shapes

The shape language is defined by extreme roundness, conveying a soft and approachable premium feel. 

- **Primary Radius:** Large components like cards and containers use a "3XL" radius (approx 32px or 2rem).
- **Interactive Elements:** Buttons and tags use a "Pill" shape (rounded-full) to maximize the friendly, modern aesthetic.
- **Consistency:** Avoid sharp corners entirely. Even input fields and progress bars must adhere to the high-roundedness standard to maintain visual harmony.

## Components

### Buttons
Primary buttons are pill-shaped, using the #00e676 background with white text. They should have a subtle green outer glow on hover. Secondary buttons should use the Glassmorphism style: transparent background, 1px white border, and blurred backdrop.

### Cards
Cards are the cornerstone of the desktop layout. They feature the 3XL rounded corners, the semi-transparent glass fill, and the 1px soft white border. Content inside cards should have generous padding (at least 32px).

### Input Fields
Inputs are pill-shaped with a subtle 1px border. When focused, the border color transitions to #00e676 with a soft outer glow.

### Navigation
The top navigation bar should be a persistent glass element that spans the full width of the viewport, using a high backdrop-blur value to ensure legibility of the menu items as the user scrolls content underneath.

### Chips & Tags
Small, pill-shaped indicators with a slightly more opaque white background or a very pale tint of the primary green (#00e676 at 10% opacity) for categorizing information without clutter.