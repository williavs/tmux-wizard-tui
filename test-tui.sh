#!/bin/bash
# Test script for the updated TUI

# Source the required modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/tui.sh"
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/tmux-manager.sh"
source "$SCRIPT_DIR/lib/project-manager.sh"
source "$SCRIPT_DIR/lib/template-manager.sh"

# Override the create function to show what would be created
tui_create_workspace() {
    tui_cleanup
    
    # Export config for main script
    export SESSION_NAME="${TUI_CONFIG[session_name]}"
    export PROJECT_TYPE="${TUI_CONFIG[project_type]}" 
    export PROJECT_METHOD="${TUI_CONFIG[project_method]}"
    export TEMPLATE_OR_THEME="${TUI_CONFIG[template_theme]}"
    export PANE_COUNT="${TUI_CONFIG[pane_count]}"
    
    # Show what would be created
    echo "====================================="
    echo "Workspace Configuration:"
    echo "====================================="
    echo "  Session: $SESSION_NAME"
    echo "  Type: $PROJECT_TYPE"
    [[ -n "$PROJECT_METHOD" ]] && echo "  Method: $PROJECT_METHOD" 
    [[ -n "$TEMPLATE_OR_THEME" ]] && echo "  Theme: $TEMPLATE_OR_THEME"
    echo "  Panes: $PANE_COUNT"
    echo "====================================="
    echo
    echo "In production, this would:"
    echo "1. Create tmux session '$SESSION_NAME' with $PANE_COUNT panes"
    
    if [[ "$PROJECT_TYPE" == "nextjs" ]]; then
        echo "2. Create Next.js project using $PROJECT_METHOD"
        if [[ "$PROJECT_METHOD" == "create-next-app" ]]; then
            echo "3. Apply theme: $TEMPLATE_OR_THEME"
        fi
    elif [[ "$PROJECT_TYPE" == "generic" ]]; then
        echo "2. Set up generic project structure"
    fi
    
    echo "4. Configure development environment"
    echo "5. Attach to the tmux session"
    echo
    
    exit 0
}

# Start the TUI
echo "Starting Tmux Wizard TUI (Simplified Version)"
echo "=============================================="
echo
echo "Features:"
echo "  - Two main options: Open existing session or create new"
echo "  - Streamlined workflow for workspace creation"
echo "  - Full configuration flow behind 'Create New Workspace'"
echo
echo "Press any key to start..."
read -n1 -s

# Launch the TUI
tui_main