# Kinako

A simple and beautiful macOS GUI application for building `.pkg` installer packages.

<p align="center">
  <img src="Icon/Kinako.svg" width="128" alt="Kinako">
</p>

<p align="center">
  <strong>Make macOS package creation simple.</strong>
</p>

<p align="center">
  macOS 26+ · Apple Silicon · SwiftUI
</p>

---

## Overview

**Kinako** is a lightweight native macOS application that makes creating macOS installer packages (`.pkg`) easy.

No complicated Terminal commands. No manually managing package directory structures.

Simply add your files, organize their installation destinations, configure package information, and build your `.pkg` installer.

## Features

- **Drag & Drop** — Easily add files, folders, and applications.
- **Visual Package Layout** — See exactly how your package directory structure is organized.
- **Custom Destinations** — Choose installation destinations for individual items.
- **Destination Presets** — Quickly select commonly used macOS directories.
- **Custom Folders** — Add your own installation directories.
- **Preinstall Scripts** — Execute scripts before installation.
- **Postinstall Scripts** — Execute scripts after installation.
- **Package Metadata** — Configure package name, identifier, and version.
- **Optional Package Signing** — Specify a signing identity when building packages.
- **Native Interface** — Designed with SwiftUI for macOS.

## Requirements

| Component | Requirement |
|---|---|
| Operating System | macOS 26.0 or later |
| Architecture | Apple Silicon |
| Development Environment | Xcode 26+ |
| Swift | Swift 6.2+ |

## Installation

1. Download the latest release from [GitHub Releases](../../releases).
2. Extract `Kinako.app` from the downloaded archive.
3. Move Kinako to your Applications folder.

### Important: Security Notice

**Kinako is NOT signed with an Apple Developer ID certificate and is NOT notarized by Apple.**

macOS Gatekeeper may prevent the application from opening.

To launch Kinako, you may need to remove the macOS quarantine attribute.

Open Terminal and execute:

`xattr -dr com.apple.quarantine /Applications/Kinako.app`

If Kinako is located somewhere else, replace the path with the actual location of your application.

For example, if it is still in Downloads:

`xattr -dr com.apple.quarantine ~/Downloads/Kinako.app`

After executing the command, try opening Kinako again.

**Security warning:** Removing the quarantine attribute bypasses an important macOS security protection. Only do this if you trust the source of the application.

## Usage

### 1. Add Files

Drag and drop files, folders, or applications into the left panel.

You can also use the file picker to select multiple items.

### 2. Organize Your Package

Use the central package layout to visualize the installation directory structure.

You can:

- Drag items to change their destinations.
- Select destinations through the context menu.
- Use predefined destination presets.
- Add custom destination folders.
- Remove individual items.

### 3. Configure Package Information

Use the right-side settings panel to configure:

- Package Name
- Package Identifier
- Package Version

### 4. Configure Scripts (Optional)

Add installation scripts if needed.

- `preinstall` — Runs before package installation.
- `postinstall` — Runs after package installation.

### 5. Build Your Package

Click the package creation button and select an output location.

Kinako uses Apple's native `pkgbuild` utility to generate the `.pkg` installer.

## Default Installation Destinations

Kinako includes several commonly used destination presets.

| Destination | Description |
|---|---|
| `/Applications` | macOS applications |
| `/usr/local/bin` | Executable files |
| `/usr/local/lib` | Libraries |
| `/Library/Application Support` | Application support files |
| `/Library/LaunchDaemons` | Launch Daemons |
| `/Library/LaunchAgents` | Launch Agents |
| `/Library/Fonts` | Fonts |
| `/Library/Frameworks` | Frameworks |

Custom destinations can also be added.

## Package Signing

Package signing is optional.

You can specify a signing identity when building a package.

If no signing identity is provided, Kinako creates an unsigned installer package.

Note that package signing and application signing are separate processes.

## Building from Source

### Clone the Repository

`git clone https://github.com/YOUR_USERNAME/Kinako.git`

`cd Kinako`

### Build

Run the build script:

`chmod +x build_app.sh`

`./build_app.sh`

The generated application will be located at:

`build/Kinako.app`

The build script uses Swift Package Manager and creates a macOS application bundle.

### Open with Xcode

You can also open `Package.swift` in Xcode 26 or later and run the application using `Command + R`.

## Technology Stack

- Swift
- SwiftUI
- AppKit
- Foundation
- Swift Package Manager
- Apple `pkgbuild`

## Project Structure

    Kinako/
    ├── Icon/
    │   ├── Kinako.icns
    │   ├── Kinako.svg
    │   └── AppIcon-1024.png
    ├── Sources/
    │   └── Kinako/
    │       ├── KinakoApp.swift
    │       ├── ContentView.swift
    │       ├── Models.swift
    │       └── Builder.swift
    ├── Package.swift
    ├── build_app.sh
    └── README.md

## License

Kinako is licensed under the MIT License.

You are free to use, modify, distribute, and incorporate this software into commercial projects, subject to the terms of the MIT License.

See [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with Swift.
</p>

<p align="center">
  <strong>Kinako</strong>
</p>
