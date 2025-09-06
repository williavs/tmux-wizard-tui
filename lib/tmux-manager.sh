#!/bin/bash
# Tmux Wizard - Tmux Management Module
# Handles tmux session creation, layout management, and pane operations

# Source UI functions for error handling and output
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# Global variables that will be set by the main script
SESSION_NAME=""
WORKING_DIR=""
PANE_COUNT=1

# Set session variables (called by main script)
set_session_vars() {
    SESSION_NAME="$1"
    WORKING_DIR="$2" 
    PANE_COUNT="${3:-1}"
}

# Check if tmux is available
check_tmux_available() {
    if ! command -v tmux >/dev/null 2>&1; then
        print_error "tmux is not installed. Please install tmux to use this tool."
        return 1
    fi
    
    # Check tmux version (should be 2.0+)
    local tmux_version
    tmux_version=$(tmux -V | cut -d' ' -f2)
    if [[ $(echo "$tmux_version" | cut -d'.' -f1) -lt 2 ]]; then
        print_warning "tmux version $tmux_version detected. Some features may not work properly."
        print_info "Consider upgrading to tmux 2.0 or later"
    fi
    
    return 0
}

# Check if session exists
session_exists() {
    local session_name="$1"
    tmux has-session -t "$session_name" 2>/dev/null
}

# Kill existing session
kill_existing_session() {
    local session_name="$1"
    
    if session_exists "$session_name"; then
        if confirm_action "Session '$session_name' already exists. Kill it and create a new one?"; then
            tmux kill-session -t "$session_name" 2>/dev/null || true
            print_success "Killed existing session: $session_name"
            return 0
        else
            return 1  # User chose not to kill existing session
        fi
    fi
    
    return 0  # Session doesn't exist, no need to kill
}

# Create split layout based on pane count
create_split_layout() {
    local pane_count="$1"
    local session_name="$2"
    local working_dir="$3"
    
    if [[ -z "$session_name" || -z "$working_dir" ]]; then
        print_error "create_split_layout requires session_name and working_dir"
        return 1
    fi
    
    case $pane_count in
        2)
            # Split horizontally (side by side)
            tmux split-window -h -t "$session_name:0" -c "$working_dir"
            ;;
        3)
            # One big pane on left, two stacked on right
            tmux split-window -h -t "$session_name:0" -c "$working_dir"
            tmux split-window -v -t "$session_name:0.1" -c "$working_dir"
            ;;
        4)
            # 2x2 grid
            tmux split-window -h -t "$session_name:0" -c "$working_dir"
            tmux split-window -v -t "$session_name:0.0" -c "$working_dir"
            tmux split-window -v -t "$session_name:0.2" -c "$working_dir"
            ;;
        5)
            # Top row with 3, bottom row with 2
            tmux split-window -v -t "$session_name:0" -c "$working_dir"
            tmux split-window -h -t "$session_name:0.0" -c "$working_dir"
            tmux split-window -h -t "$session_name:0.1" -c "$working_dir"
            tmux split-window -h -t "$session_name:0.3" -c "$working_dir"
            ;;
        6)
            # 3x2 grid
            tmux split-window -v -t "$session_name:0" -c "$working_dir"
            tmux split-window -h -t "$session_name:0.0" -c "$working_dir"
            tmux split-window -h -t "$session_name:0.1" -c "$working_dir"
            tmux split-window -h -t "$session_name:0.3" -c "$working_dir"
            tmux split-window -h -t "$session_name:0.4" -c "$working_dir"
            ;;
        7|8|9|10)
            # Use tiled layout for 7+ panes
            for (( i=1; i<pane_count; i++ )); do
                tmux split-window -t "$session_name:0" -c "$working_dir"
                tmux select-layout -t "$session_name:0" tiled
            done
            ;;
        *)
            print_warning "Unsupported pane count: $pane_count. Using single pane."
            ;;
    esac
}

# Create new tmux session
create_tmux_session() {
    local session_name="$1"
    local working_dir="$2"
    local window_name="${3:-Multi-View}"
    
    print_info "Creating tmux session '$session_name'..."
    
    # Validate inputs
    if [[ -z "$session_name" ]]; then
        print_error "Session name is required"
        return 1
    fi
    
    if [[ -z "$working_dir" ]]; then
        print_error "Working directory is required"
        return 1
    fi
    
    if [[ ! -d "$working_dir" ]]; then
        print_error "Working directory does not exist: $working_dir"
        return 1
    fi
    
    # Create the session
    if ! tmux new-session -d -s "$session_name" -n "$window_name" -c "$working_dir"; then
        print_error "Failed to create tmux session '$session_name'"
        return 1
    fi
    
    print_success "Created tmux session: $session_name"
    return 0
}

# Set up pane titles and borders
setup_pane_display() {
    local session_name="$1"
    
    # Enable pane borders and titles
    tmux set -t "$session_name" pane-border-status top 2>/dev/null || true
    tmux set -t "$session_name" pane-border-format " #{pane_title} " 2>/dev/null || true
    
    print_info "Configured pane display for session: $session_name"
}

# Set pane title
set_pane_title() {
    local session_name="$1"
    local pane_index="$2"
    local title="$3"
    
    tmux select-pane -t "$session_name:0.$pane_index" -T "$title" 2>/dev/null || true
}

# Execute command in specific pane
execute_in_pane() {
    local session_name="$1"
    local pane_index="$2"
    local command="$3"
    
    tmux send-keys -t "$session_name:0.$pane_index" "$command" C-m
}

# Setup pane commands and titles
setup_panes() {
    local session_name="$1"
    local -a pane_names=("${@:2}")  # Array of pane names
    local -a pane_commands=("${@:$((2 + ${#pane_names[@]}))}")  # Array of commands
    
    for i in "${!pane_names[@]}"; do
        local pane_index="$i"
        local pane_name="${pane_names[$i]}"
        local pane_command="${pane_commands[$i]:-}"
        
        # Set pane title
        set_pane_title "$session_name" "$pane_index" "$pane_name"
        
        # Execute command if provided
        if [[ -n "$pane_command" ]]; then
            execute_in_pane "$session_name" "$pane_index" "$pane_command"
        fi
    done
}

# Attach to session or switch client
attach_to_session() {
    local session_name="$1"
    
    # Select first pane
    tmux select-pane -t "$session_name:0.0" 2>/dev/null || true
    
    # Check if we're already in tmux
    if [[ -n "$TMUX" ]]; then
        print_info "Switching to session: $session_name"
        
        # If in popup mode, we need to handle the switch differently
        if [[ -n "${TMUX_WIZARD_POPUP:-}" ]]; then
            # Get the parent session/client before popup closes
            local parent_session=$(tmux display-message -p '#S' 2>/dev/null)
            # Close popup first, then switch from parent session
            sleep 0.2  # Brief delay to ensure popup closes
            tmux switch-client -t "$session_name"
        else
            tmux switch-client -t "$session_name"
        fi
    else
        print_info "Attaching to session: $session_name"
        tmux attach-session -t "$session_name"
    fi
}

# List existing sessions
list_sessions() {
    if ! tmux list-sessions 2>/dev/null; then
        print_info "No active tmux sessions found"
        return 1
    fi
}

# Show session selection menu
select_existing_session() {
    local sessions
    sessions=$(tmux list-sessions 2>/dev/null | cut -d: -f1)
    
    if [[ -z "$sessions" ]]; then
        print_info "No existing sessions found"
        return 1
    fi
    
    print_color $GREEN "Active tmux sessions:"
    echo "$sessions" | nl -w2 -s') '
    
    local selected
    selected=$(echo "$sessions" | select_with_fzf "Select session:" "$sessions" 10 "Select existing session to attach")
    
    if [[ -n "$selected" ]]; then
        attach_to_session "$selected"
        return 0
    else
        return 1
    fi
}

# Create complete workspace with layout and commands
create_workspace() {
    local session_name="$1"
    local working_dir="$2"
    local pane_count="${3:-1}"
    local -a pane_names=("${@:4}")
    
    # Validate tmux availability
    if ! check_tmux_available; then
        return 1
    fi
    
    # Handle existing session
    if ! kill_existing_session "$session_name"; then
        print_info "Cancelled by user"
        return 1
    fi
    
    # Create the session
    if ! create_tmux_session "$session_name" "$working_dir"; then
        return 1
    fi
    
    # Create split layout if multiple panes
    if [[ $pane_count -gt 1 ]]; then
        if ! create_split_layout "$pane_count" "$session_name" "$working_dir"; then
            print_error "Failed to create split layout"
            return 1
        fi
        print_success "Created $pane_count pane layout"
    fi
    
    # Setup pane display
    setup_pane_display "$session_name"
    
    # Setup pane titles if provided
    if [[ ${#pane_names[@]} -gt 0 ]]; then
        for i in "${!pane_names[@]}"; do
            set_pane_title "$session_name" "$i" "${pane_names[$i]}"
        done
    fi
    
    print_success "Workspace '$session_name' created successfully!"
    return 0
}

# Show helpful tmux key bindings
show_tmux_help() {
    section_header "Tmux Key Bindings"
    
    print_color $GREEN "Navigation:"
    echo "  Ctrl+b → Arrow keys : Navigate between panes"
    echo "  Ctrl+b z           : Zoom/unzoom current pane"
    echo "  Ctrl+b space       : Cycle through layouts"
    echo ""
    
    print_color $GREEN "Session Management:"
    echo "  Ctrl+b d           : Detach from session"
    echo "  Ctrl+b s           : List sessions"
    echo "  Ctrl+b $           : Rename session"
    echo ""
    
    print_color $GREEN "Pane Management:"
    echo "  Ctrl+b %           : Split horizontally"
    echo "  Ctrl+b \"           : Split vertically"
    echo "  Ctrl+b x           : Close pane"
    echo "  Ctrl+b !           : Break pane into window"
    echo ""
    
    print_info "For more help: man tmux"
}