#!/bin/bash
# Tmux Wizard - Unix TUI Module
# Minimal, keyboard-driven interface following Unix philosophy

# TUI State Management
TUI_STATE=""
TUI_SELECTION=0
TUI_OPTIONS=()
TUI_VALUES=()
declare -A TUI_CONFIG=()

# Initialize TUI
tui_init() {
    # Save terminal state
    stty -echo
    tput civis  # Hide cursor
    
    # Set up cleanup trap
    trap 'tui_cleanup' EXIT INT TERM
    
    # Initialize config
    TUI_CONFIG[session_name]=""
    TUI_CONFIG[project_type]=""
    TUI_CONFIG[project_method]=""
    TUI_CONFIG[template_theme]=""
    TUI_CONFIG[pane_count]="1"
}

# Cleanup TUI
tui_cleanup() {
    stty echo
    tput cnorm  # Show cursor
    clear
}

# Get terminal dimensions
get_terminal_size() {
    TERM_COLS=$(tput cols 2>/dev/null || echo 80)
    TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
}

# Center text in terminal
center_text() {
    local text="$1"
    local text_len=${#text}
    local padding=$(( (TERM_COLS - text_len) / 2 ))
    printf "%*s%s\n" $padding "" "$text"
}

# Draw menu items with consistent centering
draw_menu_items() {
    local -n options_ref=$1
    local -n descriptions_ref=$2  # Optional descriptions array
    local show_descriptions=${3:-false}
    
    for i in "${!options_ref[@]}"; do
        if [[ $i -eq $TUI_SELECTION ]]; then
            tput rev  # Reverse video
            if [[ "$show_descriptions" == "true" && -n "${descriptions_ref[$i]:-}" ]]; then
                center_text " > ${options_ref[$i]} - ${descriptions_ref[$i]} "
            else
                center_text " > ${options_ref[$i]} "
            fi
            tput sgr0
        else
            if [[ "$show_descriptions" == "true" && -n "${descriptions_ref[$i]:-}" ]]; then
                center_text "   ${options_ref[$i]} - ${descriptions_ref[$i]}"
            else
                center_text "   ${options_ref[$i]}"
            fi
        fi
    done
}

# Center colored text
center_colored_text() {
    local text="$1"
    # Strip ANSI codes for length calculation
    local clean_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#clean_text}
    local padding=$(( (TERM_COLS - text_len) / 2 ))
    printf "%*s" $padding ""
    echo -e "$text"
}

# Draw the current screen
tui_draw() {
    # Clear screen and move cursor to top-left
    tput clear
    tput cup 0 0
    
    get_terminal_size
    
    # Detect popup mode and adjust layout accordingly
    local is_popup_mode="${TMUX_WIZARD_POPUP:-}"
    
    if [[ -n "$is_popup_mode" ]]; then
        # Popup mode: minimal padding and compact header
        echo
        tput setaf 4; tput bold
        center_text " TMUX WIZARD"
        tput sgr0
        echo
    else
        # Normal mode: full header with vertical centering
        local vertical_padding=$(( (TERM_ROWS - 25) / 2 ))
        if [[ $vertical_padding -gt 0 ]]; then
            for ((i=0; i<vertical_padding; i++)); do
                echo
            done
        fi
        
        tput setaf 4; tput bold
        center_text "╭─── TMUX WIZARD ───╮"
        center_text "│    By: WillyV3    │"
        center_text "╰───────────────────╯"
        tput sgr0
        echo
    fi
    
    # Current config summary (only show when creating workspace)
    if [[ "$TUI_STATE" != "main" && "$TUI_STATE" != "session_list" ]]; then
        tui_show_config
        echo
    fi
    
    # Current menu
    case "$TUI_STATE" in
        "main") tui_draw_main_menu ;;
        "session_list") tui_draw_session_list ;;
        "session_name") tui_draw_session_name ;;
        "project_type") tui_draw_project_type ;;
        "nextjs_method") tui_draw_nextjs_method ;;
        "theme_select") tui_draw_theme_select ;;
        "template_select") tui_draw_template_select ;;
        "pane_config") tui_draw_pane_config ;;
        "pane_apps") tui_draw_pane_apps ;;
        "saved_sessions") tui_draw_saved_sessions ;;
        "confirm") tui_draw_confirm ;;
    esac
    
    # Footer - compact in popup mode
    echo
    tput setaf 8  # Gray color
    if [[ -n "${TMUX_WIZARD_POPUP:-}" ]]; then
        center_text "[↑↓] move  [Enter] select  [←] back  [q] quit"
    else
        center_text "[↑↓] move  [Enter] select  [←/h] back  [q] quit  [?] help"
    fi
    tput sgr0
}

# Show current configuration
tui_show_config() {
    tput setaf 2; tput bold  # Green bold
    center_text "┌─ Current Configuration ─┐"
    tput sgr0; tput setaf 2  # Green normal
    
    printf "%*s" $(( (TERM_COLS - 28) / 2 )) ""
    printf "│ Session: %-15s │\n" "${TUI_CONFIG[session_name]:-workspace}"
    
    printf "%*s" $(( (TERM_COLS - 28) / 2 )) ""
    printf "│ Type: %-18s │\n" "${TUI_CONFIG[project_type]:-none}"
    
    printf "%*s" $(( (TERM_COLS - 28) / 2 )) ""
    printf "│ Method: %-16s │\n" "${TUI_CONFIG[project_method]:-none}"
    
    printf "%*s" $(( (TERM_COLS - 28) / 2 )) ""
    printf "│ Theme: %-17s │\n" "${TUI_CONFIG[template_theme]:-none}"
    
    printf "%*s" $(( (TERM_COLS - 28) / 2 )) ""
    printf "│ Panes: %-17s │\n" "${TUI_CONFIG[pane_count]}"
    
    tput bold
    center_text "└──────────────────────────┘"
    tput sgr0
}

# Draw main menu
tui_draw_main_menu() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== What you doin? ==="
    tput sgr0
    echo
    
    TUI_OPTIONS=(
        "Current Running Sessions"
        "Create New Workspace"
        "Saved Sessions"
        "Quit"
    )
    
    local descriptions=(
        "Attach to existing tmux session"
        "Create a new development workspace"
        "Browse saved session configs & tmuxinator"
        "Exit tmux wizard"
    )
    
    local empty_descriptions=()
    draw_menu_items TUI_OPTIONS empty_descriptions false
    
    # Show description for selected item
    if [[ ${#descriptions[@]} -gt 0 && -n "${descriptions[$TUI_SELECTION]:-}" ]]; then
        echo
        tput setaf 8  # Gray for description
        center_text "${descriptions[$TUI_SELECTION]}"
        tput sgr0
    fi
}

# Draw session list menu
tui_draw_session_list() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Existing Sessions ==="
    tput sgr0
    echo
    
    # Get existing tmux sessions
    local sessions
    sessions=$(tmux list-sessions 2>/dev/null | cut -d: -f1)
    
    if [[ -z "$sessions" ]]; then
        center_text "No active sessions found"
        echo
        center_text "Press [←/h] to go back"
        TUI_OPTIONS=()
    else
        # Convert sessions to array
        TUI_OPTIONS=()
        while IFS= read -r session; do
            TUI_OPTIONS+=("$session")
        done <<< "$sessions"
        
        # Add back option
        TUI_OPTIONS+=("← Back to menu")
        
        local empty_descriptions=()
        draw_menu_items TUI_OPTIONS empty_descriptions false
    fi
}

# Draw session name input
tui_draw_session_name() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== New Workspace ==="
    tput sgr0
    echo
    
    center_text "First, Name Your Workspace"
    echo
    
    # Show current name with input prompt
    tput cnorm  # Show cursor
    center_text "Session name: ${TUI_CONFIG[session_name]:-workspace}"
    echo
    center_text "Press [Enter] to continue or type a new name"
    
    # This state will handle input differently
}

# Draw project type menu
tui_draw_project_type() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Project Type ==="
    tput sgr0
    echo
    
    TUI_OPTIONS=(
        "nextjs"
        "generic"
        "none"
    )
    
    local descriptions=(
        "Next.js with Shadcn/UI"
        "Generic project structure"
        "Just tmux session"
    )
    
    draw_menu_items TUI_OPTIONS descriptions true
}

# Draw Next.js method menu
tui_draw_nextjs_method() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Next.js Method ==="
    tput sgr0
    echo
    
    TUI_OPTIONS=(
        "create-next-app"
        "template"
    )
    
    local descriptions=(
        "Shadcn themes (recommended)"
        "Template library"
    )
    
    draw_menu_items TUI_OPTIONS descriptions true
}


# Draw pane configuration
tui_draw_pane_config() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Pane Count ==="
    tput sgr0
    echo
    
    TUI_OPTIONS=("1" "2" "3" "4" "5" "6")
    
    local descriptions=(
        "Single pane"
        "Side by side"
        "One left, two right"
        "2x2 grid"
        "Complex layout"
        "Grid layout"
    )
    
    draw_menu_items TUI_OPTIONS descriptions true
}

# Draw confirmation
tui_draw_confirm() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Create Workspace? ==="
    tput sgr0
    echo
    
    center_text "Ready to create:"
    center_text "  Session: ${TUI_CONFIG[session_name]}"
    center_text "  Type: ${TUI_CONFIG[project_type]}"
    if [[ "${TUI_CONFIG[project_type]}" == "nextjs" ]]; then
        center_text "  Method: ${TUI_CONFIG[project_method]}"
        center_text "  Theme: ${TUI_CONFIG[template_theme]}"
    fi
    center_text "  Panes: ${TUI_CONFIG[pane_count]}"
    echo
    
    TUI_OPTIONS=("Yes, create it" "No, go back")
    
    local empty_descriptions=()
    draw_menu_items TUI_OPTIONS empty_descriptions false
}

# Draw saved sessions menu
tui_draw_saved_sessions() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Saved Sessions ==="
    tput sgr0
    echo
    
    # Find saved session scripts and tmuxinator configs
    local saved_scripts=()
    local tmuxinator_configs=()
    
    # Get saved session scripts
    if [[ -d "/home/wv3/tmux-scripts/views" ]]; then
        while IFS= read -r script; do
            local basename=$(basename "$script" .sh)
            saved_scripts+=("📜 $basename")
        done < <(find "/home/wv3/tmux-scripts/views" -name "*.sh" -type f 2>/dev/null)
    fi
    
    # Get tmuxinator configs
    if [[ -d "$HOME/.config/tmuxinator" ]]; then
        while IFS= read -r config; do
            local basename=$(basename "$config" .yml)
            tmuxinator_configs+=("🔧 $basename")
        done < <(find "$HOME/.config/tmuxinator" -name "*.yml" -type f 2>/dev/null)
    fi
    
    # Combine all options
    TUI_OPTIONS=()
    TUI_OPTIONS+=("${saved_scripts[@]}")
    TUI_OPTIONS+=("${tmuxinator_configs[@]}")
    TUI_OPTIONS+=("← Back to menu")
    
    if [[ ${#TUI_OPTIONS[@]} -eq 1 ]]; then
        center_text "No saved sessions or tmuxinator configs found"
        echo
        center_text "Create some sessions first, then save them for reuse"
    else
        local empty_descriptions=()
        draw_menu_items TUI_OPTIONS empty_descriptions false
    fi
}

# Handle keyboard input
tui_handle_input() {
    # No special handling needed - let normal input flow handle it
    
    local key
    read -rsn1 key
    
    # Handle escape sequences (arrow keys)
    if [[ "$key" == $'\e' ]]; then
        read -rsn2 key
        case "$key" in
            '[A') # Up arrow
                if [[ ${#TUI_OPTIONS[@]} -gt 0 ]]; then
                    TUI_SELECTION=$(((TUI_SELECTION - 1 + ${#TUI_OPTIONS[@]}) % ${#TUI_OPTIONS[@]}))
                fi
                ;;
            '[B') # Down arrow
                if [[ ${#TUI_OPTIONS[@]} -gt 0 ]]; then
                    TUI_SELECTION=$(((TUI_SELECTION + 1) % ${#TUI_OPTIONS[@]}))
                fi
                ;;
            '[D') # Left arrow (back)
                tui_go_back
                ;;
        esac
    else
        case "$key" in
            'h'|'b') # Back
                tui_go_back
                ;;
            'q') # Quit
                exit 0
                ;;
            '?') # Help
                tui_show_help
                ;;
            '') # Enter
                tui_handle_selection
                ;;
        esac
    fi
}

# Handle current selection
tui_handle_selection() {
    case "$TUI_STATE" in
        "main")
            case "$TUI_SELECTION" in
                0) tui_set_state "session_list" ;;  # Open Running Session
                1) 
                    # Create New Workspace - directly edit name then go to project type
                    tui_edit_session_name
                    tui_set_state "project_type"
                    ;;
                2) tui_set_state "saved_sessions" ;;  # Saved Sessions
                3) exit 0 ;;                          # Quit
            esac
            ;;
        "session_list")
            if [[ ${#TUI_OPTIONS[@]} -eq 0 ]]; then
                # No sessions, just go back
                tui_set_state "main"
            elif [[ "${TUI_OPTIONS[$TUI_SELECTION]}" == "← Back to menu" ]]; then
                tui_set_state "main"
            else
                # Attach to selected session
                local selected_session="${TUI_OPTIONS[$TUI_SELECTION]}"
                tui_cleanup
                # Attach to session
                if [[ -n "$TMUX" ]]; then
                    tmux switch-client -t "$selected_session"
                else
                    tmux attach-session -t "$selected_session"
                fi
                exit 0
            fi
            ;;
        "session_name")
            # This state is no longer used - directly edit name from main menu
            ;;
        "project_type")
            TUI_CONFIG[project_type]="${TUI_OPTIONS[$TUI_SELECTION]}"
            if [[ "${TUI_OPTIONS[$TUI_SELECTION]}" == "nextjs" ]]; then
                tui_set_state "nextjs_method"
            else
                # Go directly to pane config for non-nextjs projects
                tui_set_state "pane_config"
            fi
            ;;
        "nextjs_method")
            TUI_CONFIG[project_method]="${TUI_OPTIONS[$TUI_SELECTION]}"
            if [[ "${TUI_OPTIONS[$TUI_SELECTION]}" == "create-next-app" ]]; then
                tui_set_state "theme_select"
            else
                # For template method, go to template selection state
                tui_set_state "template_select"
            fi
            ;;
        "theme_select")
            # User pressed Enter - do theme selection
            tui_select_theme
            tui_set_state "pane_config"
            ;;
        "template_select")
            # User pressed Enter - do template selection
            tui_select_template
            tui_set_state "pane_config"
            ;;
        "pane_apps")
            # User pressed Enter - do pane app configuration
            tui_configure_pane_apps
            # Note: tui_configure_pane_apps handles its own state transitions
            ;;
        "saved_sessions")
            local selected_session="${TUI_OPTIONS[$TUI_SELECTION]}"
            if [[ "$selected_session" == "← Back to menu" ]]; then
                tui_set_state "main"
            else
                tui_launch_saved_session "$selected_session"
            fi
            ;;
        "pane_config")
            TUI_CONFIG[pane_count]="${TUI_OPTIONS[$TUI_SELECTION]}"
            if [[ "${TUI_OPTIONS[$TUI_SELECTION]}" == "1" ]]; then
                # Single pane - go directly to confirm
                tui_set_state "confirm"
            else
                # Multiple panes - configure apps for each pane
                tui_set_state "pane_apps"
            fi
            ;;
        "confirm")
            if [[ $TUI_SELECTION -eq 0 ]]; then
                tui_create_workspace
            else
                tui_set_state "pane_config"
            fi
            ;;
    esac
}

# Edit session name
tui_edit_session_name() {
    clear
    # Enable normal terminal input
    stty echo
    tput cnorm  # Show cursor
    
    echo
    echo
    center_text "Enter Session Name"
    echo
    printf "%*s" $(( (TERM_COLS - 20) / 2 )) ""
    printf "Name: "
    read -r new_name
    TUI_CONFIG[session_name]="${new_name:-workspace}"
    
    # Return to TUI mode
    stty -echo
    tput civis  # Hide cursor
}

# Select template using direct file access (no complex template manager)
tui_select_template() {
    # Clear screen and enable normal terminal input
    clear
    stty echo
    tput cnorm
    
    # Direct template selection without complex template manager
    local templates_file="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/data/curated-templates.txt"
    local selected_template
    
    if [[ -f "$templates_file" ]]; then
        # Extract just the template names and descriptions, skip section headers
        selected_template=$(grep " | " "$templates_file" | \
            fzf --prompt="Select template: " \
                --height=15 \
                --border \
                --header="Next.js Templates from curated list")
        
        if [[ -n "$selected_template" ]]; then
            # Extract template name (before the |)
            local template_name=$(echo "$selected_template" | awk -F' | ' '{print $1}' | sed 's/^[[:space:]]*//')
            TUI_CONFIG[template_theme]="$template_name"
            print_success "Selected template: $template_name"
            sleep 0.5
        fi
    else
        print_error "Templates file not found: $templates_file"
        sleep 1
    fi
    
    # Clear screen for clean transition
    clear
    
    # Return to TUI mode
    stty -echo
    tput civis
}

# Draw theme selection screen
tui_draw_theme_select() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Select Shadcn Theme ==="
    tput sgr0
    echo
    
    center_text "Press [Enter] to browse available themes"
    echo
    center_text "Themes will be loaded dynamically from"
    center_text "the Next.js creation script"
}

# Draw template selection screen  
tui_draw_template_select() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Select Next.js Template ==="
    tput sgr0
    echo
    
    center_text "Press [Enter] to browse template library"
    echo
    center_text "Templates include popular starters, SaaS boilerplates,"
    center_text "authentication examples, and specialized applications"
}

# Draw pane apps configuration screen  
tui_draw_pane_apps() {
    tput setaf 3; tput bold  # Yellow bold
    center_text "=== Configure Pane Applications ==="
    tput sgr0
    echo
    
    center_text "Press [Enter] to configure applications"
    center_text "for each of the ${TUI_CONFIG[pane_count]} panes"
    echo
    center_text "You'll select what runs in each pane:"
    center_text "Claude Code, Terminal, VS Code, Dev Server, etc."
}

# Configure applications for each pane
tui_configure_pane_apps() {
    # Initialize pane arrays if not set
    if [[ -z "${TUI_CONFIG[pane_apps]}" ]]; then
        TUI_CONFIG[pane_apps]=""
        TUI_CONFIG[pane_index]=1
    fi
    
    local current_pane=${TUI_CONFIG[pane_index]:-1}
    local pane_count=${TUI_CONFIG[pane_count]:-1}
    
    if [[ $current_pane -gt $pane_count ]]; then
        # Done configuring all panes
        tui_set_state "confirm"
        return
    fi
    
    clear
    stty echo
    tput cnorm
    
    echo
    center_text "=== Pane $current_pane of $pane_count ==="
    echo
    center_text "Select application for this pane:"
    echo
    
    local app_options="1|Claude Code (AI Assistant)
2|Terminal (Command Line)
3|Code Editor (VS Code)
4|Development Server
5|Git Status
6|File Manager
7|System Monitor
8|Documentation
9|Testing
10|Build/Deploy"
    
    local selected
    selected=$(echo -e "$app_options" | fzf --prompt="Pane $current_pane: " --height=12 --border --header="Select application for this pane")
    
    if [[ -n "$selected" ]]; then
        local choice=$(echo "$selected" | cut -d'|' -f1)
        local app_name=$(echo "$selected" | cut -d'|' -f2)
        
        # Store the selection
        if [[ -z "${TUI_CONFIG[pane_apps]}" ]]; then
            TUI_CONFIG[pane_apps]="$choice"
        else
            TUI_CONFIG[pane_apps]="${TUI_CONFIG[pane_apps]},$choice"
        fi
        
        print_success "Pane $current_pane: $app_name"
        sleep 0.5
        
        # Move to next pane
        TUI_CONFIG[pane_index]=$((current_pane + 1))
        
        # Continue or finish
        if [[ $((current_pane + 1)) -le $pane_count ]]; then
            tui_configure_pane_apps  # Recursive call for next pane
        else
            tui_set_state "confirm"
        fi
    else
        # User cancelled - go back to pane config
        tui_set_state "pane_config"
    fi
    
    stty -echo
    tput civis
}

# Launch a saved session or tmuxinator config
tui_launch_saved_session() {
    local session_name="$1"
    tui_cleanup
    
    # Enable normal terminal output
    stty echo
    tput cnorm
    
    if [[ "$session_name" == 📜* ]]; then
        # Saved session script
        local script_name="${session_name#📜 }"
        local script_path="/home/wv3/tmux-scripts/views/${script_name}.sh"
        
        if [[ -f "$script_path" ]]; then
            print_info "Launching saved session: $script_name"
            echo "Press any key to continue or Ctrl+C to cancel..."
            read -rsn1
            
            # Execute the saved session script
            bash "$script_path"
            exit 0
        else
            print_error "Script not found: $script_path"
            sleep 2
            tui_set_state "saved_sessions"
        fi
    elif [[ "$session_name" == 🔧* ]]; then
        # Tmuxinator config
        local config_name="${session_name#🔧 }"
        
        if command -v tmuxinator &> /dev/null; then
            print_info "Launching tmuxinator session: $config_name"
            echo "Press any key to continue or Ctrl+C to cancel..."
            read -rsn1
            
            # Launch tmuxinator session
            tmuxinator start "$config_name"
            exit 0
        else
            print_error "tmuxinator not found. Install with: gem install tmuxinator"
            sleep 2
            tui_set_state "saved_sessions"
        fi
    else
        print_error "Unknown session type: $session_name"
        sleep 2
        tui_set_state "saved_sessions"
    fi
}

# Get themes from Next.js script and select with fzf  
tui_select_theme() {
    local script_path="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/scripts/create-nextjs-shadcn.sh"
    
    # Clear screen and enable normal terminal input
    clear
    tput cnorm
    stty echo
    
    # Extract themes from the Next.js script
    local themes="default"
    if [[ -f "$script_path" ]]; then
        # Extract theme names from lines 16-21 of the script
        local extracted_themes
        extracted_themes=$(sed -n '16,21p' "$script_path" | \
            grep -o '[a-z][a-z0-9-]*[a-z0-9]' | \
            grep -v echo | \
            sort -u)
        themes="$themes
$extracted_themes"
    fi
    
    local selected
    selected=$(echo "$themes" | fzf --prompt="Select theme: " --height=15 --border --header="Shadcn themes from tweakcn.com")
    
    if [[ -n "$selected" ]]; then
        TUI_CONFIG[template_theme]="$selected"
        print_success "Selected theme: $selected"
        sleep 0.5
    fi
    
    # Clear screen for clean transition
    clear
    
    stty -echo
    tput civis
}

# Set TUI state
tui_set_state() {
    TUI_STATE="$1"
    TUI_SELECTION=0
}

# Go back
tui_go_back() {
    case "$TUI_STATE" in
        "session_list"|"session_name") tui_set_state "main" ;;
        "saved_sessions") tui_set_state "main" ;;
        "project_type") tui_set_state "main" ;;
        "nextjs_method") tui_set_state "project_type" ;;
        "theme_select") tui_set_state "nextjs_method" ;;
        "template_select") tui_set_state "nextjs_method" ;;
        "pane_config") tui_set_state "project_type" ;;
        "pane_apps") tui_set_state "pane_config" ;;
        "confirm") 
            if [[ ${TUI_CONFIG[pane_count]} -eq 1 ]]; then
                tui_set_state "pane_config"
            else
                tui_set_state "pane_apps"
            fi
            ;;
        "main") exit 0 ;;
    esac
}

# Show help
tui_show_help() {
    clear
    get_terminal_size
    
    # Center the help text
    local help_text="╭─── TMUX WIZARD HELP ───╮
│                        │
│ ↑↓      Move up/down   │
│ Enter   Select option  │
│ ←, h    Go back        │
│ f       Full list      │
│ q       Quit           │
│ ?       This help      │
│                        │
│ Unix philosophy:       │
│ - Minimal interface    │
│ - Keyboard driven      │
│ - Do one thing well    │
│                        │
╰────────────────────────╯

Press any key to continue..."
    
    # Add vertical padding
    local vertical_padding=$(( (TERM_ROWS - 20) / 2 ))
    if [[ $vertical_padding -gt 0 ]]; then
        printf "%${vertical_padding}s" | tr ' ' '\n'
    fi
    
    # Print each line centered
    while IFS= read -r line; do
        center_text "$line"
    done <<< "$help_text"
    
    read -rsn1
}

# Create the workspace
tui_create_workspace() {
    # Only cleanup immediately if not in popup mode
    if [[ -z "${TMUX_WIZARD_POPUP:-}" ]]; then
        tui_cleanup
    fi
    
    # Export config for main script
    export SESSION_NAME="${TUI_CONFIG[session_name]}"
    export PROJECT_TYPE="${TUI_CONFIG[project_type]}" 
    export PROJECT_METHOD="${TUI_CONFIG[project_method]}"
    export TEMPLATE_OR_THEME="${TUI_CONFIG[template_theme]}"
    export PANE_COUNT="${TUI_CONFIG[pane_count]}"
    
    # Call the actual creation logic
    echo "Creating workspace with configuration:"
    echo "  Session: $SESSION_NAME"
    echo "  Type: $PROJECT_TYPE"
    echo "  Method: $PROJECT_METHOD" 
    echo "  Theme: $TEMPLATE_OR_THEME"
    echo "  Panes: $PANE_COUNT"
    echo
    
    # Create project if needed (using library modules directly)
    if [[ "$PROJECT_TYPE" != "generic" ]] && [[ -n "$TEMPLATE_OR_THEME" ]]; then
        # Enable normal terminal output for external scripts
        stty echo
        tput cnorm
        
        print_info "Creating $PROJECT_TYPE project..."
        if ! create_project "$PROJECT_TYPE" "$SESSION_NAME" "$PROJECT_METHOD" "$TEMPLATE_OR_THEME"; then
            print_error "Failed to create project"
            echo "Press any key to continue..."
            read -rsn1
            exit 1
        fi
        WORKING_DIR=$(get_working_dir)
    else
        WORKING_DIR="$HOME"
    fi
    
    # Convert pane apps to names and commands
    local -a PANE_NAMES=()
    local -a PANE_COMMANDS=()
    
    if [[ $PANE_COUNT -eq 1 ]]; then
        PANE_NAMES=("Main")
        case "$PROJECT_TYPE" in
            "nextjs")
                PANE_COMMANDS=("cd '$WORKING_DIR' && npm run dev")
                ;;
            *)
                PANE_COMMANDS=("cd '$WORKING_DIR'")
                ;;
        esac
    else
        # Parse pane app selections
        IFS=',' read -ra app_choices <<< "${TUI_CONFIG[pane_apps]}"
        for i in "${!app_choices[@]}"; do
            local choice="${app_choices[$i]}"
            case "$choice" in
                1) PANE_NAMES[$i]="Claude-Code"; PANE_COMMANDS[$i]="cd '$WORKING_DIR' && claude" ;;
                2) PANE_NAMES[$i]="Terminal"; PANE_COMMANDS[$i]="cd '$WORKING_DIR'" ;;
                3) PANE_NAMES[$i]="Editor"; PANE_COMMANDS[$i]="cd '$WORKING_DIR' && code ." ;;
                4) PANE_NAMES[$i]="Dev-Server"
                   if [[ "$PROJECT_TYPE" == "nextjs" ]]; then
                       PANE_COMMANDS[$i]="cd '$WORKING_DIR' && npm run dev"
                   else
                       PANE_COMMANDS[$i]="cd '$WORKING_DIR' && echo 'Start your development server here'"
                   fi ;;
                5) PANE_NAMES[$i]="Git"; PANE_COMMANDS[$i]="cd '$WORKING_DIR' && git status" ;;
                6) PANE_NAMES[$i]="Files"; PANE_COMMANDS[$i]="cd '$WORKING_DIR' && ls -la" ;;
                7) PANE_NAMES[$i]="Monitor"; PANE_COMMANDS[$i]="htop" ;;
                8) PANE_NAMES[$i]="Docs"; PANE_COMMANDS[$i]="cd '$WORKING_DIR' && echo 'Documentation and notes'" ;;
                9) PANE_NAMES[$i]="Tests"; PANE_COMMANDS[$i]="cd '$WORKING_DIR' && echo 'Run tests here'" ;;
                10) PANE_NAMES[$i]="Build"; PANE_COMMANDS[$i]="cd '$WORKING_DIR' && echo 'Build and deploy'" ;;
                *) PANE_NAMES[$i]="Terminal"; PANE_COMMANDS[$i]="cd '$WORKING_DIR'" ;;
            esac
        done
    fi
    
    # Create the tmux workspace (using library modules directly)  
    print_info "Creating tmux workspace..."
    if ! create_workspace "$SESSION_NAME" "$WORKING_DIR" "$PANE_COUNT" "${PANE_NAMES[@]}"; then
        print_error "Failed to create tmux workspace"
        echo "Press any key to continue..."
        read -rsn1
        exit 1
    fi
    
    
    # Setup pane commands
    for i in "${!PANE_COMMANDS[@]}"; do
        if [[ -n "${PANE_COMMANDS[$i]}" ]]; then
            execute_in_pane "$SESSION_NAME" "$i" "${PANE_COMMANDS[$i]}"
        fi
    done
    
    # Show completion message
    clear
    echo
    print_success "🚀 Workspace '$SESSION_NAME' created successfully!"
    print_info "Working directory: $WORKING_DIR"
    print_info "Panes: $PANE_COUNT"
    echo
    
    # Attach to the session
    print_info "Attaching to session..."
    sleep 1
    attach_to_session "$SESSION_NAME"
}

# Main TUI loop
tui_main() {
    tui_init
    tui_set_state "main"
    
    # Set defaults
    TUI_CONFIG[session_name]="workspace"
    TUI_CONFIG[project_type]="none"
    TUI_CONFIG[template_theme]="default"
    TUI_CONFIG[pane_count]="1"
    
    while true; do
        tui_draw
        tui_handle_input
        # Small delay to reduce flicker
        sleep 0.05
    done
}
