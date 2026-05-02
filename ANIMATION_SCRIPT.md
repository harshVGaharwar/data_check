# Template Configuration — Onboarding Animation Script

**App:** Data Fusion — HDFC Internal Tool
**Animation Type:** Guided UI Walkthrough (Lottie / CSS / After Effects)
**Duration:** ~45 seconds total
**Tone:** Clean, professional, minimal

---

## COLOR REFERENCE
| Name    | Hex       | Use                        |
|---------|-----------|----------------------------|
| Blue    | #2563EB   | Primary actions, highlights |
| Green   | #059669   | Confirmed / Success         |
| Amber   | #D97706   | In-progress / Editing       |
| Violet  | #7C3AED   | Join node                   |
| Gray BG | #F1F5F9   | Canvas background           |
| White   | #FFFFFF   | Cards / Panels              |

---

## SCENE 1 — INTRO
**Duration:** 3 seconds

**Visual:**
- Blank canvas screen fade in
- Left sidebar visible, right side empty canvas (dotted grid)
- App logo + "Data Fusion" text visible at top

**Text Overlay (center, large):**
> "Pipeline Configuration"
> *"Connect your data sources in 5 easy steps"*

**Animation:**
- Screen fades in from white
- Text slides up gently

---

## SCENE 2 — SELECT DEPARTMENT & TEMPLATE
**Duration:** 6 seconds

**Visual:**
- Spotlight / soft glow appears on LEFT SIDEBAR
- Sidebar top section highlighted with blue glow ring

**Step 2a (0–2s):**
- Cursor moves to Department dropdown
- Dropdown opens → "Finance" option highlights → click
- Sidebar shows green checkmark on Department row

**Step 2b (2–4s):**
- Template dropdown unlocks (subtle bounce animation)
- Cursor clicks "P&L Report"
- Badge appears: **"2 Sources Required"** (blue pill badge)
- Sidebar me source counter show hota hai: **"0 / 2"** (gray, unfilled)

**Step 2c (4–6s):**
- Source type palette slides in from below in sidebar
- Three cards appear: **Manual**, **QRS**, **FC**
- Cards glow with subtle blue pulse
- Counter badge **"0 / 2"** pulse karta hai — user ko indicate karta hai ki sources add karne hain

**Text Overlay (bottom bar):**
> "Step 1 — Choose your department and template"

---

## SCENE 3 — ADD SOURCE NODES
**Duration:** 10 seconds

**Visual:**
- Focus shifts to canvas area
- Sidebar source cards still visible on left

**Step 3a (0–4s) — First Source:**
- "Manual" card lifts from sidebar (scale up slightly)
- Drag animation — card floats across to canvas left side
- Card drops → transforms into a **Source Node** (white card, gray border)
- Node content fades in: name field, upload icon
- Right panel (ConfigPanel) slides in from right
- Fields fill automatically one by one:
  - Source name: "S1" types itself
  - File upload icon pulses → file selected
  - Columns appear as chips: `DeptID`, `DeptName`, `Budget`
  - All chips highlight (selected)
- ✅ Confirm button pulses green → click
- Node border turns **GREEN**, checkmark badge appears
- ⭐ Sidebar counter animates: **"0 / 2"** → **"1 / 2"** (half-fill, amber color)
- Counter badge bounce hota hai — progress feel deta hai

**Step 3b (4–8s) — Second Source:**
- Same animation repeats for "QRS" source node
- Second node appears below first
- Confirms → turns green
- ⭐ Sidebar counter animates: **"1 / 2"** → **"2 / 2"** (full-fill, GREEN color)
- Counter badge ek baar bada hota hai (scale pop) — completion signal

**Step 3c (8–10s):**
- Counter **"2 / 2"** green glow karta hai
- JOIN section sidebar me UNLOCK hoti hai — lock icon hata, card brighten hota hai
- JOIN card blue pulse shuru karta hai
- Small arrow ya bounce animation pointing to JOIN in sidebar

**Text Overlay:**
> "Step 2 — Add sources. Counter tracks your progress."

---

## SCENE 4 — ADD JOIN NODE
**Duration:** 5 seconds

**Visual:**

**Step 4a (0–2s):**
- JOIN node card lifts from sidebar
- Drags to center-right of canvas
- Drops → transforms into violet JOIN node card
- Header: chain-link icon + "Join Operation" text

**Step 4b (2–5s):**
- Two animated arrows/lines pulse from source nodes toward join node
- Text hint appears near ports:
  > *"Connect sources to join node"*
- Port dots (●) on source nodes start glowing amber

**Text Overlay:**
> "Step 3 — Add a Join node to the canvas"

---

## SCENE 5 — CONNECT NODES (PORT DRAG)
**Duration:** 8 seconds

**Visual:**

**Step 5a (0–3s) — First connection:**
- Cursor moves to right port (●) of Source Node 1
- Port glows **amber** on hover → click
- Animated dashed line follows cursor
- Cursor moves to left port (●) of JOIN node
- Port glows **green** → click
- Solid bezier curve draws itself between nodes (blue line)
- Small ✅ flash at connection point

**Step 5b (3–6s) — Second connection:**
- Same animation for Source Node 2 → JOIN node
- Second bezier curve draws in

**Step 5c (6–8s):**
- JOIN node header updates: **"2 sources"** badge appears
- JOIN node body shows mapping form sliding down

**Text Overlay:**
> "Step 4 — Connect each source to the Join node"

---

## SCENE 6 — JOIN MAPPING
**Duration:** 10 seconds

**Visual:**
- JOIN node zoom in (focus karo — baaki canvas blur ho)
- Node ka exact UI dikhao:

---

**JOIN NODE — EXACT UI LAYOUT**

```
┌─────────────────────────────────────────────┐
│ 🔗  Join Operation            2 sources  🗑️ │  ← violet header
├─────────────────────────────────────────────┤
│ CONNECTED SOURCES                           │
│  [📄 S1]  [🔷 S2]                           │  ← colored badges
│                                             │
│ ┌ ─ ─ ─ JOIN CONDITION ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐ │
│                                             │
│  JOIN TYPE  [ 🔵 Left Join         ▼ ]      │
│                                             │
│  ┌──────────────┐  ┌─────┐  ┌────────────┐ │
│  │ LEFT TABLE   │  │ ON  │  │ RIGHT TABLE│ │
│  │  (purple)    │  │  =  │  │  (blue)    │ │
│  │              │  │amber│  │            │ │
│  │ [S1      ▼]  │  └─────┘  │ [S2     ▼] │ │
│  │ JOIN KEY     │           │ MATCH KEY  │ │
│  │ [DeptID  ▼]  │           │ [DeptID ▼] │ │
│  └──────────────┘           └────────────┘ │
│                                             │
│  [  +  Add Mapping  ]   ← violet outline   │
└─────────────────────────────────────────────┘
```

---

**Step 6a (0–2s) — Sources connected hote hain:**
- JOIN node header me **"2 sources"** badge appear hota hai
- "CONNECTED SOURCES" section me **[S1]** aur **[S2]** ke colored chips slide in hote hain
  - S1 chip: purple/violet color (Manual source ka color)
  - S2 chip: blue color (QRS source ka color)
- Neeche "JOIN CONDITION" form slide down hota hai

**Step 6b (2–5s) — Join Type select karo:**
- **"JOIN TYPE"** label glow karta hai
- Dropdown khulta hai → **"Left Join"** option highlight hota hai → click
- Dropdown me Venn diagram icon dikhta hai (left circle filled = LEFT JOIN)
- Selected value show hoti hai: **🔵 Left Join**

**Step 6c (5–8s) — Left & Right table set karo:**
- **LEFT TABLE card** (purple tint) highlight hota hai:
  - Source dropdown: **"S1"** select hota hai
  - **"JOIN KEY"** label → column dropdown: **"DeptID"** select hota hai
- **Center amber badge** glow karta hai: **ON / =**
- **RIGHT TABLE card** (blue tint) highlight hota hai:
  - Source dropdown: **"S2"** select hota hai
  - **"MATCH KEY"** label → column dropdown: **"DeptID"** select hota hai

**Step 6d (8–10s) — Mapping add karo:**
- **"+ Add Mapping"** button (violet outline) pulse karta hai → click
- Naya mapping row slide in hota hai:
```
  ┌────────────────────────────────────────────────┐
  │  S1          🔵          S2              [×]   │
  │  DeptID   LEFT JOIN   DeptID                   │
  └────────────────────────────────────────────────┘
```
  - Left side: violet text — source name + column
  - Center: Venn diagram icon + **"left_join"** badge
  - Right side: blue text — source name + column
  - Row bounce animation se appear hota hai

- **"COLUMN MAPPINGS (1)"** label appear hota hai upar
- Neeche **"➤ Submit Mapping"** green gradient button glow karna shuru karta hai

**Text Overlay:**
> "Step 5 — Set LEFT TABLE, RIGHT TABLE aur JOIN KEY"

---

## SCENE 7 — SUBMIT & SUCCESS
**Duration:** 6 seconds

**Visual:**

**Step 7a (0–2s):**
- Click "Submit Mapping"
- Preview dialog slides up from bottom (full screen overlay)
- Summary shown:
  - Sources: S1, S2
  - Join condition: DeptID = DeptID
  - Output columns listed

**Step 7b (2–4s):**
- "Confirm & Submit" button glows
- Click → loading spinner appears (1s)

**Step 7c (4–6s):**
- Success dialog appears:
  - Large green checkmark animates in (circle draw effect)
  - Text: **"Pipeline Saved!"**
  - Template ID badge shows

**Text Overlay:**
> "Done! Your pipeline configuration is saved."

---

## SCENE 8 — OUTRO
**Duration:** 3 seconds

**Visual:**
- Zoom out to full canvas view
- All nodes visible: [S1] → [JOIN] ← [S2]
- All nodes have green borders
- Soft glow/pulse on the completed pipeline

**Final Text Overlay (center):**
> **"5 Steps. Your pipeline is ready."**
>
> *Department → Template → Sources → Connect → Submit*

- App logo fades in bottom right
- Screen fades to white

---

## ANIMATION NOTES

| Scene | Duration | Key Animation                        | Sound Cue        |
|-------|----------|--------------------------------------|------------------|
| 1     | 3s       | Fade in                              | Soft chime       |
| 2     | 6s       | Dropdown + badge pop + counter 0/2   | Click x2         |
| 3     | 10s      | Drag + confirm x2 + counter 1/2→2/2  | Confirm ding x2  |
| 4     | 5s       | Drag + port glow                     | Soft whoosh      |
| 5     | 8s       | Bezier line draw x2                  | Connection click |
| 6     | 10s      | Source badges → join type → left/right table → add mapping row | Click x4 |
| 7     | 6s       | Preview dialog + success             | Success chime    |
| 8     | 3s       | Zoom out + outro                     | Fade music       |
| **Total** | **~51s** |                                  |                  |

---

## PROGRESS INDICATOR (shown throughout)

Bottom of screen — always visible:

```
① Dept & Template  →  ② Add Sources  →  ③ Add Join  →  ④ Connect  →  ⑤ Submit
```

Each step fills with blue as user progresses.
