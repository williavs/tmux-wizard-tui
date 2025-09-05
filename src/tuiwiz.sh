#!/bin/bash
# Tmux Wizard - TUI Edition
# Unix-style text interface

set -e

# Script directory and module loading
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Load modules
source "$LIB_DIR/ui.sh"
source "$LIB_DIR/tui.sh"
source "$LIB_DIR/tmux-manager.sh"
source "$LIB_DIR/project-manager.sh"
source "$LIB_DIR/template-manager.sh"

# Check if we're in a terminal that supports TUI
check_tui_support() {
    if [[ ! -t 0 || ! -t 1 ]]; then
        print_error "TUI mode requires interactive terminal"
        exit 1
    fi
    
    if ! command -v tput >/dev/null 2>&1; then
        print_error "TUI mode requires 'tput' command"
        exit 1
    fi
}

# Parse minimal args
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    cat << 'EOF'
Tmux Wizard TUI - Unix-style text interface

Usage: tuiwiz

A minimal, keyboard-driven interface:
  ↑↓      Navigate up/down (arrow keys)
  Enter   Select option  
  ←/h     Go back
  f       Full selection (where available)
  q       Quit
  ?       Help

Pure Unix philosophy - minimal, focused, keyboard-driven.
Responsive design - centers content in terminal.
EOF
    exit 0
fi

if [[ "$1" == "--version" || "$1" == "-v" ]]; then
    echo "Tmux Wizard TUI v2.0.0"
    exit 0
fi

# Main execution
main() {
    check_tui_support
    
    # Validate required tools
    validate_commands "tmux" || exit 1
    
    # Run TUI
    tui_main
}

main "$@"