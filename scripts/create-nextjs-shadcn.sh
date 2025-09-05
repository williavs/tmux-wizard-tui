#!/bin/bash

# NextJS + Shadcn Setup with Tweakcn Themes
# Using Next.js 15, Tailwind v4, and npm

set -e

PROJECT_NAME="${1:-}"
PROJECT_PATH="${2:-$(pwd)}"
THEME="${3:-}"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name> [path] [theme]"
    echo ""
    echo "Available themes from tweakcn.com:"
    echo "  modern-minimal, violet-bloom, t3-chat, mocha-mousse, amethyst-haze,"
    echo "  doom-64, kodama-grove, cosmic-night, quantum-rose, bold-tech,"
    echo "  elegant-luxury, amber-minimal, neo-brutalism, solar-dusk, pastel-dreams,"
    echo "  clean-slate, ocean-breeze, retro-arcade, midnight-bloom, northern-lights,"
    echo "  vintage-paper, sunset-horizon, starry-night, soft-pop"
    exit 1
fi

PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
FULL_PATH="$PROJECT_PATH/$PROJECT_NAME"

echo "Creating: $PROJECT_NAME at $FULL_PATH"

# Create Next.js 15 app with Tailwind v4
cd "$PROJECT_PATH"
echo "n" | npx create-next-app@latest "$PROJECT_NAME" \
    --typescript \
    --tailwind \
    --eslint \
    --app \
    --src-dir \
    --turbopack

cd "$FULL_PATH"

echo "Current directory: $(pwd)"
echo "Contents: $(ls -la)"

# Init shadcn and apply theme if specified
if [ ! -z "$THEME" ]; then
    echo "Initializing shadcn with $THEME theme..."
    # Run the theme command twice - first time inits shadcn, second applies theme
    yes | npx shadcn@latest add "https://tweakcn.com/r/themes/${THEME}.json"
    yes | npx shadcn@latest add "https://tweakcn.com/r/themes/${THEME}.json"
else
    echo "Initializing shadcn..."
    # First ensure shadcn is available
    if ! command -v npx &> /dev/null; then
        echo "Error: npx not found"
        exit 1
    fi

    # Try shadcn init with more robust input handling
    echo "Running shadcn init..."
    if ! echo -e "1\n1\ny\n" | npx shadcn@latest init --yes; then
        echo "Warning: shadcn init failed, trying alternative approach..."
        # Fallback: try without --yes flag
        echo -e "1\n1\ny\n" | npx shadcn@latest init
    fi
fi

# Add all components with auto-yes
echo "Installing all shadcn components..."
if ! yes | npx shadcn@latest add --all; then
    echo "Warning: Bulk component installation failed, trying individual components..."
    # Fallback: install some essential components individually
    for component in button card input label; do
        echo "Installing $component..."
        yes | npx shadcn@latest add "$component" || echo "Failed to install $component"
    done
fi

# Add useful packages
echo "Adding additional packages..."
npm install lucide-react next-themes

# Setup Claude (if available)
if command -v claudenew &> /dev/null; then
    echo "Setting up Claude directory..."
    claudenew
fi

echo "✅ Done. Project at: $FULL_PATH"
if [ ! -z "$THEME" ]; then
    echo "   Theme applied: $THEME"
fi
echo "Run: cd $FULL_PATH && npm run dev"