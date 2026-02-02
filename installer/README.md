# OpenClawKit Installer

This directory contains the OpenClawKit installer components for macOS.

## Components

- `install.sh`: Core installation script that handles Node.js setup and OpenClaw installation
- `AppDelegate.swift`: Swift UI wrapper for the installer with a visual interface
- `package.sh`: Script for building the macOS app bundle (in development)

## Build Instructions

1. Install Xcode or Xcode Command Line Tools
2. Install SwiftUI dependencies
3. Run `./package.sh` to build the installer

## Features

- Visual interface for OpenClaw installation
- Node.js 22+ setup with version checking
- Visual onboarding wizard
- API key configuration interface
- Channel setup wizard
- Service installation

## Development Notes

The installer wraps the following commands:
- `curl -fsSL https://openclaw.ai/install.sh | bash`
- `openclaw onboard --install-daemon`

But provides a graphical user interface for the entire process, making it accessible to non-technical users.