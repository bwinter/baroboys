# ✅ Baroboys Admin Panel – Style Guide (Cyborg Theme, Finalized)

This guide reflects the **final visual system for the admin panel**, built on Bootswatch **Cyborg**, using native
Bootstrap classes with minimal, focused overrides.

> 🧠 **Note:** This guide is meant to support the visual direction already in place — not to enforce new rules or
> override working styles. If the existing admin dashboard uses a class or color, **assume it's intentional** unless
> documented otherwise.

---

## 🎨 Theme Foundation

| Element         | Class / Style                             | Notes                                                    |
|-----------------|-------------------------------------------|----------------------------------------------------------|
| Page background | `html, body { background-color: #000; }`  | Pure black canvas — no gray bleed from the theme         |
| Cards           | `.card` with `background-color: #111`     | Deep gray — subtle lift from the background              |
| Header text     | `.text-dark`                              | Primary text color (highest readability on Cyborg cards) |
| Muted text      | `.text-muted`                             | Used sparingly for labels, descriptions, or help text    |
| Body text       | Use `.text-dark` for all readable content | Provides consistency and high legibility                 |

**Container usage:** use `.container` for standard width, or `.container-fluid` if edge-to-edge is required.

---

## 🎭 Semantic Inversion: Color Name ≠ Color Meaning

In Bootstrap's dark themes like **Cyborg**, semantic color names (`.text-info`, `.bg-success`, etc.) may appear **very
different** from their default Bootstrap colors. This is intentional for better contrast and theme balance.

| Class           | Default Bootstrap Look | Actual in Cyborg      |
|-----------------|------------------------|-----------------------|
| `.text-info`    | Teal / cyan            | Pale blue-violet      |
| `.text-success` | Leaf green             | Vibrant neon green    |
| `.text-warning` | Gold amber             | Slightly muted orange |

### 🔑 Key Principle

> Don't assume `.text-info` = teal. When you want **a specific hue**, define a custom utility class instead of relying
> on Bootstrap semantics.

### ✅ Practical Guidelines

✅ Use `.text-muted`, `.text-secondary`, and `.text-info` for intentional tone  
❌ Avoid `.text-white` or `.text-light` — rely on Cyborg’s built-in contrast instead

### 🎨 Example

```css
.text-cyan {
    color: #00bcd4 !important;
}
```

Use this for titles, links, or labels where you want **that exact hue**, independent of the theme’s idea of “info.”

---

## 🧱 Card Structure

Use Bootstrap cards as-is, with `#111` backgrounds and default borders **unless a dynamic state is present**.

✅ **Note**: Using `border-secondary` or other border colors for visual structure is acceptable in **static content** (
like logs, status), **but state-driven color borders should take priority** when active.

### 🔲 Card Example

```html

<div class="card text-light shadow-sm border-warning" id="shutdown-card">
    <div class="card-header fw-semibold text-dark d-flex align-items-center">
        <i class="bi bi-exclamation-triangle-fill text-warning me-2"></i> Graceful Shutdown
    </div>
    <div class="card-body text-center">
        <p class="small text-muted">Safely save and stop the VRising server.</p>
        <button class="btn btn-outline-warning">Trigger Shutdown</button>
    </div>
</div>
```

| Element        | Rule                                                               |
|----------------|--------------------------------------------------------------------|
| `.card`        | `#111` background; may include `border-*` for static grouping      |
| `.card-header` | Inherits card background; uses `.text-dark` for clarity            |
| `.card-body`   | Main content styled with `.text-dark`; use `.text-muted` for hints |
| Borders        | Use `border-*` **only** when needed for layout or state signaling  |

---

## 💡 Status Blocks & Terminal Panels

| Component        | Style                                                       |
|------------------|-------------------------------------------------------------|
| `.log-output`    | Dark background (`#000`), monospace font, padded block      |
| `.status-output` | Same as logs — visually mirrors terminal output             |
| `.form-label`    | Use `.text-muted` to reduce contrast without hiding info    |
| `.text-dark`     | Use for all output text unless deliberately signaling state |

For reuse, define:

```css
.terminal-block {
    background-color: #000 !important;
    color: var(--bs-body-color) !important;
    font-family: monospace;
    padding: 1rem;
    border-radius: 0.375rem;
    overflow-y: auto;
    white-space: pre-wrap;
}
```

---

## 🚥 State Styling (Dynamic)

Apply these **via JavaScript** to indicate real-time changes. They visually override any base border or shadow styles.

| State         | Class                 | Description                               |
|---------------|-----------------------|-------------------------------------------|
| Refreshing    | `.card.refreshing`    | Glowing green border                      |
| Shutting down | `.card.shutting-down` | Pulsing orange glow                       |
| Disconnected  | `.card.disconnected`  | Static orange border for offline states   |
| Glow effect   | `.glow-text`          | Highlight text momentarily during refresh |

These states override any default or `.border-*` classes. They exist purely for feedback and can be animated or timed.

---

## 🧭 Responsive Layout Guidelines

| Viewport        | Card Layout                          |
|-----------------|--------------------------------------|
| `md`+           | Use `.row .col-md-4` and `.col-md-8` |
| `< md`          | Stack all content vertically         |
| Terminal height | Fixed to `250px` for consistency     |

---

## 🔗 Link & Button Styling

| Use case                | Style                                                  |
|-------------------------|--------------------------------------------------------|
| Primary actions         | `.btn-outline-*` only — never solid                    |
| Navigational text links | `.text-info`, `.text-muted`, or `.text-cyan`           |
| Avoid                   | `.text-white` — contrast handled by theme              |
| Consistent icons        | Bootstrap Icons with color for intent (not decoration) |

---

## 🧨 Visual Identity Summary

* 🎯 Jet black base (`#000`) with deep gray cards (`#111`)
* 📦 Static borders allowed **only when structurally helpful**
* ✳️ `.text-dark` as primary text color for full clarity
* 🎛️ Icons are subtle, purposeful, and always paired with text
* 🖥️ Logs/status areas styled as black terminal windows
* 🔁 Real-time states override border and glow dynamically

---

## 🧠 Design Intent Reminder

This dashboard reflects a **developer-friendly**, clean, minimalist admin experience. Every style exists to support
clarity, not decoration. Avoid visual clutter, preserve whitespace, and **trust Cyborg + Bootstrap defaults unless
there's a clear need to override.**
