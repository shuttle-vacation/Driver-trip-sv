# DriverTrip — native iOS foundation

This native iOS app is developed on a separate branch from the existing web driver portal. The deployed web portal and production API are not modified by this branch.

## Implemented in this branch

- SwiftUI sign-in connected to `POST /api/driver/login`.
- Session token stored in iOS Keychain.
- Assigned services from `GET /api/driver/trips`.
- Status updates through `PATCH /api/trips/{id}/status`, including optional ETA.
- Automatic GPS monitoring tied to assigned trips and the server's seven-hour window.
- GPS uploads use the actual central API route: `POST /api/driver/location` with `latitude`, `longitude`, and `accuracy`.
- The central endpoint authenticates the driver, checks the seven-hour window, and updates all eligible non-closed services assigned to that driver. The driver does not select a service.
- Location authorization descriptions and iOS Location background mode are configured in the XcodeGen specification.

## Verified GPS behavior in the PHP API

The API's `gps_window_open()` helper opens tracking seven hours before `scheduled_at` and closes it for `completed` or `cancelled` services. `POST /api/driver/location` checks the authenticated driver's assigned trips, filters them through this helper, and updates every eligible trip in one request. The native app now calls this route instead of the per-trip endpoint, which intentionally accepts only operational GPS states.

The API itself already supported the seven-hour window; no production API/database migration was necessary for this native client correction.

## iOS background-location limitations

- The app requests Always authorization, enables the Location background mode and uses significant-change monitoring to help iOS wake/restart location monitoring when the device moves.
- Continuous high-accuracy updates are enabled while the app is running and an assigned service is inside the seven-hour window.
- iOS controls background scheduling and may suspend or throttle apps. A seven-hour timer cannot be guaranteed to fire at an exact minute if the app has been suspended and the device remains stationary.
- If the user force-quits the app, iOS generally will not relaunch it for location events until the user opens it again.
- Always permission, Location Services, battery settings and real-device testing are required. The app must clearly explain location use to drivers.

The app refreshes assigned services periodically while active and reevaluates the server-authorized GPS window. It stops updates when no eligible service remains or the driver signs out.

## Build

This repository contains source and an XcodeGen specification, not a signed IPA. On macOS with Xcode and XcodeGen installed:

```sh
cd ios
xcodegen generate
open DriverTrip.xcodeproj
```

The `.github/workflows/drivertrip-ios.yml` workflow attempts an unsigned iOS Simulator build on GitHub-hosted macOS. A successful simulator build is not an App Store archive. Device signing and submission require Apple Developer signing configuration and a macOS/Xcode environment.
