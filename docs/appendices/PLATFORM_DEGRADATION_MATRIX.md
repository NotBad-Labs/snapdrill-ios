# Platform Degradation Matrix (iOS 16/17/18/26)

Purpose: define availability and fallbacks per OS level.

## Matrix

- OCR (Vision): iOS 16+ basic; math formula structuring deferred (vNext)
- Notifications: iOS 16+; schedule windows + quiet hours; deep links
- App Intents/Shortcuts: progressive enhancement; optional
- CloudKit: private DB multi-device only in MVP; sharing/teacher deferred
- AR/visionOS: deferred to vNext; provide 2D alternatives

## Guards

- Compile-time: #available checks
- Runtime: capability detection; graceful degradation UI
