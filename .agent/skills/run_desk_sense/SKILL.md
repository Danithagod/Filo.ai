---
name: run_desk_sense
description: Automates running and starting the Desk-Sense desktop application, including the Serverpod backend and Flutter frontend.
---

# Run Desk-Sense Skill

This skill provides instructions and automated steps to launch the Desk-Sense application. It ensures that the backend server is running and that any port conflicts (especially port 8080) are resolved before starting the Flutter application.

## Prerequisites
- Flutter SDK installed and on PATH.
- Dart SDK installed and on PATH.
- Docker (optional, if using local Postgres/Redis instead of Neon).

## Quick Start
To launch the application, follow these steps:

### 1. Resolve Port Conflicts
The Serverpod backend uses port 8080 by default. Check if the port is in use and terminate the conflicting process.

```powershell
# Find process on port 8080
netstat -ano | findstr :8080

# Kill process (replace <PID> with the actual PID)
taskkill /F /PID <PID>
```

### 2. Start the Backend Server
Navigate to the server directory and start the Serverpod server.

```powershell
cd semantic_butler/semantic_butler_server
dart bin/main.dart
```

### 3. Start the Frontend Application
Navigate to the flutter directory and run the app in Windows mode.

```powershell
cd semantic_butler/semantic_butler_flutter
flutter run -d windows
```

## Troubleshooting

### White Screen on Launch
If the application launches to a white screen:
- Ensure the server is running and accessible (check `http://localhost:8080`).
- Verify that the `MaterialApp` builder in `main.dart` wraps the layout in a `Material` widget to provide the necessary context.
- Check the console logs for "Failed to load indexing status" or similar API errors.

### Docker Connection Errors
If the server fails to connect to the database:
- Check `config/development.yaml` for the current database host.
- If using local Docker, ensure containers are running: `docker compose up -d`.
