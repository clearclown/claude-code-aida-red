# AIDA Design Protocol

Professional UI/UX requirements for all AIDA-generated projects.

Inspired by Linear, Notion, Stripe, Vercel design principles.

---

## PHILOSOPHY: Design is Not Optional

**"If it looks amateur, it IS amateur."**

Every AIDA project must look like it was built by a professional team, not a weekend hackathon. Users judge quality by appearance first.

The goal: **Intricate minimalism with appropriate personality.** Same quality bar, context-driven execution.

---

## STEP 0: CHOOSE A DESIGN DIRECTION (REQUIRED)

**Before writing ANY code, commit to a design direction.** Don't default. Think about what this specific product needs to feel like.

### Think About Context

- **What does this product do?** A finance tool needs different energy than a creative tool.
- **Who uses it?** Power users want density. Occasional users want guidance.
- **What's the emotional job?** Trust? Efficiency? Delight? Focus?
- **What would make this memorable?** Every product has a chance to feel distinctive.

### Design Personalities

| Direction | Aesthetic | Best For |
|-----------|-----------|----------|
| **Precision & Density** | Tight spacing, monochrome, information-forward | Developer tools, power user apps (Linear, Raycast) |
| **Warmth & Approachability** | Generous spacing, soft shadows, friendly colors | Collaborative tools, consumer SaaS (Notion, Coda) |
| **Sophistication & Trust** | Cool tones, layered depth, financial gravitas | Finance, enterprise B2B (Stripe, Mercury) |
| **Boldness & Clarity** | High contrast, dramatic negative space, confident typography | Modern dashboards (Vercel) |
| **Utility & Function** | Muted palette, functional density, clear hierarchy | Developer tools (GitHub) |
| **Data & Analysis** | Chart-optimized, technical but accessible, numbers-first | Analytics, BI tools |

**Pick one. Or blend two. But COMMIT.**

### Color Foundation

**Don't default to warm neutrals.** Consider the product:

| Foundation | Feeling | Example |
|------------|---------|---------|
| Warm (creams, warm grays) | Approachable, comfortable, human | Notion |
| Cool (slate, blue-gray) | Professional, trustworthy, serious | Stripe |
| Pure neutrals (true grays) | Minimal, bold, technical | Linear |
| Tinted (slight color cast) | Distinctive, memorable, branded | Custom |

**Accent color** — Pick ONE that means something:
- Blue = Trust
- Green = Growth/Success
- Orange = Energy/Warning
- Violet = Creativity
- Red = Destructive/Error

---

## CORE CRAFT PRINCIPLES

These apply regardless of design direction. This is the quality floor.

### The 4px Grid (MANDATORY)

All spacing uses a 4px base grid:

```
4px  - micro spacing (icon gaps)
8px  - tight spacing (within components)
12px - standard spacing (between related elements)
16px - comfortable spacing (section padding)
24px - generous spacing (between sections)
32px - major separation
48px - large section breaks
```

**In Tailwind:**
```
space-1 = 4px
space-2 = 8px
space-3 = 12px
space-4 = 16px
space-6 = 24px
space-8 = 32px
space-12 = 48px
```

### Symmetrical Padding (MANDATORY)

**TLBR must match.** If top padding is 16px, left/bottom/right must also be 16px.

```css
/* Good */
padding: 16px;
padding: 12px 16px; /* Only when horizontal needs more room */

/* Bad - FORBIDDEN */
padding: 24px 16px 12px 16px;
```

### Border Radius Consistency

Pick a system and commit:

| Style | Values | Feeling |
|-------|--------|---------|
| Sharp | 4px, 6px, 8px | Technical, precise |
| Soft | 8px, 12px | Friendly, approachable |
| Minimal | 2px, 4px, 6px | Utility-focused |

**Don't mix systems.**

### Depth & Elevation Strategy

**Choose ONE approach and commit:**

| Strategy | When to Use | CSS |
|----------|-------------|-----|
| **Borders-only** | Dense, technical tools | `border: 0.5px solid rgba(0,0,0,0.08)` |
| **Subtle single shadow** | Approachable products | `0 1px 3px rgba(0,0,0,0.08)` |
| **Layered shadows** | Premium, substantial feel | See below |
| **Surface color shifts** | Minimal, clean | Background tints only |

```css
/* Borders-only approach */
--border: rgba(0, 0, 0, 0.08);
border: 0.5px solid var(--border);

/* Single shadow approach */
--shadow: 0 1px 3px rgba(0, 0, 0, 0.08);

/* Layered shadow approach (Stripe-style) */
--shadow-layered:
  0 0 0 0.5px rgba(0, 0, 0, 0.05),
  0 1px 2px rgba(0, 0, 0, 0.04),
  0 2px 4px rgba(0, 0, 0, 0.03),
  0 4px 8px rgba(0, 0, 0, 0.02);
```

### Typography Hierarchy

```css
/* Headlines */
font-weight: 600;
letter-spacing: -0.02em;

/* Body */
font-weight: 400-500;
letter-spacing: normal;

/* Labels (uppercase) */
font-weight: 500;
letter-spacing: 0.05em;

/* Size scale */
11px - micro labels
12px - captions, metadata
13px - secondary text
14px - body (base)
16px - lead text
18px - h4
24px - h3
32px - h2
```

### Monospace for Data

Numbers, IDs, codes, timestamps belong in monospace:

```tsx
<span className="font-mono tabular-nums">$12,345.67</span>
<span className="font-mono text-muted-foreground">ID: abc-123</span>
<span className="font-mono text-xs">2024-01-15 14:30</span>
```

### Color for Meaning ONLY

**Gray builds structure. Color only appears when it communicates.**

| Use Color For | Example |
|--------------|---------|
| Status indicators | Green = success, Red = error |
| Actions | Blue buttons for primary actions |
| Alerts | Yellow for warnings |
| Links | Blue for clickable text |

**DON'T use color for:**
- Decorative gradients
- Random accent splashes
- Different colors for same-type elements

### Contrast Hierarchy

Build a four-level system:

```css
--foreground: 100% opacity (primary text)
--secondary: 70% opacity (secondary text)
--muted: 50% opacity (placeholder, hints)
--faint: 30% opacity (disabled, borders)
```

---

## MANDATORY DESIGN STANDARDS

### 1. Modern UI Framework

**REQUIRED: Tailwind CSS with shadcn/ui components**

```bash
# Frontend initialization MUST include:
npm install -D tailwindcss postcss autoprefixer
npm install @radix-ui/react-* lucide-react class-variance-authority clsx tailwind-merge
npx tailwindcss init -p
```

### 2. Color System

```js
// tailwind.config.js - Context-driven palette
module.exports = {
  theme: {
    extend: {
      colors: {
        // Choose foundation based on product personality
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        border: 'hsl(var(--border))',
        ring: 'hsl(var(--ring))',
      },
    },
  },
}
```

### 3. Typography

```css
/* Choose based on product personality */

/* Technical/Developer tools */
--font-sans: 'Geist', 'Inter', system-ui, sans-serif;
--font-mono: 'Geist Mono', 'JetBrains Mono', monospace;

/* Approachable/Consumer */
--font-sans: 'Inter', 'SF Pro', system-ui, sans-serif;

/* Enterprise/Professional */
--font-sans: 'Inter', '-apple-system', 'Segoe UI', sans-serif;
```

---

## COMPONENT REQUIREMENTS

### Layout Components (MANDATORY)

Every project MUST have these base components:

```
src/components/
├── ui/                    # shadcn/ui components
│   ├── button.tsx
│   ├── card.tsx
│   ├── input.tsx
│   ├── avatar.tsx
│   ├── dropdown-menu.tsx
│   ├── dialog.tsx
│   ├── toast.tsx
│   └── skeleton.tsx       # Loading states
├── layout/
│   ├── Header.tsx         # App header with navigation
│   ├── Sidebar.tsx        # Side navigation
│   ├── Footer.tsx         # Footer if needed
│   └── Layout.tsx         # Main layout wrapper
└── common/
    ├── LoadingSpinner.tsx
    ├── ErrorBoundary.tsx
    └── EmptyState.tsx
```

### Button Variants (REQUIRED)

```tsx
// Every project needs these button variants
<Button variant="default">Primary Action</Button>
<Button variant="secondary">Secondary</Button>
<Button variant="outline">Outline</Button>
<Button variant="ghost">Ghost</Button>
<Button variant="destructive">Delete</Button>
<Button variant="link">Link Style</Button>

// Sizes
<Button size="sm">Small</Button>
<Button size="default">Default</Button>
<Button size="lg">Large</Button>
<Button size="icon"><Icon /></Button>
```

### Form Components (REQUIRED)

```tsx
// Proper form styling with validation states
<Input className="..." error={errors.email} />
<Textarea className="..." maxLength={280} />
<Select options={...} />
<Checkbox />
<Switch />
```

---

## PAGE LAYOUT PATTERNS

### Twitter Clone Layout (Example)

```
┌─────────────────────────────────────────────────────────────┐
│ Header: Logo | Search | Profile Menu                        │
├──────────┬─────────────────────────────────┬───────────────┤
│          │                                 │               │
│ Sidebar  │     Main Content Area           │  Right Panel  │
│          │                                 │               │
│ • Home   │  ┌────────────────────────────┐ │  Trends       │
│ • Explore│  │ Compose Post               │ │  Who to follow│
│ • Notif  │  │ [Avatar] What's happening? │ │               │
│ • Messages│ │ [    Post Button          ]│ │               │
│ • Profile│  └────────────────────────────┘ │               │
│          │                                 │               │
│          │  ┌────────────────────────────┐ │               │
│          │  │ Post Card                  │ │               │
│          │  │ [Avatar] Username • 2h     │ │               │
│          │  │ Post content here...       │ │               │
│          │  │ ♡ 12  ↻ 3  💬 5  ⬆        │ │               │
│          │  └────────────────────────────┘ │               │
│          │                                 │               │
└──────────┴─────────────────────────────────┴───────────────┘
```

### Required Layout Features

1. **Responsive Design** - Mobile-first approach
2. **Sticky Header** - Always visible navigation
3. **Sidebar Navigation** - Collapsible on mobile
4. **Content Area** - Proper max-width and padding
5. **Right Panel** - Secondary content (optional on mobile)

---

## TWITTER CLONE SPECIFIC REQUIREMENTS

### Post Card Component

```tsx
// MINIMUM requirements for a post card
interface PostCardProps {
  post: {
    id: string;
    content: string;
    author: {
      id: string;
      username: string;
      displayName: string;
      avatarUrl: string;
    };
    createdAt: Date;
    likeCount: number;
    repostCount: number;
    replyCount: number;
    isLiked: boolean;
    isReposted: boolean;
  };
}

// Visual requirements:
// - Avatar with proper sizing (40-48px)
// - Display name (bold) and @username (muted)
// - Relative timestamp ("2h", "Mar 15")
// - Action buttons with hover states
// - Like animation when clicked
// - Proper spacing and alignment
```

### Compose Post Component

```tsx
// Requirements:
// - Avatar next to textarea
// - Auto-expanding textarea
// - Character counter (changes color near limit)
// - Disabled button until content exists
// - Media upload button (even if not functional)
// - Emoji picker button (even if not functional)
```

### Profile Page

```tsx
// Requirements:
// - Cover photo area (even if placeholder)
// - Large avatar overlapping cover
// - Display name and @username
// - Bio section
// - Stats (followers, following, posts)
// - Tab navigation (Posts, Replies, Likes)
// - Follow/Unfollow button with proper states
```

---

## LOADING STATES (MANDATORY)

### Skeleton Loading

Every data-fetching component MUST show skeleton loading:

```tsx
// Post skeleton
<div className="animate-pulse">
  <div className="flex gap-3">
    <div className="w-12 h-12 bg-muted rounded-full" />
    <div className="flex-1 space-y-2">
      <div className="h-4 bg-muted rounded w-1/4" />
      <div className="h-4 bg-muted rounded w-3/4" />
      <div className="h-4 bg-muted rounded w-1/2" />
    </div>
  </div>
</div>
```

### Loading Spinner

```tsx
// For actions and page transitions
<Spinner className="animate-spin h-5 w-5" />
```

### Button Loading States

```tsx
<Button disabled={isLoading}>
  {isLoading ? <Spinner /> : null}
  {isLoading ? "Posting..." : "Post"}
</Button>
```

---

## EMPTY STATES (MANDATORY)

Every list view MUST have a designed empty state:

```tsx
// NOT acceptable:
<p>No posts yet</p>

// REQUIRED:
<div className="flex flex-col items-center justify-center py-16 text-center">
  <div className="w-24 h-24 mb-4 rounded-full bg-muted flex items-center justify-center">
    <FeatherIcon className="w-12 h-12 text-muted-foreground" />
  </div>
  <h3 className="text-xl font-semibold mb-2">No posts yet</h3>
  <p className="text-muted-foreground mb-4 max-w-sm">
    When you or people you follow post, it'll show up here.
  </p>
  <Button>Create your first post</Button>
</div>
```

---

## ERROR STATES (MANDATORY)

```tsx
// NOT acceptable:
<p>Error loading posts</p>

// REQUIRED:
<div className="flex flex-col items-center justify-center py-16 text-center">
  <AlertCircle className="w-12 h-12 text-destructive mb-4" />
  <h3 className="text-xl font-semibold mb-2">Something went wrong</h3>
  <p className="text-muted-foreground mb-4">
    We couldn't load the posts. Please try again.
  </p>
  <Button variant="outline" onClick={retry}>
    <RefreshCw className="w-4 h-4 mr-2" />
    Try again
  </Button>
</div>
```

---

## ANIMATIONS & TRANSITIONS

### Required Transitions

```css
/* All interactive elements MUST have transitions */
.button, .link, .card {
  transition: all 150ms ease;
}

/* Hover states */
.card:hover {
  background-color: var(--muted);
}

/* Focus states for accessibility */
.button:focus-visible {
  outline: 2px solid var(--ring);
  outline-offset: 2px;
}
```

### Like Animation

```tsx
// Heart animation on like
const [isAnimating, setIsAnimating] = useState(false);

const handleLike = () => {
  setIsAnimating(true);
  setTimeout(() => setIsAnimating(false), 300);
  // ... like logic
};

<Heart
  className={cn(
    "w-5 h-5 transition-transform",
    isLiked && "fill-red-500 text-red-500",
    isAnimating && "scale-125"
  )}
/>
```

---

## RESPONSIVE BREAKPOINTS

```js
// tailwind.config.js
screens: {
  'sm': '640px',   // Mobile landscape
  'md': '768px',   // Tablet
  'lg': '1024px',  // Desktop
  'xl': '1280px',  // Large desktop
  '2xl': '1536px', // Extra large
}
```

### Mobile-First Layout

```tsx
// Sidebar: hidden on mobile, visible on lg+
<aside className="hidden lg:flex lg:w-64 ...">

// Right panel: hidden on mobile and tablet
<aside className="hidden xl:flex xl:w-80 ...">

// Main content: full width on mobile, constrained on desktop
<main className="flex-1 w-full max-w-2xl mx-auto px-4 lg:px-0">
```

---

## ICON LIBRARY

**REQUIRED: Lucide React**

```bash
npm install lucide-react
```

```tsx
// Standard icons
import {
  Home, Search, Bell, Mail, User,
  Heart, MessageCircle, Repeat2, Share,
  MoreHorizontal, Settings, LogOut,
  Camera, Image, Smile, MapPin
} from 'lucide-react';
```

---

## ACCESSIBILITY REQUIREMENTS

### ARIA Labels

```tsx
// All interactive elements MUST have accessible names
<button aria-label="Like this post">
  <Heart />
</button>

<button aria-label="More options">
  <MoreHorizontal />
</button>
```

### Keyboard Navigation

```tsx
// Focus must be visible and logical
<Button onKeyDown={(e) => e.key === 'Enter' && handleAction()}>
```

### Color Contrast

- Text on background: minimum 4.5:1 ratio
- Large text: minimum 3:1 ratio
- Interactive elements: clear focus states

---

## QUALITY CHECKLIST

Before implementation is complete, verify:

### Visual Quality
- [ ] Consistent spacing (4px/8px grid)
- [ ] Proper typography hierarchy
- [ ] Color consistency throughout
- [ ] Icons are properly sized
- [ ] Images have proper aspect ratios
- [ ] Avatar placeholders for missing images

### Interactive Quality
- [ ] All buttons have hover states
- [ ] All buttons have loading states
- [ ] All forms show validation errors
- [ ] All links have hover/focus states
- [ ] Transitions are smooth (150-300ms)

### State Quality
- [ ] Loading skeletons for all data
- [ ] Empty states for all lists
- [ ] Error states with retry options
- [ ] Success feedback (toasts)

### Responsive Quality
- [ ] Mobile layout works (320px+)
- [ ] Tablet layout works (768px+)
- [ ] Desktop layout works (1024px+)
- [ ] No horizontal scroll on any viewport

---

## FORBIDDEN PATTERNS (NEVER DO THIS)

### Visual Anti-Patterns

| Pattern | Why It's Bad |
|---------|--------------|
| Dramatic drop shadows (`box-shadow: 0 25px 50px...`) | Looks dated, unprofessional |
| Large border radius (16px+) on small elements | Bubbly, childish appearance |
| Asymmetric padding without clear reason | Sloppy, unintentional |
| Pure white cards on colored backgrounds | Harsh, no subtlety |
| Thick borders (2px+) for decoration | Heavy, amateur |
| Excessive spacing (margins > 48px) | Wasteful, disconnected |
| Spring/bouncy animations | Playful ≠ professional |
| Gradients for decoration | 2010s web design |
| Multiple accent colors in one interface | Chaotic, no hierarchy |

### Code Anti-Patterns

```tsx
// FORBIDDEN: Raw HTML without styling
<button>Click me</button>

// FORBIDDEN: Inline styles
<div style={{marginTop: '10px'}}>

// FORBIDDEN: Magic numbers (not on 4px grid)
<div className="mt-[13px]">

// FORBIDDEN: Native form elements (can't be styled)
<select><option>...</option></select>
<input type="date" />

// FORBIDDEN: Text-only empty states
<p>No data</p>

// FORBIDDEN: Alert-based errors
alert('Something went wrong');

// FORBIDDEN: Console-only errors
console.error('Failed to load');

// FORBIDDEN: Mixed depth strategies
<Card className="shadow-sm" />  // some cards with shadow
<Card className="border" />     // some cards with border only
```

### Required Replacements

```tsx
// REQUIRED: Styled components
<Button variant="primary">Click me</Button>

// REQUIRED: Tailwind utilities on 4px grid
<div className="mt-4">  {/* 16px, on grid */}

// REQUIRED: Custom select with styled dropdown
<Select>
  <SelectTrigger className="inline-flex whitespace-nowrap">
    <SelectValue placeholder="Select..." />
  </SelectTrigger>
  <SelectContent>...</SelectContent>
</Select>

// REQUIRED: Designed empty states
<EmptyState
  icon={<Inbox className="w-12 h-12 text-muted-foreground" />}
  title="No posts yet"
  description="When you follow people, their posts will show up here."
  action={<Button>Find people to follow</Button>}
/>

// REQUIRED: Toast notifications
toast.error('Something went wrong. Please try again.');

// REQUIRED: Consistent depth strategy
// Pick ONE and use everywhere:
<Card className="border border-border/50" />  // borders-only
// OR
<Card className="shadow-sm" />                // single shadow
```

### Self-Check Questions

Before completing any UI work, ask:

1. "Did I think about what this product needs, or did I default?"
2. "Does this direction fit the context and users?"
3. "Does this element feel crafted?"
4. "Is my depth strategy consistent and intentional?"
5. "Are all elements on the 4px grid?"
6. "Is color earning its place, or just decorating?"

---

## COMPONENT LIBRARY SETUP

### shadcn/ui Installation

```bash
# Initialize shadcn/ui
npx shadcn-ui@latest init

# Install required components
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
npx shadcn-ui@latest add input
npx shadcn-ui@latest add textarea
npx shadcn-ui@latest add avatar
npx shadcn-ui@latest add dropdown-menu
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add toast
npx shadcn-ui@latest add skeleton
npx shadcn-ui@latest add tabs
npx shadcn-ui@latest add tooltip
```

### Required Configuration

```ts
// components.json
{
  "style": "default",
  "rsc": false,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/index.css",
    "baseColor": "slate",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils"
  }
}
```

---

## DESIGN TOKENS

### Spacing Scale

```
space-0: 0
space-1: 0.25rem (4px)
space-2: 0.5rem (8px)
space-3: 0.75rem (12px)
space-4: 1rem (16px)
space-5: 1.25rem (20px)
space-6: 1.5rem (24px)
space-8: 2rem (32px)
space-10: 2.5rem (40px)
space-12: 3rem (48px)
space-16: 4rem (64px)
```

### Border Radius

```
rounded-none: 0
rounded-sm: 0.125rem (2px)
rounded: 0.25rem (4px)
rounded-md: 0.375rem (6px)
rounded-lg: 0.5rem (8px)
rounded-xl: 0.75rem (12px)
rounded-2xl: 1rem (16px)
rounded-full: 9999px
```

### Shadow Scale

```
shadow-sm: 0 1px 2px rgba(0,0,0,0.05)
shadow: 0 1px 3px rgba(0,0,0,0.1)
shadow-md: 0 4px 6px rgba(0,0,0,0.1)
shadow-lg: 0 10px 15px rgba(0,0,0,0.1)
shadow-xl: 0 20px 25px rgba(0,0,0,0.1)
```

---

## VERIFICATION COMMANDS

```bash
# Check for required components
ls src/components/ui/ | wc -l  # Should be 10+

# Check for layout components
ls src/components/layout/ | wc -l  # Should be 3+

# Check for Tailwind config
grep -c "colors:" tailwind.config.js  # Should be 1+

# Check for shadcn/ui setup
test -f components.json && echo "shadcn configured"

# Check for Lucide icons
grep -r "from 'lucide-react'" src/ | wc -l  # Should be 5+
```

---

## COMPLETION CRITERIA

Design is ONLY complete when:

- [ ] shadcn/ui components installed (10+ components)
- [ ] Layout components exist (Header, Sidebar, Layout)
- [ ] Tailwind configured with custom colors
- [ ] All pages have proper layouts (not just centered divs)
- [ ] All lists have skeleton loading states
- [ ] All empty states are designed (not just text)
- [ ] All error states are designed (not alerts)
- [ ] Mobile responsive (tested at 320px, 768px, 1024px)
- [ ] Icons from Lucide (not emoji or text)
- [ ] Transitions on all interactive elements

**NO EXCUSES. NO BASIC HTML. PROFESSIONAL ONLY.**
