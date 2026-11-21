# DriverTrip — native iOS foundation

This native iOS app is developed separately from the existing web/PWA driver portal. The web portal and production API are not changed by this branch.

## Implemented in this branch

- SwiftUI sign-in screen connected to `POST /api/driver/login`.
- Driver session token stored in iOS Keychain (not UserDefaults).
- Assigned service list from `GET /api/driver/trips`.
- Status updates through `PATCH /api/trips/{id}/status`, with the same server-approved transitions as the PHP API.
- Optional ETA sent with status changes.
- Refresh, pull-to-refresh, logout and expired-session handling.
- XcodeGen project specification at `ios/project.yml`.

## Verified API contract

Production source of truth: `auren-digital/Trip-Tracking_SV/api/index.php`.

- Login returns `access_token`, `token_type`, `expires_at`.
- Driver trips return an array with `id`, `folio`, `flight_number`, `passenger_name`, `destination`, `pickup`, `scheduled_at`, `passengers`, `status`, and `eta_minutes`.
- Status update: `PATCH /api/trips/{id}/status` with `status` and optional `eta_minutes`.
- Location update: `PATCH /api/trips/{id}/location` with `latitude` and `longitude`; server accepts it only for operational GPS states.
- Logout: `POST /api/driver/logout`.

No API secrets are embedded in the app.

## Important GPS limitation found during integration

The current PHP API only accepts per-trip GPS updates in the operational states `driver_on_way`, `driver_arrived`, `passenger_onboard`, `in_transit`, and `incident`. Although it has a seven-hour GPS-window helper for public tracking, the driver location endpoint does not currently permit uploading coordinates while a trip is merely `confirmed` or `assigned`.

Therefore this iOS client must not claim or attempt seven-hour pre-service background tracking until the server contract is deliberately extended and tested. The existing browser portal's legacy `POST /api/driver/location` call also does not match the current PHP API route; the PHP endpoint is per-trip `PATCH /api/trips/{id}/location`. This mismatch should be corrected in a separate, reviewed web-portal change, not silently in this native branch.

## Background location still pending

The Core Location manager is currently a foundation only. It is not yet connected to API uploads. Before enabling background tracking:

1. Confirm the approved operational GPS policy and driver notice/consent.
2. Extend and test the API for the intended pre-service window, if required.
3. Wire Core Location to the active assigned trip(s), uploading only to authorized endpoints.
4. Request Always permission only when needed and explain why.
5. Test on physical iPhones for app suspension, termination, reboot, offline recovery, permission changes and battery impact.

## Build

This repository contains source and an XcodeGen specification, not a signed IPA. On macOS with Xcode and XcodeGen installed:

```sh
cd ios
xcodegen generate
open DriverTrip.xcodeproj
```

Then configure the Apple Developer Team and signing settings in Xcode. A macOS/Xcode build environment is required for device signing, archiving and App Store submission.
