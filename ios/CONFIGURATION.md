# Integration configuration

Text and photo nutrition can use the included private-backend route. Without a configured HTTPS base URL, the app keeps the explicit local demo estimator. Restaurant menu lookup still returns a reliable unavailable state.

## Private backend contract

The iPhone client calls `POST /api/meal-analysis`, authenticated by a backend token stored in Keychain. The included Express route calls OpenAI’s Responses API with `gpt-4o-mini`, accepts text or image input, requests schema-constrained nutrition output, and disables response storage. The OpenAI API key stays on the backend.

Example non-secret development configuration shape:

```text
MEALTRACKER_API_BASE_URL=https://your-private-backend.example
OPENAI_API_KEY=server-only-openai-key
MEALTRACKER_BACKEND_TOKEN=separate-random-client-token
```

1. Deploy this repository’s Express server to an HTTPS host.
2. Set `OPENAI_API_KEY` and a long random `MEALTRACKER_BACKEND_TOKEN` in that host’s secret manager.
3. In Xcode, set the MealTracker target’s `MEALTRACKER_API_BASE_URL` user-defined build setting to the HTTPS origin, without `/api/meal-analysis`.
4. Build and run the app, open Settings, paste the matching backend token, and Save. The token is stored in the device Keychain.

For a public or multi-user release, replace the private token with real user authentication and short-lived access tokens. Never treat a shared token as a general production authentication system.

Do not put AI, geocoding, restaurant, or search provider keys in `.xcconfig`, `Info.plist`, source, build settings, entitlements, or bundled JSON. A base URL is not a credential, but production builds should still use an allowlisted HTTPS host and certificate-valid transport.

## Required production responses

Meal analysis responses are schema-constrained and then runtime-validated for a meal name, editable detected items and quantities, macro estimates, overall confidence, and material assumptions before they reach `MealDraft`. Malformed responses become an unavailable state and are never persisted.

Menu responses should include source URL, publisher, retrieval time, official/estimated status, and an expiration. If reliability is unknown, return `noReliableMenu` and keep capture available.

Adventure responses may supply bounded narration and choices only. Resource balance, inventory, future character state, dice, and quest state remain deterministic application data.

## Apple capabilities

- HealthKit read types: body mass, workouts, step count, active energy burned
- Location: When In Use only
- Camera: contextual request from Take Photo
- Speech and microphone: contextual request from Speak
- Photos: system Photos picker, which does not require broad library enumeration

iCloud sync and notification capabilities are not enabled in this first local-only milestone.
