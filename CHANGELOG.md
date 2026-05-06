# Changelog

## 0.2.0

### New features

- **GraphQL pretty-print**: detect GraphQL operations on the wire, surface the operation name in the transaction list with a `GQL` badge, render the query / variables / data / errors as separate sections in the detail screen.
- **Stats / analytics screen**: live dashboard accessible from the inspector AppBar — total / success / failure / success-rate, avg / p95 / max duration, slowest endpoints, most-failing endpoints, requests-per-host bar chart.
- **HAR 1.2 export**: one-tap export of any transaction (or all of them) as a HAR file. Drops straight into Chrome DevTools, Charles, Postman, Insomnia, Fiddler.
- **Replay request**: re-fire any captured request through your existing HTTP client. Register a replayer once with `NetWatch.registerReplayer(NWDioReplayer(dio))` and a Replay FAB appears on the detail screen.
- **Pause notifications**: runtime toggle in Settings to silence pop-up banners while keeping NetWatch capturing in the background.
- **Success / Failure tabs**: inspector now opens with `All / Success / Failure` tabs, each with a live count badge. Filter chips still work inside each tab for granular status filtering.
- **`NWGraphQL`** utility class exposed in the public API for custom GraphQL handling.

### Fixes

- Snackbars from inside bottom sheets (cURL, Export, Settings) now render *inside* the sheet instead of being hidden behind it. New `NWSheetShell` wraps each sheet in a local `ScaffoldMessenger`.
- Inspector / detail screens render correctly regardless of the host app's color seed: a self-contained NetWatch theme replaces the inherited Material 3 theme that previously made the status badge and Switch invisible against tinted AppBars.
- `showModalBottomSheet`, `showDialog`, and the cURL / Export sheets now actually open from inside the inspector. Previously they failed silently because the inspector was mounted as a raw `OverlayEntry` with no `Navigator` ancestor; each NetWatch screen now hosts its own `Navigator` + `HeroControllerScope`.
- Notification banner duplicate-key crash fixed — when a transaction transitioned from pending to completed, both events were appended with the same `ValueKey`. Same-id notifications now update in place.

### Breaking

- Minimum `dio` bumped from `>=4.0.0` to `>=5.4.0` (we use `DioException`, introduced in dio 5.4).
- Minimum `chopper` bumped from `>=7.0.0` to `>=8.0.0` (we use chopper 8's `Chain` API).
- `share_plus` constraint widened from `^10.0.0` to `>=10.0.0 <14.0.0`.

### Other

- Unused `path_provider` dependency removed.
- Public-API dartdoc coverage raised above 20% (from 17.3%).
- Package description shortened to fit pub.dev's 60–180 char range.

## 0.1.0

Initial release.

- Sealed-class request, response, status, and security models.
- In-memory storage with size cap and ordered access.
- Dio, http, and Chopper interceptors that never throw and never block traffic.
- Sensitive data masking (headers, JSON body, URL query params) with case-insensitive matching.
- Security analysis: HTTPS, HSTS, X-Content-Type-Options, CSP, Basic auth, sensitive query params.
- Exporters: cURL, Postman Collection v2.1 (single or batch), plain-text share.
- Floating draggable bubble with edge-snap and live unseen-request badge.
- Toast-style overlay notifications, max 3 stacked, auto-dismiss.
- Full-screen inspector with status filters, live stream, search, settings sheet.
- Per-transaction detail screen with Request, Response, and Security tabs.
- `NetWatch.builder` wraps the app in its own Overlay — never pushes routes onto the developer's navigator.
- Auto-disabled in release builds via `kReleaseMode` (interceptors and builder become pass-through).
