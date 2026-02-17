# Logging Policy (Minimal)

This project uses a minimal logging approach.

## DEBUG builds

- Developer-facing logs are allowed for diagnostics.
- Prefer concise, actionable messages.
- Avoid logging sensitive user/device data.

## RELEASE builds

- Do not rely on verbose console logging.
- Keep runtime logs minimal and non-sensitive.
- Use crash reporting / analytics tooling (if integrated) for production diagnostics.

## Current repo note

Some `print(...)` statements exist in audio/menu components. Before production submission, ensure release behavior does not emit noisy logs and does not expose sensitive information.
