# Accessibility

- Touch targets >= 48dp. Every icon button has a `tooltip`/`Semantics` label.
- Images carry a semantic label (title + creator). Decorative images are excluded.
- Text contrast >= WCAG AA (4.5:1), including the three reader themes.
- Do not convey state with color alone.
- Support TalkBack focus order, reduced motion (`MediaQuery.disableAnimations`), and system font scaling.
