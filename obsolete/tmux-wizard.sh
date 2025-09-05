#!/bin/bash
# Tmux Wizard - Modern Development Environment Orchestrator
# Version: 2.0 (Refactored)

set -e  # Exit on any error

# Script directory and module loading
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

# Load all modules
for module in "$LIB_DIR"/*.sh; do
    if [[ -f "$module" ]]; then
        source "$module"
    fi
done

# Global variables
VERSION="2.0.0"
SESSION_NAME="${SESSION_NAME:-}"
PROJECT_TYPE="${PROJECT_TYPE:-generic}"
PROJECT_METHOD="${PROJECT_METHOD:-template}"
TEMPLATE_OR_THEME="${TEMPLATE_OR_THEME:-}"
WORKING_DIR=""
PANE_COUNT="${PANE_COUNT:-1}"

# Application choices for panes
declare -a PANE_NAMES=()
declare -a PANE_COMMANDS=()

# Show banner
show_banner() {
    section_header "TMUX WORKSPACE WIZARD v$VERSION"
    print_color $BLUE "🧙‍♂️ Modern Development Environment Orchestrator"
    echo
}

# Show help
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help              Show this help message
    -v, --version           Show version information
    -s, --session NAME      Set session name
    -t, --type TYPE         Set project type (nextjs, generic)
    -p, --panes COUNT       Set number of panes (1-10)
    --list-templates        List available templates
    --debug                 Enable debug mode

Examples:
    $(basename "$0")                    # Interactive mode
    $(basename "$0") -s myproject       # Create session 'myproject'
    $(basename "$0") -t nextjs -p 3     # Next.js project with 3 panes

Project Types:
    nextjs      Next.js application with Shadcn/UI
    generic     Generic project structure

For more information: https://github.com/yourusername/tmux-wizard
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "Tmux Wizard v$VERSION"
                exit 0
                ;;
            -s|--session)
                SESSION_NAME="$2"
                shift 2
                ;;
            -t|--type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            -p|--panes)
                PANE_COUNT="$2"
                shift 2
                ;;
            --list-templates)
                init_template_system
                get_available_templates "curated"
                exit 0
                ;;
            --debug)
                set -x
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                print_info "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Check existing sessions and offer to attach
check_existing_sessions() {
    local existing_sessions
    existing_sessions=$(tmux list-sessions 2>/dev/null | cut -d: -f1 || echo "")
    
    if [[ -n "$existing_sessions" ]]; then
        print_color $GREEN "Active tmux sessions:"
        echo "$existing_sessions" | nl -w2 -s') '
        echo
        
        if confirm_action "Attach to existing session instead?"; then
            local selected
            selected=$(echo "$existing_sessions" | select_with_fzf "Select session:" "$existing_sessions")
            if [[ -n "$selected" ]]; then
                attach_to_session "$selected"
                exit 0
            fi
        fi
    fi
}

# Ask if creating new app
ask_new_app() {
    if [[ -z "$SESSION_NAME" ]]; then
        return 1  # Can't create new app without session name
    fi
    
    if confirm_action "Is this a new app/project?"; then
        return 0
    else
        return 1
    fi
}

# Get session name from user
get_session_name() {
    if [[ -n "$SESSION_NAME" ]]; then
        return 0  # Already set via command line
    fi
    
    print_color $YELLOW "Enter session/project name (default: workspace):"
    read -r SESSION_NAME
    SESSION_NAME=${SESSION_NAME:-workspace}
}

# Select project type with navigation support
select_project_type() {
    while true; do
        if [[ "$PROJECT_TYPE" != "generic" ]]; then
            return 0  # Already set via command line
        fi
        
        show_navigation_breadcrumbs
        
        local project_options="nextjs|Next.js application with Shadcn/UI
generic|Generic project structure"
        
        print_info "Select project type:"
        local selected
        selected=$(echo -e "$project_options" | select_with_navigation "Project Type:" "$project_options")
        
        local exit_code=$?
        case $exit_code in
            0)
                # Normal selection
                PROJECT_TYPE=$(echo "$selected" | cut -d'|' -f1)
                push_navigation_step "project_type" "$PROJECT_TYPE"
                return 0
                ;;
            3)
                # User wants to go back
                local previous_step
                previous_step=$(pop_navigation_step)
                if [[ -n "$previous_step" ]]; then
                    return 3  # Signal to main workflow to go back
                else
                    print_info "Already at the beginning"
                    continue
                fi
                ;;
            2)
                # User cancelled (Esc)
                print_info "Cancelled by user"
                exit 0
                ;;
            *)
                # Error or no selection, use default
                PROJECT_TYPE="generic"
                push_navigation_step "project_type" "$PROJECT_TYPE"
                return 0
                ;;
        esac
    done
}

# Select Next.js creation method
select_nextjs_method() {
    if [[ "$PROJECT_TYPE" != "nextjs" ]]; then
        return 0
    fi
    
    local method_options="create-next-app|Use create-next-app with Shadcn themes (recommended)
template|Copy from template library"
    
    print_info "Select Next.js creation method:"
    local selected
    selected=$(echo -e "$method_options" | select_with_fzf "Next.js Method:" "$method_options")
    
    if [[ -n "$selected" ]]; then
        PROJECT_METHOD=$(echo "$selected" | cut -d'|' -f1)
    else
        PROJECT_METHOD="create-next-app"  # Default
    fi
}

# Select theme or template with navigation support
select_theme_or_template() {
    while true; do
        case "$PROJECT_TYPE" in
            "nextjs")
                if [[ "$PROJECT_METHOD" == "create-next-app" ]]; then
                    show_navigation_breadcrumbs
                    # Select Shadcn theme
                    print_info "Select Shadcn theme (or press Tab/🔙 to go back):"
                    
                    local theme_options="modern-minimal
violet-bloom
t3-chat
mocha-mousse
amethyst-haze
doom-64
kodama-grove
cosmic-night
quantum-rose
bold-tech
elegant-luxury
amber-minimal
neo-brutalism
solar-dusk
pastel-dreams
clean-slate
ocean-breeze
retro-arcade
midnight-bloom
northern-lights
vintage-paper
sunset-horizon
starry-night
soft-pop"
                    
                    local selected_theme
                    selected_theme=$(echo "$theme_options" | select_with_navigation "Select theme:" "$theme_options" 15)
                    
                    local exit_code=$?
                    case $exit_code in
                        0)
                            TEMPLATE_OR_THEME="$selected_theme"
                            push_navigation_step "theme_selection" "$TEMPLATE_OR_THEME"
                            return 0
                            ;;
                        3)
                            # Go back
                            pop_navigation_step
                            return 3
                            ;;
                        2)
                            # Cancelled - use default (no theme)
                            TEMPLATE_OR_THEME=""
                            push_navigation_step "theme_selection" "default"
                            return 0
                            ;;
                        *)
                            # Error - use default
                            TEMPLATE_OR_THEME=""
                            push_navigation_step "theme_selection" "default"
                            return 0
                            ;;
                    esac
                else
                    # Select from template library
                    show_navigation_breadcrumbs
                    print_info "Select from template library:"
                    TEMPLATE_OR_THEME=$(select_template "interactive")
                    if [[ $? -eq 0 && -n "$TEMPLATE_OR_THEME" ]]; then
                        push_navigation_step "template_selection" "$TEMPLATE_OR_THEME"
                        return 0
                    elif [[ $? -eq 3 ]]; then
                        pop_navigation_step
                        return 3
                    else
                        # Default or cancelled
                        TEMPLATE_OR_THEME=""
                        push_navigation_step "template_selection" "default"
                        return 0
                    fi
                fi
                ;;
            *)
                # No theme/template selection for other project types
                return 0
                ;;
        esac
    done
}

# Get number of panes
get_pane_count() {
    if [[ $PANE_COUNT -ne 1 ]]; then
        return 0  # Already set via command line
    fi
    
    print_color $YELLOW "How many panes do you want in your split view? (1-10):"
    read -r PANE_COUNT
    
    # Validate input
    if ! [[ "$PANE_COUNT" =~ ^[0-9]+$ ]] || [ "$PANE_COUNT" -lt 1 ] || [ "$PANE_COUNT" -gt 10 ]; then
        print_warning "Invalid input. Using 1 pane."
        PANE_COUNT=1
    fi
}

# Configure pane applications
configure_panes() {
    if [[ $PANE_COUNT -eq 1 ]]; then
        PANE_NAMES=("Main")
        case "$PROJECT_TYPE" in
            "nextjs")
                PANE_COMMANDS=("cd $WORKING_DIR && npm run dev")
                ;;
            *)
                PANE_COMMANDS=("cd $WORKING_DIR")
                ;;
        esac
        return 0
    fi
    
    print_info "Configure applications for each pane:"
    
    local app_options="1|Claude Code (Normal)
2|Terminal
3|Code Editor
4|Development Server
5|Git Status
6|File Manager
7|System Monitor
8|Documentation
9|Testing
10|Build/Deploy"
    
    for ((i=0; i<PANE_COUNT; i++)); do
        print_color $YELLOW "Pane $((i+1)) application:"
        
        local selected
        selected=$(echo -e "$app_options" | select_with_fzf "Pane $((i+1)):" "$app_options")
        
        local choice
        choice=$(echo "$selected" | cut -d'|' -f1)
        
        case "$choice" in
            1) 
                PANE_NAMES[$i]="Claude-Code"
                PANE_COMMANDS[$i]="cd $WORKING_DIR && claude"
                ;;
            2)
                PANE_NAMES[$i]="Terminal"
                PANE_COMMANDS[$i]="cd $WORKING_DIR"
                ;;
            3)
                PANE_NAMES[$i]="Editor"
                PANE_COMMANDS[$i]="cd $WORKING_DIR && code ."
                ;;
            4)
                PANE_NAMES[$i]="Dev-Server"
                if [[ "$PROJECT_TYPE" == "nextjs" ]]; then
                    PANE_COMMANDS[$i]="cd $WORKING_DIR && npm run dev"
                else
                    PANE_COMMANDS[$i]="cd $WORKING_DIR && echo 'Start your development server here'"
                fi
                ;;
            5)
                PANE_NAMES[$i]="Git"
                PANE_COMMANDS[$i]="cd $WORKING_DIR && git status"
                ;;
            6)
                PANE_NAMES[$i]="Files"
                PANE_COMMANDS[$i]="cd $WORKING_DIR && ls -la"
                ;;
            7)
                PANE_NAMES[$i]="Monitor"
                PANE_COMMANDS[$i]="htop"
                ;;
            8)
                PANE_NAMES[$i]="Docs"
                PANE_COMMANDS[$i]="cd $WORKING_DIR && echo 'Documentation and notes'"
                ;;
            9)
                PANE_NAMES[$i]="Tests"
                PANE_COMMANDS[$i]="cd $WORKING_DIR && echo 'Run tests here'"
                ;;
            10)
                PANE_NAMES[$i]="Build"
                PANE_COMMANDS[$i]="cd $WORKING_DIR && echo 'Build and deploy'"
                ;;
            *)
                PANE_NAMES[$i]="Terminal"
                PANE_COMMANDS[$i]="cd $WORKING_DIR"
                ;;
        esac
    done
}

# Main workflow
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Show banner
    show_banner
    
    # Validate requirements
    if ! validate_commands "tmux"; then
        exit 1
    fi
    
    # Check existing sessions
    check_existing_sessions
    
    # Get session name
    get_session_name
    
    # Determine if creating new project
    if ask_new_app; then
        IS_NEW_APP=true
        push_navigation_step "new_app" "true"
        
        # Interactive workflow with navigation support
        local current_step="project_type"
        
        while true; do
            case "$current_step" in
                "project_type")
                    if select_project_type; then
                        current_step="method_selection"
                    else
                        # Handle back navigation or exit
                        case $? in
                            3) current_step="new_app" ;;
                            *) exit 0 ;;
                        esac
                    fi
                    ;;
                    
                "method_selection")
                    if [[ "$PROJECT_TYPE" == "nextjs" ]]; then
                        # Select Next.js method
                        select_nextjs_method
                        push_navigation_step "nextjs_method" "$PROJECT_METHOD"
                    fi
                    current_step="theme_selection"
                    ;;
                    
                "theme_selection")
                    if select_theme_or_template; then
                        current_step="project_creation"
                        break  # Exit navigation loop, proceed to project creation
                    else
                        case $? in
                            3) current_step="method_selection" ;;
                            *) current_step="project_creation"; break ;;
                        esac
                    fi
                    ;;
                    
                "new_app")
                    # Back to the very beginning
                    clear_navigation_stack
                    IS_NEW_APP=false
                    break
                    ;;
                    
                *)
                    print_error "Unknown navigation step: $current_step"
                    break
                    ;;
            esac
        done
        
        # If user navigated back to the beginning, handle non-new-app flow
        if [[ "$IS_NEW_APP" == false ]]; then
            WORKING_DIR="$HOME"
        fi
        
        # Create the project (only if still creating new app)
        if [[ "$IS_NEW_APP" == true ]]; then
            print_info "Creating $PROJECT_TYPE project..."
            if ! create_project "$PROJECT_TYPE" "$SESSION_NAME" "$PROJECT_METHOD" "$TEMPLATE_OR_THEME"; then
                print_error "Failed to create project"
                exit 1
            fi
            
            # Set working directory from project manager
            WORKING_DIR=$(get_working_dir)
            
            # Validate project creation
            if ! validate_project "$WORKING_DIR" "$PROJECT_TYPE"; then
                print_error "Project validation failed"
                exit 1
            fi
        fi
    else
        IS_NEW_APP=false
        WORKING_DIR="$HOME"
    fi
    
    # Get pane configuration
    get_pane_count
    configure_panes
    
    # Create the tmux workspace
    print_info "Creating tmux workspace..."
    if ! create_workspace "$SESSION_NAME" "$WORKING_DIR" "$PANE_COUNT" "${PANE_NAMES[@]}"; then
        print_error "Failed to create tmux workspace"
        exit 1
    fi
    
    # Setup pane commands
    for i in "${!PANE_COMMANDS[@]}"; do
        if [[ -n "${PANE_COMMANDS[$i]}" ]]; then
            execute_in_pane "$SESSION_NAME" "$i" "${PANE_COMMANDS[$i]}"
        fi
    done
    
    # Show completion message
    section_header "Workspace Ready! 🚀"
    print_success "Session '$SESSION_NAME' created with $PANE_COUNT pane(s)"
    print_info "Working directory: $WORKING_DIR"
    
    # Show helpful information
    show_tmux_help
    
    # Attach to the session
    attach_to_session "$SESSION_NAME"
}

# Run main function with all arguments
main "$@"