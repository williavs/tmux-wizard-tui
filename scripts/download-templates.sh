#!/bin/bash
# Tmux Wizard Template Downloader
# Downloads the full collection of Next.js templates for offline use

set -e

# Source the template manager and UI functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/ui.sh"
source "$SCRIPT_DIR/../lib/template-manager.sh"

# Show banner
section_header "Tmux Wizard Template Downloader"

cat << 'EOF'
This script will download a comprehensive collection of Next.js templates:

📦 What you'll get:
  • 200+ Vercel Next.js examples
  • Clerk authentication templates  
  • Shadcn/UI examples
  • Modern SaaS starters
  • E-commerce templates
  • Real-time collaboration apps
  • AI application templates

💾 Storage requirements:
  • ~500MB disk space
  • Internet connection required
  • Git must be installed

⚡ Benefits:
  • Offline template browsing
  • Faster project creation
  • Full template search
  • Latest versions from GitHub

EOF

# Validate requirements
print_info "Checking requirements..."
if ! validate_commands "git curl"; then
    exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
    print_warning "fzf not found - template selection will be limited"
    print_info "Install fzf for the best experience: https://github.com/junegunn/fzf"
fi

# Check available disk space
available_space=$(df -BG "${TMUX_WIZARD_TEMPLATES_DIR:-$HOME}" | tail -1 | awk '{print $4}' | sed 's/G//')
if [[ $available_space -lt 1 ]]; then
    print_error "Insufficient disk space. Need at least 1GB free."
    exit 1
fi

print_success "Requirements check passed"

# Confirm download
echo ""
if ! confirm_action "Download template collections now? (~500MB)"; then
    print_info "Download cancelled. You can run this script again anytime."
    print_info "Tmux Wizard will work with curated templates in the meantime."
    exit 0
fi

# Start download
echo ""
print_info "Starting template collection download..."
print_info "This may take 5-10 minutes depending on your internet connection"

# Create progress tracking
DOWNLOAD_LOG="/tmp/tmux-wizard-download-$$.log"
exec 3> >(tee "$DOWNLOAD_LOG")

# Download collections
download_template_collections

# Show completion summary
echo ""
section_header "Download Complete!"

print_success "Template collections successfully downloaded"
print_info "Templates location: ${TMUX_WIZARD_TEMPLATES_DIR:-$HOME/.tmux-wizard/templates}"

# Show statistics
if has_local_templates; then
    local template_count
    template_count=$(find "${TMUX_WIZARD_TEMPLATES_DIR:-$HOME/.tmux-wizard/templates}" -name "package.json" 2>/dev/null | wc -l)
    print_success "$template_count templates now available locally"
fi

echo ""
print_color $GREEN "🎉 You can now use 'full' mode in tmux-wizard for complete template browsing!"
print_info "Run: ./src/tmux-wizard.sh and select option 2 for all templates"

# Clean up
rm -f "$DOWNLOAD_LOG"

echo ""
show_box "Happy coding! 🚀"