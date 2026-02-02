#!/bin/bash
# OpenClawKit Installer Script
# This script handles the installation of OpenClaw AI with a user-friendly approach

# Display welcome message
echo "🦞 Welcome to OpenClawKit - OpenClaw AI, Simplified!"
echo "-------------------------------------------------------"

# Check for Node.js installation
check_node() {
  if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v | cut -d 'v' -f 2)
    echo "✅ Node.js $NODE_VERSION is installed"
    
    # Check if version is >= 22.0.0
    if [ "$(echo "$NODE_VERSION >= 22.0.0" | bc)" -eq 1 ]; then
      echo "✅ Node.js version meets OpenClaw requirements"
      return 0
    else
      echo "❌ OpenClaw requires Node.js 22+. Current version: $NODE_VERSION"
      return 1
    fi
  else
    echo "❌ Node.js is not installed"
    return 1
  fi
}

# Install Node.js if needed
install_node() {
  echo "📦 Installing Node.js 22..."
  
  # For macOS using Homebrew
  if command -v brew &> /dev/null; then
    brew install node@22
    echo "✅ Node.js 22 installed successfully"
  else
    # Install Homebrew first
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Then install Node
    brew install node@22
    echo "✅ Node.js 22 installed successfully"
  fi
}

# Install OpenClaw
install_openclaw() {
  echo "🦞 Installing OpenClaw..."
  curl -fsSL https://openclaw.ai/install.sh | bash
  
  echo "✅ OpenClaw installed successfully"
}

# Run the onboarding wizard
run_onboarding() {
  echo "🧙‍♂️ Running OpenClaw onboarding wizard..."
  openclaw onboard --install-daemon
  
  echo "✅ OpenClaw onboarding completed"
}

# Main installation flow
main() {
  echo "🔍 Checking requirements..."
  
  # Check for Node.js
  if ! check_node; then
    install_node
  fi
  
  # Install OpenClaw
  install_openclaw
  
  # Run onboarding
  run_onboarding
  
  echo "🎉 OpenClaw installation complete! Your AI assistant is ready to use."
  echo "📝 For more information, visit: https://docs.openclaw.ai"
}

# Start the installation
main