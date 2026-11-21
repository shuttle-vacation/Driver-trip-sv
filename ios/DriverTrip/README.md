# DriverTrip — Apple native foundation

This folder starts the native iOS implementation without changing the existing web/PWA driver portal.

## Current status

- SwiftUI app entry point and initial sign-in / home screens: scaffold only.
- Driver trip model: scaffold only; API decoding must be verified against backend payloads.
- Core Location manager: permission and location lifecycle foundation only.
- Authentication, trip loading, status updates, location uploads, push notifications, Apple Watch companion and App Store archive are not implemented yet.

## Integration contract

- Central API: https://api.shuttlevacation.com
- Existing web driver portal remains in place.
- Do not store API secrets in the app.
- Use HTTPS, revocable driver sessions, server-side authorization and minimal location retention.
- Do not upload coordinates until the authenticated driver has an eligible assigned service and the server confirms the tracking window.
- The server remains authoritative for the seven-hour pre-service GPS window and trip status transitions.

## Core Location requirements before background GPS

1. Add the appropriate location usage descriptions to the app Info.plist.
2. Explain the operational purpose before asking for authorization.
3. Request the least privilege that supports the approved workflow; request Always only when background tracking is genuinely required.
4. Enable the Location updates Background Mode only after reviewing Apple's current requirements and App Store privacy disclosures.
5. Test permission changes, app termination, reboot, loss of connectivity, battery impact and trip completion on physical iPhones.
6. Stop updates immediately when no eligible trip remains or the trip is completed/cancelled.

The code deliberately does not request permission on launch or transmit location by itself.

## Build environment

A native iOS app requires Xcode on macOS to create, sign, archive and run device builds. This repository currently contains source files, not a signed IPA or a complete Xcode project.

## Next implementation steps

1. Verify the driver login, assigned trips, status update and location upload API contracts.
2. Implement a secure API client and Keychain-backed session storage.
3. Connect the trip list and permitted status transitions.
4. Add server-authorized scheduled background location tracking.
5. Add push notifications and test on physical devices.
6. Create the Xcode project, signing configuration and App Store Connect metadata.
