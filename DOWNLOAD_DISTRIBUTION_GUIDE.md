# Windows Distribution Guide - Filo (Desk-Sense)

This guide provides instructions on how to build, package, and distribute the Filo Windows application.

## Prerequisites

- **Flutter SDK**: Ensure Flutter 3.24.0 or later is installed.
- **Visual Studio**: Required for building Windows applications. Make sure to install "Desktop development with C++".
- **MSIX Package**: The `msix` tool is used for packaging. It is configured in `pubspec.yaml`.

## Configuration

Before building the release, ensure the API endpoint is correctly configured in:
`semantic_butler/semantic_butler_flutter/assets/config.json`

```json
{
    "apiUrl": "http://your-server-ip:8080"
}
```

> [!IMPORTANT]
> If you are deploying for production, ensure the `apiUrl` points to your public Serverpod instance.

## Building the Installer

### 1. Manual Steps

Navigate to the Flutter directory:
```powershell
cd semantic_butler/semantic_butler_flutter
```

Build the Windows release:
```powershell
flutter build windows --release
```

Create the MSIX package:
```powershell
dart run msix:create
```

The installer will be generated at:
`build/windows/runner/Release/Filo.msix`

### 2. Automated Script

You can use the provided `build-dist.ps1` script in the root directory to automate the process:

```powershell
.\build-dist.ps1
```

## Distribution

To update the website with the latest installer:

1. Copy the generated `.msix` file to `website/public/downloads/filo-windows.msix`.
2. Commit and push the changes to your repository.
3. The CI/CD pipeline (if configured) will deploy the website with the new download link.

## Troubleshooting

- **Certificate Issues**: By default, `msix:create` uses a self-signed certificate. For production, you may want to configure a trusted certificate in `pubspec.yaml`.
- **C++ Build Errors**: Ensure "Desktop development with C++" is installed in Visual Studio and run `flutter doctor` to verify.
- **Path Issues**: Ensure you are running commands from the `semantic_butler/semantic_butler_flutter` directory unless using the helper script.
