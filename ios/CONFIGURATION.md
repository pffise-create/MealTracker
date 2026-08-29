# Production integration configuration

The committed iPhone app has no secret configuration. Text/photo nutrition and adventure copy use local demo providers; menu lookup returns a reliable unavailable state. This is deliberate.

## Private backend contract

Add production providers behind the existing service protocols. The client should authenticate to a private TLS backend using a short-lived user token stored in Keychain. Provider API keys stay on that backend.

Example non-secret development configuration shape:

```text
MEALTRACKER_API_BASE_URL=https://your-private-backend.example
MEALTRACKER_ENVIRONMENT=development
```

Do not put AI, geocoding, restaurant, or search provider keys in `.xcconfig`, `Info.plist`, source, build settings, entitlements, or bundled JSON. A base URL is not a credential, but production builds should still use an allowlisted HTTPS host and certificate-valid transport.

## Required production responses

Meal analysis responses should be schema-validated before they reach `MealDraft` and include detected items, quantities, units, optional nutrition fields, per-field confidence, material ambiguities, provenance, and editable ingredient structure. Malformed responses must become a retry/manual fallback, never persisted application state.

Menu responses should include source URL, publisher, retrieval time, official/estimated status, and an expiration. If reliability is unknown, return `noReliableMenu` and keep capture available.

Adventure responses may supply bounded narration and choices only. Resource balance, inventory, future character state, dice, and quest state remain deterministic application data.

## Apple capabilities

- HealthKit read types: body mass, workouts, step count, active energy burned
- Location: When In Use only
- Camera: contextual request from Take Photo
- Speech and microphone: contextual request from Speak
- Photos: system Photos picker, which does not require broad library enumeration

iCloud sync and notification capabilities are not enabled in this first local-only milestone.
