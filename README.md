# OpenClawKit

## Overview
OpenClawKit is a user-friendly installer for OpenClaw AI, simplifying the setup process for macOS users.

## Monorepo Structure

This repository uses a monorepo structure containing:

### 📱 **OpenClawKit** (macOS App)
- **Location**: `/OpenClawKit/`
- **Technology**: SwiftUI, Swift 5.0
- **Purpose**: Native macOS companion app for OpenClaw configuration and management
- **Xcode Project**: `OpenClawKit.xcodeproj`

### 🌐 **Website** (Marketing Site)
- **Location**: `/website/`
- **Technology**: Bootstrap 5.3.0, static HTML/CSS/JS
- **Purpose**: Marketing and download pages
- **Deployment**: Vercel (https://openclawkit.vercel.app)

### ⚙️ **Installer** (Setup Scripts)
- **Location**: `/installer/`
- **Purpose**: Installation and setup scripts for OpenClaw

## Quick Start

### Development Setup

#### macOS App Development
```bash
# Open the Xcode project
open OpenClawKit/OpenClawKit.xcodeproj
```

#### Website Development
```bash
# Serve website locally
./serve.sh
# or navigate to website directory and use any static server
cd website && python3 -m http.server 3000
```

## Deployment

### Website
- **Platform**: Vercel
- **Root Directory**: `/website`
- **Build Steps**: None (static site)
- **URL**: https://openclawkit.vercel.app

### macOS App
- **Platform**: Mac App Store (planned)
- **Build**: Use Xcode to archive and distribute

## Technical Details

### OpenClawKit App
- **Minimum OS**: macOS 26.0+
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with Combine
- **Features**: Setup wizard, configuration management, AI provider integration

### Website
- **Framework**: Bootstrap 5.3.0
- **Design**: Responsive
- **Type**: Static site
- **Hosting**: Vercel

## Quick Links
- **Website**: [OpenClawKit Vercel Deployment](https://openclawkit.vercel.app)
- **GitHub**: [Repository](https://github.com/ngmeyer/openclaw-kit)