# Project guidance

This project uses Flutter with Flame and Cloudflare Workers static assets.
Keep the landing screen limited to the text "DEVxSD GameJam!" until a spec changes that scope.

Before changing behavior, create or update an OpenSpec change with requirements,
scenarios, and tasks. Keep `openspec/specs/` consistent with shipped behavior.
Run `flutter analyze`, `flutter test`, and `npm run build` for app changes.
Validate specs with `openspec validate --all --strict`.

Use `npm run build` for the release web build and `npx wrangler deploy` for deployment.
Do not commit generated build output, caches, or credentials.
