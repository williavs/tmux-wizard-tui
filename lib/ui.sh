#!/bin/bash
# Tmux Wizard - UI Functions Module
# Provides colored output, user interaction, and FZF integration

# Color definitions (only set if not already defined)
[[ -z "${RED:-}" ]] && readonly RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && readonly GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && readonly YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && readonly BLUE='\033[0;34m'
[[ -z "${PURPLE:-}" ]] && readonly PURPLE='\033[0;35m'
[[ -z "${CYAN:-}" ]] && readonly CYAN='\033[0;36m'
[[ -z "${NC:-}" ]] && readonly NC='\033[0m' # No Color

# Print colored text
# Usage: print_color $COLOR "message"
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Print success message
# Usage: print_success "Operation completed"
print_success() {
    print_color $GREEN "✓ $1"
}

# Print error message  
# Usage: print_error "Something went wrong"
print_error() {
    print_color $RED "✗ $1"
}

# Print warning message
# Usage: print_warning "This might be risky"
print_warning() {
    print_color $YELLOW "⚠ $1"
}

# Print info message
# Usage: print_info "Just so you know..."
print_info() {
    print_color $BLUE "ℹ $1"
}

# Ask for yes/no confirmation
# Usage: if confirm_action "Delete this file?"; then ... fi
confirm_action() {
    local message=$1
    local default=${2:-N}  # Default to No
    
    if [[ $default == "Y" ]]; then
        print_color $YELLOW "$message (Y/n): "
        local pattern="^[Nn]$"
        local return_code=0
    else
        print_color $YELLOW "$message (y/N): "
        local pattern="^[Yy]$"
        local return_code=1
    fi
    
    read -r response
    if [[ $response =~ $pattern ]]; then
        return $((1 - return_code))
    else
        return $return_code
    fi
}

# FZF selection with error handling and back navigation
# Usage: selected=$(select_with_fzf "Select option:" "option1\noption2\noption3" [height] [allow_back])
select_with_fzf() {
    local prompt=$1
    local options=$2
    local height=${3:-10}
    local allow_back=${4:-false}
    local header="Use arrow keys to navigate, Enter to select, Esc to cancel"
    
    if ! command -v fzf >/dev/null 2>&1; then
        print_error "fzf is not installed. Please install fzf to use this feature."
        return 1
    fi
    
    # Add back option if enabled
    local fzf_options="$options"
    if [[ "$allow_back" == "true" ]]; then
        fzf_options="🔙 ← Back to previous step
$options"
        header="Arrow keys: navigate • Enter: select • Tab: ← Back • Esc: cancel"
    fi
    
    local selected
    selected=$(echo -e "$fzf_options" | fzf \
        --prompt="$prompt " \
        --height="$height" \
        --border \
        --header="$header" \
        --no-info \
        --reverse \
        --bind="tab:accept" \
        --expect="tab")
    
    local exit_code=$?
    local key=$(echo "$selected" | head -1)
    local choice=$(echo "$selected" | tail -1)
    
    # Handle different exit scenarios
    if [[ $exit_code -eq 130 ]]; then
        # User pressed Esc/Ctrl+C
        return 2
    elif [[ "$key" == "tab" ]] || [[ "$choice" == "🔙 ← Back to previous step" ]]; then
        # User wants to go back
        return 3
    elif [[ $exit_code -eq 0 && -n "$choice" ]]; then
        # Normal selection
        echo "$choice"
        return 0
    else
        # No selection made or other error
        return 1
    fi
}

# Enhanced selection with automatic back navigation
# Usage: selected=$(select_with_navigation "prompt" "options" [height])
select_with_navigation() {
    local prompt=$1
    local options=$2  
    local height=${3:-10}
    
    # Check if we're in a navigation context (stack exists)
    local allow_back=false
    if [[ ${#NAVIGATION_STACK[@]} -gt 0 ]]; then
        allow_back=true
    fi
    
    select_with_fzf "$prompt" "$options" "$height" "$allow_back"
}

# Multi-select with FZF
# Usage: selected=$(multi_select_with_fzf "Select multiple:" "option1\noption2\noption3")
multi_select_with_fzf() {
    local prompt=$1
    local options=$2
    local height=${3:-10}
    local header=${4:-"Tab to select multiple, Enter to confirm"}
    
    if ! command -v fzf >/dev/null 2>&1; then
        print_error "fzf is not installed. Please install fzf to use this feature."
        return 1
    fi
    
    echo -e "$options" | fzf \
        --prompt="$prompt " \
        --height="$height" \
        --border \
        --header="$header" \
        --multi \
        --reverse
}

# Show progress spinner
# Usage: show_spinner "Processing..." &
#        SPINNER_PID=$!
#        # ... do work ...
#        kill $SPINNER_PID 2>/dev/null
show_spinner() {
    local message=$1
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    
    while true; do
        printf "\r${CYAN}%c${NC} %s" "${chars:$i:1}" "$message"
        i=$(( (i + 1) % ${#chars} ))
        sleep 0.1
    done
}

# Show progress bar
# Usage: show_progress 50 100 "Installing packages"
show_progress() {
    local current=$1
    local total=$2
    local message=${3:-"Progress"}
    
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CYAN}%s${NC} [" "$message"
    printf "%*s" $filled | tr ' ' '█'
    printf "%*s" $empty | tr ' ' '░'
    printf "] %d%%" $percent
    
    if [[ $current -eq $total ]]; then
        echo ""  # New line when complete
    fi
}

# Create a section header
# Usage: section_header "Project Configuration"
section_header() {
    local title=$1
    local width=50
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo ""
    print_color $BLUE "$(printf '═%.0s' $(seq 1 $width))"
    printf "${BLUE}%*s %s %*s${NC}\n" $padding "" "$title" $padding ""
    print_color $BLUE "$(printf '═%.0s' $(seq 1 $width))"
    echo ""
}

# Show a box with text
# Usage: show_box "Important message here"
show_box() {
    local message=$1
    local width=$((${#message} + 4))
    
    print_color $YELLOW "┌$(printf '─%.0s' $(seq 1 $((width - 2))))┐"
    print_color $YELLOW "│ $message │"
    print_color $YELLOW "└$(printf '─%.0s' $(seq 1 $((width - 2))))┘"
}

# Validate that required commands exist
# Usage: validate_commands "fzf git tmux"
validate_commands() {
    local commands=$1
    local missing=()
    
    for cmd in $commands; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_error "Missing required commands: ${missing[*]}"
        print_info "Please install the missing commands and try again"
        return 1
    fi
    
    return 0
}

# Show help text with proper formatting
# Usage: show_help "command" "description" "usage example"
show_help() {
    local command=$1
    local description=$2
    local usage=$3
    
    section_header "Help: $command"
    print_color $GREEN "Description:"
    echo "  $description"
    echo ""
    print_color $GREEN "Usage:"
    echo "  $usage"
    echo ""
}

# Navigation stack management
declare -a NAVIGATION_STACK=()

# Push current step onto navigation stack
# Usage: push_navigation_step "step_name" "step_data"
push_navigation_step() {
    local step_name="$1"
    local step_data="$2"
    NAVIGATION_STACK+=("$step_name:$step_data")
    print_info "Navigation: $step_name (${#NAVIGATION_STACK[@]} steps)"
}

# Pop and return to previous step
# Usage: previous_step=$(pop_navigation_step)
pop_navigation_step() {
    if [[ ${#NAVIGATION_STACK[@]} -eq 0 ]]; then
        echo ""
        return 1
    fi
    
    # Remove last element
    local last_index=$((${#NAVIGATION_STACK[@]} - 1))
    local previous_step="${NAVIGATION_STACK[$last_index]}"
    unset 'NAVIGATION_STACK[$last_index]'
    
    echo "$previous_step"
    print_info "Going back: $(echo "$previous_step" | cut -d':' -f1)"
    return 0
}

# Get current navigation depth
get_navigation_depth() {
    echo "${#NAVIGATION_STACK[@]}"
}

# Clear navigation stack
clear_navigation_stack() {
    NAVIGATION_STACK=()
    print_info "Navigation stack cleared"
}

# Show navigation breadcrumbs
show_navigation_breadcrumbs() {
    if [[ ${#NAVIGATION_STACK[@]} -eq 0 ]]; then
        return 0
    fi
    
    local breadcrumbs=""
    for step in "${NAVIGATION_STACK[@]}"; do
        local step_name=$(echo "$step" | cut -d':' -f1)
        if [[ -n "$breadcrumbs" ]]; then
            breadcrumbs="$breadcrumbs → $step_name"
        else
            breadcrumbs="$step_name"
        fi
    done
    
    print_color $CYAN "📍 Navigation: $breadcrumbs"
}