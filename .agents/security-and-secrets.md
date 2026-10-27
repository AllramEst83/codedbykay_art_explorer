# Security and secrets

- The Europeana key lives in `.env` (git-ignored, bundled as an asset). The app is private-use only; do not publish the APK or commit `.env`.
- Never print or log the key. Only HTTPS endpoints; no cleartext traffic.
- Validate/escape anything from the API before rendering or launching (only open `https` URLs).
- Request the minimum Android permissions (INTERNET, ACCESS_NETWORK_STATE).
