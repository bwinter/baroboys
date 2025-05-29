# ✅ Baroboys Admin Panel – Style Guide (Cyborg Theme, Finalized)

This guide reflects the final visual system for the admin panel, optimized for Bootswatch **Cyborg**, with custom overrides for improved contrast and layout clarity.

---

## 🎨 Theme Foundation

| Element         | Class / Style                           | Notes                                 |
| --------------- | --------------------------------------- | ------------------------------------- |
| Page background | `html, body { background-color: #000 }` | Fully black — eliminates gray bleed   |
| Cards           | `.card.bg-black` (via custom style)     | Use `#111` for darker contrast        |
| Header color    | `.text-info` overridden to `#00bcd4`    | No purple — clear cool tone           |
| Text muted      | `.text-muted` → `#999`                  | Adjusted for better contrast on black |

**Container behavior:** use `.container`, or `.container-fluid` if edge-to-edge layout is needed.

---

## 🧱 Card Structure

Use native Bootstrap card markup for consistent layout and automatic header separators.

### 🔲 Markup Example

```html
<div class="card border-warning">
  <div class="card-header fw-bold">
    <i class="bi bi-exclamation-triangle-fill text-warning me-2"></i> Graceful Shutdown
  </div>
  <div class="card-body text-center">
    <p class="small text-muted">Safely stop the VRising server.</p>
    <button class="btn btn-outline-warning">Trigger Shutdown</button>
  </div>
</div>
```

| Element        | Rule                                        |
| -------------- | ------------------------------------------- |
| `.card`        | Use `bg: #111`, border color (`border-*`)   |
| `.card-header` | Required — adds a clean visual divider      |
| `.card-body`   | Optional text centering for layout symmetry |
| Buttons        | Use `btn-outline-*` for clean hierarchy     |

---

## 🔗 Link & Button Styling

| Rule                    | Class                                    |
| ----------------------- | ---------------------------------------- |
| Header links            | `text-info`, but overridden to `#00bcd4` |
| Internal action buttons | `btn btn-outline-*`                      |
| Avoid `text-white`      | Let the theme/override handle contrast   |

---

## 🧪 Status + Logs Display

| Component   | Style                                                   |
| ----------- | ------------------------------------------------------- |
| `iframe`    | `background: #000`, `color: #ccc`                       |
| Logs area   | `.log-output` block styled with monospace font, dark bg |
| Form labels | Use `.form-label` + `color: #bbb` override              |

Log viewer uses JS to dynamically load logs and inject HTML into the `#log-output` block.

---

## 🧭 Responsive Layout

| View Width | Card Layout                                    |
| ---------- | ---------------------------------------------- |
| `md`+      | Use `.col-md-4` / `.col-md-8` for side-by-side |
| `sm`       | Cards stack vertically                         |

---

## 🧨 Summary of Visual Identity

* 🎯 Deep black theme with dark-gray cards (`#111`)
* ✨ Cool blue accents (title, icons) for clarity
* 🧱 Structured cards with visual header/body separation
* 🛠️ Focused on server control, clarity, and terminal legibility

---

# 🎨 Updated DALL·E Prompt: Admin Panel Dashboard (Cyborg Style)

> “Design a modern, dark-mode admin panel for managing a multiplayer game server. This is a single-page dashboard, not a full website.
>
> The interface must support:
>
> * A graceful shutdown button (styled as a warning)
> * A live server status area (like a terminal or iframe-style block)
> * A log viewer with dropdown to switch logs and a scrollable output area
>
> Visual tone:
>
> * Inspired by the Bootswatch Cyborg theme
> * Pure black background (`#000`), deep gray cards (`#111`)
> * Clear borders and crisp text contrast
> * Minimal layout, no bright colors or visual clutter
> * Terminal and devops-inspired, clean icons and modern fonts
>
> Present as a clean web-based dashboard. Do not include layout hints or wireframes — let the UI components suggest structure naturally.”
