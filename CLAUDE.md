# Nearzy

A hyperlocal marketplace: an Express + Sequelize + PostgreSQL API (`backend/`)
and a Flutter client (`frontend/`) serving customers, shop owners and admins from
one codebase.

## Keep the two documents in sync — every change

Two documents describe this project and must not drift from it. On **every**
change, check both; update whichever the change actually affects, **in the same
commit as the code**.

| Document | Update it when the change touches |
|---|---|
| [docs/nearzy-engineering-reference.html](docs/nearzy-engineering-reference.html) | Anything technical: routes, auth, data model, background jobs, env vars, project structure, known bugs |
| [docs/inside-nearzy.html](docs/inside-nearzy.html) | Anything that changes what the product *does* or its status: a feature starting or stopping working, a capability gained or lost |

`inside-nearzy.html` is non-technical and investor-facing. It must never
overstate what works — a claim that collapses in a live demo is worse than an
absent one. When a feature is broken, say so there.

Each file is the source of truth for its content and carries its published
artifact URL in a header comment. After editing, republish to that URL so the
local copy and the shared page never diverge. Publishing strips everything above
`<body>` — each file's header comment explains the exact mechanics.

When a fix resolves something the engineering reference lists under **Sharp
edges**, move it to **Resolved since the last revision** rather than deleting
it. Readers who saw the old version need to know it changed.

## Conventions that bite

- **Money is integer paise everywhere.** `price_in_paise`, `total_amount_paise`,
  `unit_price_paise`. Convert at the client boundary, never in the middle:
  `product_edit_sheet.dart` is the reference implementation
  (`(rupees * 100).round()` on write, `/ 100` on read).
- **Resolve ownership from the token, never the request body.** `req.user.id` →
  shop/customer lookup. Routes that trust a body-supplied `customerId` or
  `shopId` are listed as known problems in the engineering reference; don't add
  more.
- **Flutter: use `fvm`**, never a bare `flutter`/`dart` — the version is pinned
  in `.fvmrc` and a bare binary is probably a different SDK. Don't run
  `dart format` across existing files.
- **The design system is mandatory for UI.** See
  [.claude/skills/nearzy-design/SKILL.md](.claude/skills/nearzy-design/SKILL.md);
  pull from the tokens in `frontend/lib/theme/` rather than hardcoding a colour,
  radius or duration.
- **No migrations.** The schema is `sequelize.sync({ alter: true })` at boot, so
  the models are the only definition. Treat any column rename as a data-loss
  risk and plan it deliberately.
- **Background jobs are off unless `ENABLE_JOBS=true`.** They write shared state
  and rewrite prices, so a fresh checkout deliberately shows an empty alert list.
