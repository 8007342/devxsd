# DEVxSD GameJam

A minimal Flutter + Flame canvas showing **DEVxSD GameJam!** and nothing else.

## Development

Install the Flutter SDK version in `.flutter-version` and Node.js 22 or newer.

```sh
flutter pub get
npm ci
flutter run -d chrome
```

For a remote development container, use `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080`.

```sh
flutter analyze
flutter test
npm run build
npm run dev
```

`npm run dev` builds the release app and starts a local Wrangler preview on port 8787. For Flutter hot reload, use `flutter run` instead.

## Cloudflare Workers

Configure Cloudflare Workers Builds with:

- Build command: `npm run build` (or `npx npm run build`).
- Deploy command: `npx wrangler deploy`.
- Root directory: repository root.

The build script installs the pinned Flutter SDK when Flutter is unavailable, resolves the locked Dart dependencies, and generates `build/web`. Wrangler serves that directory as static assets. Flutter rendering assets are bundled so the browser does not need a separate rendering CDN.

For a manual deployment after authenticating with `npx wrangler login`:

```sh
npm ci
npm run build
npx wrangler deploy
```

Alternatively, `npm run deploy` builds and deploys in one command. CI can authenticate using Cloudflare's `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` environment variables. Do not commit credentials.

## Specifications

`openspec/specs/devxsd-gamejam/spec.md` defines the initial behavior. Future changes start with an OpenSpec proposal, design where needed, scenarios, and tasks before implementation. Use `openspec validate --all --strict` to validate specs. `plan/roadmap.md` tracks any work remaining between sessions.
