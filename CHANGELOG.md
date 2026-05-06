# Changelog

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
