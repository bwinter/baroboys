# ✅ Baroboys Admin Panel – Style Guide (Cyborg Theme, Finalized)

This guide reflects the finalized visual system for the admin panel, optimized for Bootswatch **Cyborg**, with Bootstrap-native class usage and minimal, purpose-driven overrides.

---

## 🎨 Theme Foundation

| Element         | Class / Style                               | Notes                                                  |
| --------------- | ------------------------------------------- | ------------------------------------------------------ |
| Page background | `html, body { background-color: #000; }`    | Pure black canvas — no gray bleed from the theme       |
| Cards           | `.card` with `background-color: #111`       | Deep gray — subtle lift from the background            |
| Header text     | `.text-dark`                                | Brightest available text — optimized for dark surfaces |
| Muted text      | `.text-muted`                               | Used sparingly for low-emphasis labels and hints       |
| Body text       | Use `.text-dark` on all normal card content | Ensures consistent legibility on black and near-black  |

**Container behavior:** use `.container` for standard spacing or `.container-fluid` for edge-to-edge layouts.

---

## 🧱 Card Structure

Use Bootstrap card layout with custom background and border overrides. Do **not** start with border colors — reserve those for state changes (e.g. `.refreshing`).

### 🔲 Markup Example

```html
<div class="card text-dark shadow-sm">
  <div class="card-header fw-semibold text-dark d-flex align-items-center">
    <i class="bi bi-exclamation-triangle-fill text-warning me-2"></i> Graceful Shutdown
  </div>
  <div class="card-body text-center">
    <p class="small text-muted">Safely stop the VRising server.</p>
    <button class="btn btn-outline-warning">Trigger Shutdown</button>
  </div>
</div>
```

| Element        | Rule                                                      |
| -------------- | --------------------------------------------------------- |
| `.card`        | `#111` background, subtle border (`#333`)                 |
| `.card-header` | Same background as body, uses `.text-dark`                |
| `.card-body`   | Default text is `.text-dark`, with muted labels as needed |
| `.btn`         | Use `btn-outline-*` only for semantic hierarchy           |

---

## 🔗 Link & Button Styling

| Rule                           | Class                                                   |
| ------------------------------ | ------------------------------------------------------- |
| Navigation/Actions             | Use `.text-dark` unless purposefully colored            |
| Subtle links (e.g. footer nav) | `.text-muted` or `.text-info` if context allows         |
| Action buttons                 | `btn-outline-*` (no solid buttons)                      |
| Avoid `text-white`             | Theme will handle correct contrast through `.text-dark` |

---

## 🧪 Status + Logs Display

| Component        | Style                                                                 |
| ---------------- | --------------------------------------------------------------------- |
| `.log-output`    | `background: #000`, `color: var(--bs-body-color)`                     |
| `.status-output` | Same as log output — terminal-style block                             |
| Labels           | Use `.form-label.text-muted`                                          |
| Headers          | Use `.text-dark` to align with rest of layout                         |
| Icons            | Use color (`text-warning`, `text-success`) sparingly, for signal only |

---

## 💬 State Indicator Styles (Dynamic, JS-Driven)

| State         | Applied Class         | Notes                                           |
| ------------- | --------------------- | ----------------------------------------------- |
| Refreshing    | `.card.refreshing`    | Green border + glow via `.border-success` style |
| Shutting down | `.card.shutting-down` | Orange pulse with `.border-warning` glow        |
| Disconnected  | `.card.disconnected`  | Orange border, matches "attention not danger"   |
| Glow effect   | `.glow-text`          | Used only on status label during refresh cycle  |

---

## 🧭 Responsive Layout

| View Width | Layout Guidance                                      |
| ---------- | ---------------------------------------------------- |
| `md`+      | Use `.col-md-4` / `.col-md-8` for side-by-side cards |
| `< md`     | Stack all cards vertically for simplicity            |

---

## 🧨 Summary of Visual Identity

* 🎯 **Void-black** base with dark-gray cards (`#111`)
* 🧵 **No pre-colored borders** — borders used only to show state
* ✳️ Brightest readable text via `.text-dark`
* 🧠 Minimal use of icons for color emphasis, not decoration
* 💬 Cards = black boxes with just enough definition and hierarchy
* 🛠️ All status + logs presented with terminal-inspired styling

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
> * Crisp `.text-dark` contrast used for all readable content
> * No pre-colored borders — state changes apply color dynamically
> * Minimal layout, no bright colors or visual clutter
> * Terminal and devops-inspired, clean icons and modern fonts
>
> Present as a clean web-based dashboard. Do not include layout hints or wireframes — let the UI components suggest structure naturally.”
