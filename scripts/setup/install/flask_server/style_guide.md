# 🎨 Baroboys UI Style Guide

**Darkly Theme + Bootstrap 5.3**
*Last updated: May 2025*

This guide defines the visual language and layout rules for Baroboys’ Admin Interface using the Bootswatch “Darkly” theme and vanilla Bootstrap 5 utilities.

---

## 📄 Page Structure

| Area      | Class Example                    | Notes                       |
| --------- | -------------------------------- | --------------------------- |
| `body`    | `bg-dark text-light py-4`        | Universal base styling      |
| Container | `<div class="container">`        | Wraps page content          |
| Headings  | `text-info fw-bold mb-4`         | Consistent title color      |
| Sections  | `.row.g-4 > .col-md-6/.col-lg-4` | Responsive card grid layout |

---

## 🧱 Cards

### ✅ General Rules

* Use **`.card.bg-secondary.text-light.shadow-sm`** as the default card style.
* Add `border-*` **only for meaning** (e.g. warning, success).
* No custom backgrounds or inline styles unless absolutely needed (like fixed iframe height).

### 💡 Example

```html
<div class="card bg-secondary text-light shadow-sm border-success">
  <div class="card-header fw-bold">
    <i class="bi bi-bar-chart-line me-2"></i> Server Status
  </div>
  <div class="card-body">
    <iframe src="/check-status" class="w-100 rounded border" style="height: 250px;"></iframe>
  </div>
</div>
```

---

## 🎯 Color Usage

| Element     | Class Example                       | Use Case                     |
| ----------- | ----------------------------------- | ---------------------------- |
| Card Border | `border-warning` / `border-success` | For important state cues     |
| Buttons     | `btn-outline-warning`               | Match the card color         |
| Links       | `link-light` / `text-info`          | High-contrast on dark bg     |
| `code` tags | `bg-dark text-light px-2`           | For inline technical content |

Avoid `bg-*` or `text-*` directly on `.card-body` or `.card-header`.

---

## 🔗 Links

* Use `link-light` inside dark cards
* Use `text-info` for standalone links (e.g. return to panel)
* Add icons before text using Bootstrap Icons or emoji
  Example:

  ```html
  <a href="/" class="link-light"><i class="bi bi-tools me-2"></i>Admin Panel</a>
  ```

---

## 🧭 Icons

| Icon Source | Use For       | Example                       |
| ----------- | ------------- | ----------------------------- |
| Bootstrap   | UI Components | `<i class="bi bi-save2"></i>` |
| Emoji       | Navigation    | 🧭 🔧 🛠                      |

Icons go before text, with `.me-2` for spacing.

---

## 🖥 Layout Grid

| Screen Size | Layout            |
| ----------- | ----------------- |
| `md` & up   | 2–3 cards per row |
| `sm` & down | Stack vertically  |

Use `.row.g-4` with `.col-md-6`, `.col-lg-4` inside to maintain structure.

---

## 🧪 Special Components

### 🔄 Status Panel (`status.html`)

* Use a monospace font on the page
* Timestamp:

  ```html
  <p class="text-info">⏱ Refreshed: <code class="bg-dark text-light px-2 rounded">{{ timestamp }}</code></p>
  ```
* Status content:

  ```html
  <div class="bg-dark border rounded p-3 overflow-auto" style="white-space: pre-wrap;">{{ status }}</div>
  ```

### 🚫 404 Page

* Full viewport centering using `vh-100` and `d-flex align-items-center justify-content-center`
* Minimal layout in a card with clear return links

---

## ✅ Summary Guidelines

| ✅ Do                               | ❌ Avoid                                |
| ---------------------------------- | -------------------------------------- |
| Use `.bg-dark .text-light` on body | Avoid inline styles for colors         |
| Use `.bg-secondary` for cards      | Avoid `bg-warning`/`bg-light` on cards |
| Use `border-*` for meaning only    | Don’t color every card differently     |
| Use Bootstrap icons consistently   | Don’t mix icon styles randomly         |
| Use `.shadow-sm` for card depth    | Avoid flat designs on dark backgrounds |
