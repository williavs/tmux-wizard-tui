#!/bin/bash

# Tmux Workspace Wizard - Split View Edition
# Interactive script to set up a tmux session with split panes

set -e

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to create split layout based on pane count
create_split_layout() {
    local pane_count=$1
    
    case $pane_count in
        2)
            # Split horizontally (side by side)
            tmux split-window -h -t $SESSION_NAME:0 -c "$WORKING_DIR"
            ;;
        3)
            # One big pane on left, two stacked on right
            tmux split-window -h -t $SESSION_NAME:0 -c "$WORKING_DIR"
            tmux split-window -v -t $SESSION_NAME:0.1 -c "$WORKING_DIR"
            ;;
        4)
            # 2x2 grid
            tmux split-window -h -t $SESSION_NAME:0 -c "$WORKING_DIR"
            tmux split-window -v -t $SESSION_NAME:0.0 -c "$WORKING_DIR"
            tmux split-window -v -t $SESSION_NAME:0.2 -c "$WORKING_DIR"
            ;;
        5)
            # Top row with 3, bottom row with 2
            tmux split-window -v -t $SESSION_NAME:0 -c "$WORKING_DIR"
            tmux split-window -h -t $SESSION_NAME:0.0 -c "$WORKING_DIR"
            tmux split-window -h -t $SESSION_NAME:0.1 -c "$WORKING_DIR"
            tmux split-window -h -t $SESSION_NAME:0.3 -c "$WORKING_DIR"
            ;;
        6)
            # 3x2 grid
            tmux split-window -v -t $SESSION_NAME:0 -c "$WORKING_DIR"
            tmux split-window -h -t $SESSION_NAME:0.0 -c "$WORKING_DIR"
            tmux split-window -h -t $SESSION_NAME:0.1 -c "$WORKING_DIR"
            tmux split-window -h -t $SESSION_NAME:0.3 -c "$WORKING_DIR"
            tmux split-window -h -t $SESSION_NAME:0.4 -c "$WORKING_DIR"
            ;;
        7|8|9|10)
            # Use tiled layout for 7+ panes
            for (( i=1; i<$pane_count; i++ )); do
                tmux split-window -t $SESSION_NAME:0 -c "$WORKING_DIR"
                tmux select-layout -t $SESSION_NAME:0 tiled
            done
            ;;
    esac
}

# Define views directory
VIEWS_DIR="/home/wv3/tmux-scripts/views"

# Function to find available port in range
find_available_port() {
    local start_port=$1
    local end_port=$2
    
    # Try a few common ports first
    for port in 3000 3001 3002 3003; do
        if [ $port -ge $start_port ] && [ $port -le $end_port ]; then
            if ! nc -w 1 -z localhost $port 2>/dev/null; then
                echo $port
                return 0
            fi
        fi
    done
    
    # If common ports are taken, scan the range
    for port in $(seq $start_port $end_port); do
        if ! nc -w 1 -z localhost $port 2>/dev/null; then
            echo $port
            return 0
        fi
    done
    
    echo ""
    return 1
}

# Function to select Next.js template
select_nextjs_template() {
    local templates_dir="/home/wv3/templates"
    local temp_file="/tmp/nextjs_templates_$$.txt"
    local curated_file="/home/wv3/tmux-scripts/nextjs-templates.txt"
    
    # Check if user wants curated list or full list
    print_color $GREEN "Template Selection Mode:" >&2
    print_color $YELLOW "1) Popular templates (curated, ~40 templates)" >&2
    print_color $YELLOW "2) All templates (200+ templates)" >&2
    echo -n "Choice (1-2, default: 1): " >&2
    read -r -t 5 MODE
    MODE=${MODE:-1}
    echo >&2
    
    if [ "$MODE" = "1" ] && [ -f "$curated_file" ]; then
        # Use curated list
        cp "$curated_file" "$temp_file"
    else
        # Build full list
        {
            echo "━━━ 🚀 QUICK START ━━━"
            echo "minimal                          | Minimal Next.js 15 starter"
            echo "vercel/commerce                  | Full e-commerce site"
            echo "vercel/nextjs-postgres-nextauth  | Auth + Database starter"
            echo "vercel/ai-chatbot                | AI chatbot with streaming"
            echo ""
            
            echo "━━━ 🔐 CLERK AUTH APPS ━━━"
            for category in "$templates_dir/clerk-auth"/*; do
                if [ -d "$category" ]; then
                    for template in "$category"/*; do
                        if [ -d "$template" ]; then
                            cat_name=$(basename "$category")
                            temp_name=$(basename "$template")
                            printf "clerk-auth/%-30s | Clerk %s\n" "$cat_name/$temp_name" "$cat_name"
                        fi
                    done
                fi
            done | sort
            echo ""
            
            echo "━━━ ⭐ MODERN SAAS APPS ━━━"
            find "$templates_dir/modern-saas" -maxdepth 1 -type d ! -path "$templates_dir/modern-saas" 2>/dev/null | while read dir; do
                basename "$dir" | awk '{printf "modern-saas/%-21s | SaaS Boilerplate\n", $0}'
            done | sort
            echo ""
            
            echo "━━━ 📱 SOCIAL MEDIA APPS ━━━"
            find "$templates_dir/social-media" -maxdepth 1 -type d ! -path "$templates_dir/social-media" 2>/dev/null | while read dir; do
                basename "$dir" | awk '{printf "social-media/%-20s | Social Platform\n", $0}'
            done | sort
            echo ""
            
            echo "━━━ 🎬 VIDEO PLATFORMS ━━━"
            find "$templates_dir/youtube-builds" -maxdepth 1 -type d ! -path "$templates_dir/youtube-builds" 2>/dev/null | while read dir; do
                basename "$dir" | awk '{printf "youtube-builds/%-18s | Video Platform\n", $0}'
            done | sort
            echo ""
            
            echo "━━━ 📊 CRM & DASHBOARDS ━━━"
            find "$templates_dir/crm-dashboards" -maxdepth 1 -type d ! -path "$templates_dir/crm-dashboards" 2>/dev/null | while read dir; do
                basename "$dir" | awk '{printf "crm-dashboards/%-18s | Business Tool\n", $0}'
            done | sort
            echo ""
            
            echo "━━━ 🚀 FULL-STACK APPS ━━━"
            find "$templates_dir/full-stack" -maxdepth 1 -type d ! -path "$templates_dir/full-stack" 2>/dev/null | while read dir; do
                basename "$dir" | awk '{printf "full-stack/%-22s | Full App\n", $0}'
            done | sort
            echo ""
            
            echo "━━━ 📁 VERCEL TEMPLATES ━━━"
            find "$templates_dir/vercel" -maxdepth 1 -type d ! -path "$templates_dir/vercel" ! -name "nextjs-examples" | while read dir; do
                basename "$dir" | awk '{printf "vercel/%-26s | Vercel\n", $0}'
            done | sort
            echo ""
            
            echo "━━━ 👥 COMMUNITY ━━━"
            find "$templates_dir/community" -maxdepth 1 -type d ! -path "$templates_dir/community" | while read dir; do
                basename "$dir" | awk '{printf "community/%-23s | Community\n", $0}'
            done | sort
            echo ""
            
            echo "━━━ 📚 EXAMPLES (200+) ━━━"
            find "$templates_dir/vercel/nextjs-examples" -maxdepth 1 -type d ! -path "$templates_dir/vercel/nextjs-examples" | while read dir; do
                basename "$dir" | awk '{printf "examples/%-24s | Example\n", $0}'
            done | sort
        } > "$temp_file"
    fi
    
    # Use fzf with better options
    print_color $GREEN "Select Next.js Template:" >&2
    print_color $YELLOW "🔍 Type to search: auth, blog, cms, api, tailwind, database" >&2
    echo >&2
    
    local selected=$(cat "$temp_file" | fzf \
        --height 90% \
        --reverse \
        --prompt="🔎 Search: " \
        --ansi \
        --no-bold \
        --header="↑↓ Navigate • Enter to select • Esc to cancel" \
        --preview-window='hidden' \
        | awk -F' \\| ' '{print $1}' | tr -d ' ' || echo "")
    
    rm -f "$temp_file"
    
    # Clean up the selection (remove category prefix for examples)
    if [[ "$selected" == "examples/"* ]]; then
        selected="vercel/nextjs-examples/${selected#examples/}"
    fi
    
    # Return the selection
    if [ -n "$selected" ]; then
        echo "$selected"
    else
        echo "minimal"
    fi
}

# Main wizard starts here
clear
print_color $BLUE "╔══════════════════════════════════════╗"
print_color $BLUE "║    TMUX WORKSPACE WIZARD - SPLIT     ║"
print_color $BLUE "╚══════════════════════════════════════╝"
echo

# Check existing sessions first
EXISTING_SESSIONS=$(tmux list-sessions 2>/dev/null | cut -d: -f1)
if [ ! -z "$EXISTING_SESSIONS" ]; then
    print_color $GREEN "Active tmux sessions:"
    echo "$EXISTING_SESSIONS" | nl -w2 -s') '
    print_color $YELLOW "\nSelect a session to switch to (number), 'r' to refresh a session, or Enter to continue:"
    read -r SESSION_CHOICE
    
    if [[ $SESSION_CHOICE =~ ^[0-9]+$ ]]; then
        SELECTED_SESSION=$(echo "$EXISTING_SESSIONS" | sed -n "${SESSION_CHOICE}p")
        if [ ! -z "$SELECTED_SESSION" ]; then
            print_color $GREEN "Switching to session: $SELECTED_SESSION"
            if [ -n "$TMUX" ]; then
                tmux switch-client -t "$SELECTED_SESSION"
            else
                tmux attach-session -t "$SELECTED_SESSION"
            fi
            exit 0
        fi
    elif [[ $SESSION_CHOICE == "r" ]]; then
        print_color $YELLOW "Which session to refresh? (number):"
        read -r REFRESH_NUM
        if [[ $REFRESH_NUM =~ ^[0-9]+$ ]]; then
            REFRESH_SESSION=$(echo "$EXISTING_SESSIONS" | sed -n "${REFRESH_NUM}p")
            if [ ! -z "$REFRESH_SESSION" ] && [ -f "$VIEWS_DIR/${REFRESH_SESSION}.sh" ]; then
                print_color $YELLOW "Refreshing session '$REFRESH_SESSION' from saved view..."
                tmux kill-session -t "$REFRESH_SESSION" 2>/dev/null
                ${VIEWS_DIR}/${REFRESH_SESSION}.sh "$REFRESH_SESSION"
                exit 0
            else
                print_color $RED "No saved view found for session '$REFRESH_SESSION' or invalid selection"
            fi
        fi
    fi
fi

# Check for saved views and tmuxinator sessions
TMUXINATOR_AVAILABLE=false
TMUXINATOR_DIR=""
if command -v tmuxinator &> /dev/null; then
    TMUXINATOR_AVAILABLE=true
    # Check common tmuxinator config locations
    for dir in "$HOME/.tmuxinator" "$HOME/.config/tmuxinator"; do
        if [ -d "$dir" ] && [ "$(ls -A $dir/*.yml 2>/dev/null)" ]; then
            TMUXINATOR_DIR="$dir"
            break
        fi
    done
fi

if ([ -d "$VIEWS_DIR" ] && [ "$(ls -A $VIEWS_DIR/*.sh 2>/dev/null)" ]) || [ "$TMUXINATOR_AVAILABLE" = true ] && [ -n "$TMUXINATOR_DIR" ]; then
    print_color $YELLOW "\nWould you like to load a saved configuration? (y/N):"
    read -r LOAD_SAVED

    if [[ $LOAD_SAVED =~ ^[Yy]$ ]]; then
        print_color $GREEN "\nAvailable configurations:"
        i=1
        declare -a CONFIG_FILES
        declare -a CONFIG_TYPES

        # Add saved view configurations
        if [ -d "$VIEWS_DIR" ] && [ "$(ls -A $VIEWS_DIR/*.sh 2>/dev/null)" ]; then
            print_color $BLUE "\n━━━ TMUX WIZARD VIEWS ━━━"
            for view in $VIEWS_DIR/*.sh; do
                view_name=$(basename "$view" .sh)
                print_color $GREEN "  $i) $view_name (wizard view)"
                CONFIG_FILES[$i]="$view"
                CONFIG_TYPES[$i]="wizard"
                ((i++))
            done
        fi

        # Add tmuxinator configurations
        if [ "$TMUXINATOR_AVAILABLE" = true ] && [ -n "$TMUXINATOR_DIR" ]; then
            print_color $BLUE "\n━━━ TMUXINATOR SESSIONS ━━━"
            for tmuxinator_file in $TMUXINATOR_DIR/*.yml; do
                session_name=$(basename "$tmuxinator_file" .yml)
                print_color $GREEN "  $i) $session_name (tmuxinator)"
                CONFIG_FILES[$i]="$tmuxinator_file"
                CONFIG_TYPES[$i]="tmuxinator"
                ((i++))
            done
        fi

        print_color $YELLOW "\nSelect configuration (number) or press Enter to continue with wizard:"
        read -r CONFIG_CHOICE

        if [[ $CONFIG_CHOICE =~ ^[0-9]+$ ]] && [ ! -z "${CONFIG_FILES[$CONFIG_CHOICE]}" ]; then
            CONFIG_TYPE="${CONFIG_TYPES[$CONFIG_CHOICE]}"
            CONFIG_FILE="${CONFIG_FILES[$CONFIG_CHOICE]}"

            if [ "$CONFIG_TYPE" = "wizard" ]; then
                # Handle wizard view
                DEFAULT_SESSION=$(basename "$CONFIG_FILE" .sh)
                print_color $YELLOW "Enter session name (default: $DEFAULT_SESSION):"
                read -r SESSION_NAME
                SESSION_NAME=${SESSION_NAME:-$DEFAULT_SESSION}

                # Check if session already exists
                if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                    print_color $GREEN "\nSession '$SESSION_NAME' exists. Switching to it..."
                    if [ -n "$TMUX" ]; then
                        tmux switch-client -t "$SESSION_NAME"
                    else
                        tmux attach-session -t "$SESSION_NAME"
                    fi
                else
                    print_color $GREEN "\nCreating new session from saved wizard configuration..."
                    $CONFIG_FILE "$SESSION_NAME"
                fi
            else
                # Handle tmuxinator session
                SESSION_NAME=$(basename "$CONFIG_FILE" .yml)
                print_color $YELLOW "Enter session name (default: $SESSION_NAME):"
                read -r CUSTOM_SESSION_NAME
                SESSION_NAME=${CUSTOM_SESSION_NAME:-$SESSION_NAME}

                # Check if session already exists
                if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
                    print_color $GREEN "\nSession '$SESSION_NAME' exists. Switching to it..."
                    if [ -n "$TMUX" ]; then
                        tmux switch-client -t "$SESSION_NAME"
                    else
                        tmux attach-session -t "$SESSION_NAME"
                    fi
                else
                    print_color $GREEN "\nCreating new session from tmuxinator configuration..."
                    tmuxinator start "$SESSION_NAME"
                fi
            fi
            exit 0
        fi
    fi
fi

# Ask if this is a new app project
print_color $YELLOW "Is this a new app/project? (y/N):"
read -r IS_NEW_APP

# Initialize project type variables
PROJECT_TYPE="generic"
NEXTJS_TEMPLATE=""
NEXTJS_PORT=""
NEXTJS_CREATE_METHOD=""
NEXTJS_CREATE_OPTIONS=""
VITE_TEMPLATE=""
API_TEMPLATE=""
REALTIME_TEMPLATE=""
GAME_TEMPLATE=""

# Set up project type and session name based on new app choice
if [[ $IS_NEW_APP =~ ^[Yy]$ ]]; then
    # Ask for project type FIRST
    print_color $YELLOW "\nWhat type of project?"
    echo "1) Generic Project"
    echo "2) Next.js Application"
    echo "3) Vite Application (React/Vue/Solid)"
    echo "4) API Service (Express/Socket.io)"
    echo "5) Real-time App (WebRTC/WebSockets)"
    echo "6) Multiplayer Game"
    print_color $YELLOW "Select project type (1-6, default: 1):"
    read -r PROJECT_TYPE_CHOICE
    
    case $PROJECT_TYPE_CHOICE in
        2)
            PROJECT_TYPE="nextjs"
            print_color $YELLOW "\nHow would you like to create the Next.js app?"
            echo "1) From template (copy from ~/templates)"
            echo "2) Using create-next-app command"
            print_color $YELLOW "Select method (1-2, default: 1):"
            read -r NEXTJS_METHOD
            NEXTJS_METHOD=${NEXTJS_METHOD:-1}
            
            if [ "$NEXTJS_METHOD" = "1" ]; then
                # Capture template selection with error handling
                NEXTJS_TEMPLATE=$(select_nextjs_template)
                if [ $? -ne 0 ]; then
                    print_color $RED "Template selection failed, using minimal template"
                    NEXTJS_TEMPLATE="minimal"
                fi
                NEXTJS_CREATE_METHOD="template"
                print_color $GREEN "Selected template: $NEXTJS_TEMPLATE"
            else
                NEXTJS_CREATE_METHOD="create-next-app"
                print_color $GREEN "✓ Using automated Next.js + Shadcn setup (no manual options needed)"
                NEXTJS_CREATE_OPTIONS=""
            fi
            
            NEXTJS_PORT="3000"
            print_color $GREEN "✓ Next.js dev server will use port: $NEXTJS_PORT"
            ;;
        3)
            PROJECT_TYPE="vite"
            print_color $GREEN "✓ Vite Application selected"
            print_color $YELLOW "\nSelect Vite template:"
            echo "1) React + TypeScript"
            echo "2) Vue 3 + TypeScript"
            echo "3) Solid + TypeScript"
            echo "4) Svelte + TypeScript"
            echo "5) Socket.io + React + TypeScript"
            print_color $YELLOW "Select template (1-5, default: 1):"
            read -r VITE_TEMPLATE_CHOICE
            
            case $VITE_TEMPLATE_CHOICE in
                2) VITE_TEMPLATE="vite-vue3-ts" ;;
                3) VITE_TEMPLATE="vite-solid-ts" ;;
                4) VITE_TEMPLATE="vite-svelte-ts" ;;
                5) VITE_TEMPLATE="vite-socketio-ts" ;;
                *) VITE_TEMPLATE="vite-react-ts" ;;
            esac
            print_color $GREEN "✓ Template: $VITE_TEMPLATE"
            ;;
        4)
            PROJECT_TYPE="api"
            print_color $GREEN "✓ API Service selected"
            print_color $YELLOW "\nSelect API template:"
            echo "1) Fastify + Vite"
            echo "2) Vite + Socket.io (Custom)"
            print_color $YELLOW "Select template (1-2, default: 1):"
            read -r API_TEMPLATE_CHOICE
            
            case $API_TEMPLATE_CHOICE in
                2) API_TEMPLATE="vite-socketio-ts" ;;
                *) API_TEMPLATE="fastify-vite" ;;
            esac
            print_color $GREEN "✓ Template: $API_TEMPLATE"
            ;;
        5)
            PROJECT_TYPE="realtime"
            print_color $GREEN "✓ Real-time App selected"
            print_color $YELLOW "\nSelect real-time template:"
            echo "1) Socket.io Chat"
            echo "2) WebRTC Video Chat"
            echo "3) Webcam Monitor"
            print_color $YELLOW "Select template (1-3, default: 1):"
            read -r REALTIME_TEMPLATE_CHOICE
            
            case $REALTIME_TEMPLATE_CHOICE in
                2) REALTIME_TEMPLATE="simple-webrtc" ;;
                3) REALTIME_TEMPLATE="webcam-monitor" ;;
                *) REALTIME_TEMPLATE="socketio-chat" ;;
            esac
            print_color $GREEN "✓ Template: $REALTIME_TEMPLATE"
            ;;
        6)
            PROJECT_TYPE="game"
            print_color $GREEN "✓ Multiplayer Game selected"
            print_color $YELLOW "\nSelect game template:"
            echo "1) Three.js Multiplayer"
            echo "2) Drawing Game"
            print_color $YELLOW "Select template (1-2, default: 1):"
            read -r GAME_TEMPLATE_CHOICE
            
            case $GAME_TEMPLATE_CHOICE in
                2) GAME_TEMPLATE="drawing-game" ;;
                *) GAME_TEMPLATE="threejs-multiplayer" ;;
            esac
            print_color $GREEN "✓ Template: $GAME_TEMPLATE"
            ;;
        *)
            PROJECT_TYPE="generic"
            ;;
    esac
fi

# Get session name
print_color $YELLOW "\nEnter session/project name (default: workspace):"
read -r SESSION_NAME
SESSION_NAME=${SESSION_NAME:-workspace}

# Execute Next.js creation immediately if create-next-app method was selected
if [ "$PROJECT_TYPE" = "nextjs" ] && [ "$NEXTJS_CREATE_METHOD" = "create-next-app" ]; then
    # Check if directory exists BEFORE creating the project
    TEMP_WORKING_DIR="/home/wv3/$SESSION_NAME"
    if [ -d "$TEMP_WORKING_DIR" ] && [ "$(ls -A $TEMP_WORKING_DIR 2>/dev/null)" ]; then
        print_color $RED "Directory $TEMP_WORKING_DIR already exists and is not empty!"
        print_color $YELLOW "Delete it and continue? (y/N):"
        read -r DELETE_DIR
        if [[ $DELETE_DIR =~ ^[Yy]$ ]]; then
            rm -rf "$TEMP_WORKING_DIR"
        else
            print_color $RED "Cannot create Next.js project in non-empty directory. Exiting..."
            exit 1
        fi
    fi

    # Ask for theme selection using fzf
    print_color $YELLOW "Select a Tweakcn theme (or press Esc for default):"
    AVAILABLE_THEMES="modern-minimal
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
    
    SELECTED_THEME=$(echo "$AVAILABLE_THEMES" | fzf --prompt="Select theme: " --height=15 --border --header="Use arrow keys to navigate, Enter to select, Esc for default" || echo "")

    print_color $GREEN "Creating Next.js app with Shadcn UI..."
    if [ -n "$SELECTED_THEME" ]; then
        /home/wv3/.claude/scripts/create-nextjs-shadcn.sh "$SESSION_NAME" "/home/wv3" "$SELECTED_THEME"
        print_color $GREEN "✓ Next.js app created with $SELECTED_THEME theme!"
    else
        /home/wv3/.claude/scripts/create-nextjs-shadcn.sh "$SESSION_NAME" "/home/wv3"
        print_color $GREEN "✓ Next.js app created with default Shadcn setup!"
    fi

    # After external script execution, set up AI infrastructure and update package.json
    if [ "$PROJECT_TYPE" = "nextjs" ] && [ "$NEXTJS_CREATE_METHOD" = "create-next-app" ]; then
        # WORKING_DIR is already set in the main logic below, no need to duplicate it here

        # Copy essential AI infrastructure (includes symlinks to global agents, agent_comms, and commands)
        print_color $GREEN "Setting up AI infrastructure..."
        cp -r /home/wv3/claude-code-work/.claude "$WORKING_DIR/" 2>/dev/null && print_color $GREEN "✓ Copied .claude configuration with global symlinks"
        cp /home/wv3/claude-code-work/CLAUDE.md "$WORKING_DIR/" 2>/dev/null && print_color $GREEN "✓ Copied CLAUDE.md documentation"

        # Customize source app name in settings.json
        if [ -f "$WORKING_DIR/.claude/settings.json" ]; then
            sed -i "s/cc-hook-multi-agent-obvs/$SESSION_NAME/g" "$WORKING_DIR/.claude/settings.json"
            print_color $GREEN "✓ Customized source app name to: $SESSION_NAME"
        fi

        # Update package.json with project name
        if [ -f "$WORKING_DIR/package.json" ]; then
            # Check if name field exists
            if grep -q '"name"' "$WORKING_DIR/package.json"; then
                # Update existing name
                sed -i "s/\"name\": \"[^\"]*\"/\"name\": \"$SESSION_NAME\"/" "$WORKING_DIR/package.json"
            else
                # Add name field after opening brace on first line only
                sed -i "1s/{/{\\n  \"name\": \"$SESSION_NAME\",/" "$WORKING_DIR/package.json"
            fi
            print_color $GREEN "✓ Updated package.json with project name: $SESSION_NAME"
        fi
    fi
fi

# Set up directories based on new app choice
if [[ $IS_NEW_APP =~ ^[Yy]$ ]]; then
    WORKING_DIR="/home/wv3/$SESSION_NAME"
    
    # Directory check for Next.js projects is now handled earlier in the script
    
    # Conditional directory creation based on method
    if [ "$PROJECT_TYPE" = "nextjs" ] && [ "$NEXTJS_CREATE_METHOD" = "create-next-app" ]; then
        # Skip mkdir - external script creates directory
        print_color $BLUE "External script will create project directory: $WORKING_DIR"
    else
        # For template method: Create directory first
        print_color $BLUE "Creating new project directory: $WORKING_DIR"
        mkdir -p "$WORKING_DIR"
    fi
    
    # For Next.js template projects, copy the template NOW (not in tmux pane)
    if [ "$PROJECT_TYPE" = "nextjs" ] && [ "$NEXTJS_CREATE_METHOD" = "template" ]; then
        if [ "$NEXTJS_TEMPLATE" = "minimal" ]; then
            print_color $GREEN "✓ Directory created for minimal Next.js project"
            # Minimal template will be created in tmux pane
        else
            print_color $GREEN "Copying template: $NEXTJS_TEMPLATE..."
            print_color $YELLOW "From: /home/wv3/templates/$NEXTJS_TEMPLATE"
            print_color $YELLOW "To: $WORKING_DIR"
            # Copy template contents to become the project root
            if cp -r /home/wv3/templates/$NEXTJS_TEMPLATE/. "$WORKING_DIR/"; then
                print_color $GREEN "✓ Template copied successfully"
                # Verify files were copied
                if [ -d "$WORKING_DIR/app" ] || [ -d "$WORKING_DIR/pages" ] || [ -f "$WORKING_DIR/package.json" ]; then
                    print_color $GREEN "✓ Template files verified"
                else
                    print_color $RED "⚠ Warning: Template files may not have copied correctly"
                fi
            else
                print_color $RED "✗ Failed to copy template!"
                print_color $YELLOW "Template path: /home/wv3/templates/$NEXTJS_TEMPLATE"
                exit 1
            fi
            
            # Update package.json with project name if it exists
            if [ -f "$WORKING_DIR/package.json" ]; then
                # Check if name field exists
                if grep -q '"name"' "$WORKING_DIR/package.json"; then
                    # Update existing name
                    sed -i "s/\"name\": \"[^\"]*\"/\"name\": \"$SESSION_NAME\"/" "$WORKING_DIR/package.json"
                else
                    # Add name field after opening brace on first line only
                    sed -i "1s/{/{\\n  \"name\": \"$SESSION_NAME\",/" "$WORKING_DIR/package.json"
                fi
                print_color $GREEN "✓ Updated package.json with project name: $SESSION_NAME"
            fi
        fi
    fi
    
    # For Vite projects, copy the template
    if [ "$PROJECT_TYPE" = "vite" ] && [ -n "$VITE_TEMPLATE" ]; then
        print_color $GREEN "Copying Vite template: $VITE_TEMPLATE..."
        TEMPLATE_PATH="/home/wv3/templates/vite/$VITE_TEMPLATE"
        print_color $YELLOW "From: $TEMPLATE_PATH"
        print_color $YELLOW "To: $WORKING_DIR"
        
        if [ -d "$TEMPLATE_PATH" ]; then
            if cp -r "$TEMPLATE_PATH/." "$WORKING_DIR/" 2>/dev/null; then
                print_color $GREEN "✓ Vite template copied successfully"
                # Verify files were copied
                if [ -f "$WORKING_DIR/package.json" ]; then
                    print_color $GREEN "✓ Template files verified"
                else
                    print_color $RED "⚠ Warning: Template may not have copied correctly - no package.json found"
                fi
            else
                print_color $RED "✗ Failed to copy Vite template! Check permissions."
            fi
        else
            print_color $RED "✗ Template not found at: $TEMPLATE_PATH"
        fi
    fi
    
    # For API projects, copy the template
    if [ "$PROJECT_TYPE" = "api" ] && [ -n "$API_TEMPLATE" ]; then
        print_color $GREEN "Copying API template: $API_TEMPLATE..."
        # Determine template path based on template name
        if [ "$API_TEMPLATE" = "vite-socketio-ts" ]; then
            TEMPLATE_PATH="/home/wv3/templates/vite/$API_TEMPLATE"
        else
            TEMPLATE_PATH="/home/wv3/templates/fullstack/$API_TEMPLATE"
        fi
        
        if [ -d "$TEMPLATE_PATH" ]; then
            if cp -r "$TEMPLATE_PATH/." "$WORKING_DIR/"; then
                print_color $GREEN "✓ API template copied successfully from $TEMPLATE_PATH"
            else
                print_color $RED "✗ Failed to copy API template!"
            fi
        else
            print_color $RED "✗ Template not found at: $TEMPLATE_PATH"
        fi
    fi
    
    # For Real-time projects, copy the template
    if [ "$PROJECT_TYPE" = "realtime" ] && [ -n "$REALTIME_TEMPLATE" ]; then
        print_color $GREEN "Copying real-time template: $REALTIME_TEMPLATE..."
        TEMPLATE_PATH="/home/wv3/templates/realtime/$REALTIME_TEMPLATE"
        print_color $YELLOW "From: $TEMPLATE_PATH"
        print_color $YELLOW "To: $WORKING_DIR"
        
        if [ -d "$TEMPLATE_PATH" ]; then
            if cp -r "$TEMPLATE_PATH/." "$WORKING_DIR/" 2>/dev/null; then
                print_color $GREEN "✓ Real-time template copied successfully"
                # Verify files were copied
                if [ -f "$WORKING_DIR/package.json" ] || [ -d "$WORKING_DIR/server" ]; then
                    print_color $GREEN "✓ Template files verified"
                else
                    print_color $RED "⚠ Warning: Template may not have copied correctly"
                fi
            else
                print_color $RED "✗ Failed to copy real-time template! Check permissions."
            fi
        else
            print_color $RED "✗ Template not found at: $TEMPLATE_PATH"
        fi
    fi
    
    # For Game projects, copy the template
    if [ "$PROJECT_TYPE" = "game" ] && [ -n "$GAME_TEMPLATE" ]; then
        print_color $GREEN "Copying game template: $GAME_TEMPLATE..."
        TEMPLATE_PATH="/home/wv3/templates/games/$GAME_TEMPLATE"
        print_color $YELLOW "From: $TEMPLATE_PATH"
        print_color $YELLOW "To: $WORKING_DIR"
        
        if [ -d "$TEMPLATE_PATH" ]; then
            if cp -r "$TEMPLATE_PATH/." "$WORKING_DIR/" 2>/dev/null; then
                print_color $GREEN "✓ Game template copied successfully"
                # Verify files were copied
                if [ -f "$WORKING_DIR/package.json" ] || [ -d "$WORKING_DIR/src" ]; then
                    print_color $GREEN "✓ Template files verified"
                else
                    print_color $RED "⚠ Warning: Template may not have copied correctly"
                fi
            else
                print_color $RED "✗ Failed to copy game template! Check permissions."
            fi
        else
            print_color $RED "✗ Template not found at: $TEMPLATE_PATH"
        fi
    fi
    
    # Update package.json with project name for all project types with templates (excluding create-next-app)
    if [ -f "$WORKING_DIR/package.json" ] && ! ([ "$PROJECT_TYPE" = "nextjs" ] && [ "$NEXTJS_CREATE_METHOD" = "create-next-app" ]); then
        # Check if name field exists
        if grep -q '"name"' "$WORKING_DIR/package.json"; then
            # Update existing name
            sed -i "s/\"name\": \"[^\"]*\"/\"name\": \"$SESSION_NAME\"/" "$WORKING_DIR/package.json"
        else
            # Add name field after opening brace on first line only
            sed -i "1s/{/{\\n  \"name\": \"$SESSION_NAME\",/" "$WORKING_DIR/package.json"
        fi
        print_color $GREEN "✓ Updated package.json with project name: $SESSION_NAME"
    fi
    
    # Copy essential AI infrastructure (includes symlinks to global agents, agent_comms, and commands)
    # Skip for create-next-app method since it's handled earlier
    if ! ([ "$PROJECT_TYPE" = "nextjs" ] && [ "$NEXTJS_CREATE_METHOD" = "create-next-app" ]); then
        print_color $GREEN "Setting up AI infrastructure..."
        cp -r /home/wv3/claude-code-work/.claude "$WORKING_DIR/" 2>/dev/null && print_color $GREEN "✓ Copied .claude configuration with global symlinks"
        cp /home/wv3/claude-code-work/CLAUDE.md "$WORKING_DIR/" 2>/dev/null && print_color $GREEN "✓ Copied CLAUDE.md documentation"

        # Customize source app name in settings.json
        if [ -f "$WORKING_DIR/.claude/settings.json" ]; then
            sed -i "s/cc-hook-multi-agent-obvs/$SESSION_NAME/g" "$WORKING_DIR/.claude/settings.json"
            print_color $GREEN "✓ Customized source app name to: $SESSION_NAME"
        fi
    fi
    
    # Debug: List directory contents for Next.js template projects
    if [ "$PROJECT_TYPE" = "nextjs" ] && [ "$NEXTJS_CREATE_METHOD" = "template" ] && [ "$NEXTJS_TEMPLATE" != "minimal" ]; then
        print_color $YELLOW "\nProject directory contents:"
        ls -la "$WORKING_DIR" | head -10
    fi
    
    # Initialize generic project structure if not Next.js
    if [ "$PROJECT_TYPE" = "generic" ]; then
        mkdir -p "$WORKING_DIR"/{src,docs,scripts}
        
        # Create a project README
        cat > "$WORKING_DIR/README.md" << EOF
# $SESSION_NAME

Project created on $(date)

## Project Structure
- src/ - Source code
- docs/ - Documentation
- scripts/ - Utility scripts
- .claude/ - Claude AI configuration (agents, hooks, settings)

## Available Commands
- \`claude\` - Open Claude in project context
- \`ranger\` - File manager
- \`tmux\` - Terminal multiplexer
EOF
    fi
    
    print_color $GREEN "✓ Project structure created"
    
    # Debug: Show what templates were selected
    print_color $YELLOW "\n=== Debug: Template Variables ==="
    print_color $YELLOW "PROJECT_TYPE: $PROJECT_TYPE"
    print_color $YELLOW "VITE_TEMPLATE: $VITE_TEMPLATE"
    print_color $YELLOW "API_TEMPLATE: $API_TEMPLATE"
    print_color $YELLOW "REALTIME_TEMPLATE: $REALTIME_TEMPLATE"
    print_color $YELLOW "GAME_TEMPLATE: $GAME_TEMPLATE"
    print_color $YELLOW "=========================="
else
    WORKING_DIR="/home/wv3"
    print_color $BLUE "Using home directory: $WORKING_DIR"
fi

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    print_color $RED "Session '$SESSION_NAME' already exists!"
    print_color $YELLOW "Do you want to kill it and create a new one? (y/N)"
    read -r KILL_EXISTING
    if [[ $KILL_EXISTING =~ ^[Yy]$ ]]; then
        tmux kill-session -t "$SESSION_NAME"
    else
        print_color $RED "Exiting..."
        exit 1
    fi
fi

# Available applications
print_color $GREEN "\nAvailable applications:"
echo "1) Claude Code (Normal)"
echo "2) Claude Flow (in claude-flow directory)"
echo "3) Tmux Orchestrator (in Tmux-Orchestrator directory)"
echo "4) Carbonyl (Pretty Terminal Browser)"
echo "5) Lynx (Simple Terminal Browser)"
echo "6) Ranger (File Manager)"
echo "7) Empty Terminal"
echo "8) System Monitor (htop)"
echo "9) Blessed Monitor (Event Monitor)"
echo "10) Midnight Commander (mc)"
echo "11) Custom Command"
if [ "$PROJECT_TYPE" = "nextjs" ]; then
    echo "12) Next.js Dev Server (port $NEXTJS_PORT)"
    echo "13) API Server (port 4000-4099)"
fi
if [ "$PROJECT_TYPE" = "vite" ] || [ "$PROJECT_TYPE" = "realtime" ] || [ "$PROJECT_TYPE" = "game" ]; then
    echo "15) Vite Dev Server (port 5173)"
    echo "16) Node Server (backend - port 3001)"
fi
if [ "$PROJECT_TYPE" = "api" ]; then
    echo "17) API Server (port 3001)"
fi
echo "14) Port Monitor (show active ports/tunnels)"

# Get pane count
print_color $YELLOW "\nHow many panes do you want in your split view? (1-10):"
read -r PANE_COUNT

# Validate input
if ! [[ "$PANE_COUNT" =~ ^[0-9]+$ ]] || [ "$PANE_COUNT" -lt 1 ] || [ "$PANE_COUNT" -gt 10 ]; then
    print_color $RED "Please enter a number between 1 and 10"
    exit 1
fi

# Arrays to store configurations
declare -a COMMANDS
declare -a NAMES

# Ask about smart defaults for modern app types
USE_SMART_DEFAULTS="n"
FILE_MANAGER_PREF=""
SMART_PROJECT_TYPES="nextjs vite api realtime game"
if [[ " $SMART_PROJECT_TYPES " =~ " $PROJECT_TYPE " ]] && [ "$PANE_COUNT" -eq 4 ]; then
    print_color $YELLOW "\nUse smart defaults for $PROJECT_TYPE? (4 panes: Claude, File Manager, Terminal, Port Monitor) (Y/n):"
    read -r USE_SMART_DEFAULTS
    USE_SMART_DEFAULTS=${USE_SMART_DEFAULTS:-y}
fi

# Get configuration for each pane
for (( i=0; i<$PANE_COUNT; i++ )); do
    APP_CHOICE=""
    
    # Apply smart defaults if chosen
    if [[ $USE_SMART_DEFAULTS =~ ^[Yy]$ ]]; then
        case $i in
            0) APP_CHOICE=1 ;;  # Claude Code
            1) 
                # Ask for file manager preference
                if [ -z "$FILE_MANAGER_PREF" ]; then
                    print_color $YELLOW "File manager preference - Ranger (r) or Midnight Commander (m)? (default: r):"
                    read -r FILE_MANAGER_PREF
                    FILE_MANAGER_PREF=${FILE_MANAGER_PREF:-r}
                fi
                if [[ $FILE_MANAGER_PREF =~ ^[Mm]$ ]]; then
                    APP_CHOICE=10  # MC
                else
                    APP_CHOICE=6   # Ranger
                fi
                ;;
            2) APP_CHOICE=7 ;;  # Empty Terminal
            3) APP_CHOICE=14 ;; # Port Monitor
        esac
    fi
    
    if [ -z "$APP_CHOICE" ]; then
        print_color $YELLOW "\nPane $((i+1)) - Select application (1-14):"
        read -r APP_CHOICE
    fi
    
    case $APP_CHOICE in
        1)
            NAMES[$i]="Claude-Code"
            COMMANDS[$i]="cd $WORKING_DIR && claude"
            ;;
        2)
            NAMES[$i]="Claude-Flow"
            if [[ $IS_NEW_APP =~ ^[Yy]$ ]]; then
                COMMANDS[$i]="cd $WORKING_DIR && claude"
            else
                COMMANDS[$i]="cd /home/wv3/claude-code-work/claude-flow && claude"
            fi
            ;;
        3)
            NAMES[$i]="Tmux-Orch"
            if [[ $IS_NEW_APP =~ ^[Yy]$ ]]; then
                COMMANDS[$i]="cd $WORKING_DIR && claude"
            else
                COMMANDS[$i]="cd /home/wv3/claude-code-work/Tmux-Orchestrator && claude"
            fi
            ;;
        4)
            NAMES[$i]="Carbonyl"
            COMMANDS[$i]="cd /home/wv3/browsh/carbonyl-0.0.3 && ./carbonyl --no-sandbox https://google.com"
            ;;
        5)
            NAMES[$i]="Lynx"
            COMMANDS[$i]="lynx https://google.com"
            ;;
        6)
            NAMES[$i]="Ranger"
            COMMANDS[$i]="cd $WORKING_DIR && ranger --cmd='set show_hidden true'"
            ;;
        7)
            NAMES[$i]="Terminal"
            COMMANDS[$i]="cd $WORKING_DIR"
            ;;
        8)
            NAMES[$i]="Monitor"
            COMMANDS[$i]="htop"
            ;;
        9)
            NAMES[$i]="Blessed"
            # Check if monitor is already running
            if lsof -ti:4000 > /dev/null 2>&1; then
                print_color $YELLOW "⚠️  Monitor already running on port 4000"
                COMMANDS[$i]="echo 'Monitor already running! Check existing windows or use a different pane.'"
            else
                COMMANDS[$i]="cd /home/wv3/claude-code-work && npm run monitor"
            fi
            ;;
        10)
            NAMES[$i]="MC"
            COMMANDS[$i]="cd $WORKING_DIR && mc"
            ;;
        11)
            print_color $YELLOW "Enter custom pane name:"
            read -r CUSTOM_NAME
            print_color $YELLOW "Enter command to run (leave empty for shell):"
            read -r CUSTOM_CMD
            NAMES[$i]="${CUSTOM_NAME:-Custom}"
            COMMANDS[$i]="$CUSTOM_CMD"
            ;;
        12|15|16|17)
            # Unified project setup for all modern app types
            SETUP_NAME=""
            SETUP_COMMAND=""
            
            if [ "$APP_CHOICE" = "12" ] && [ "$PROJECT_TYPE" = "nextjs" ]; then
                NAMES[$i]="Next.js-Setup"
                if [ "$NEXTJS_CREATE_METHOD" = "template" ]; then
                    # Template method: copy template and install
                    if [ "$NEXTJS_TEMPLATE" = "minimal" ]; then
                        COMMANDS[$i]="cd $WORKING_DIR && echo 'Creating minimal Next.js app...' && cat > package.json << 'EOF'
{
  \"name\": \"$SESSION_NAME\",
  \"version\": \"0.1.0\",
  \"private\": true,
  \"scripts\": {
    \"dev\": \"next dev --port $NEXTJS_PORT\",
    \"build\": \"next build\",
    \"start\": \"next start\",
    \"lint\": \"next lint\"
  },
  \"dependencies\": {
    \"next\": \"15.1.4\",
    \"react\": \"^19.0.0\",
    \"react-dom\": \"^19.0.0\"
  },
  \"devDependencies\": {
    \"@types/node\": \"^20\",
    \"@types/react\": \"^19\",
    \"@types/react-dom\": \"^19\",
    \"typescript\": \"^5\"
  }
}
EOF
mkdir -p app && echo 'export default function Home() { return <h1>Hello Next.js!</h1> }' > app/page.tsx && echo 'export default function RootLayout({ children }) { return <html><body>{children}</body></html> }' > app/layout.tsx && echo 'Installing dependencies...' && npm install && echo && echo 'Setup complete! Run \"npm run dev\" to start the development server.'"
                    else
                        # Template already copied during wizard, just install dependencies
                        COMMANDS[$i]="cd $WORKING_DIR && echo 'Template: $NEXTJS_TEMPLATE' && echo 'Installing dependencies...' && npm install && echo && echo 'Setup complete! Run \"npm run dev\" to start the development server.'"
                    fi
                else
                    # create-next-app method - project already created, just start dev server
                    COMMANDS[$i]="cd $WORKING_DIR && npm run dev"
                fi
            elif [ "$APP_CHOICE" = "15" ] && ([ "$PROJECT_TYPE" = "vite" ] || [ "$PROJECT_TYPE" = "realtime" ] || [ "$PROJECT_TYPE" = "game" ]); then
                # Vite Dev Server
                NAMES[$i]="Vite-Dev"
                COMMANDS[$i]="cd $WORKING_DIR && echo 'Installing dependencies...' && npm install && echo && echo 'Starting Vite dev server...' && npm run client || npm run dev"
            elif [ "$APP_CHOICE" = "16" ] && ([ "$PROJECT_TYPE" = "vite" ] || [ "$PROJECT_TYPE" = "realtime" ] || [ "$PROJECT_TYPE" = "game" ]); then
                # Node Backend Server
                NAMES[$i]="Node-Server"
                COMMANDS[$i]="cd $WORKING_DIR && echo 'Installing dependencies...' && npm install && echo && echo 'Starting Node server...' && npm run server || npm run backend || npm run start"
            elif [ "$APP_CHOICE" = "17" ] && [ "$PROJECT_TYPE" = "api" ]; then
                # API Server
                NAMES[$i]="API-Server"
                COMMANDS[$i]="cd $WORKING_DIR && echo 'Installing dependencies...' && npm install && echo && echo 'Starting API server...' && npm run dev || npm run start"
            else
                print_color $RED "Application not available for $PROJECT_TYPE projects"
                NAMES[$i]="Terminal"
                COMMANDS[$i]="cd $WORKING_DIR"
            fi
            ;;
        13)
            NAMES[$i]="API-Server"
            # Find available API port
            API_PORT=$(find_available_port 4000 4099)
            if [ -z "$API_PORT" ]; then
                COMMANDS[$i]="echo 'No available ports in range 4000-4099'"
            else
                COMMANDS[$i]="cd $WORKING_DIR && echo 'API server would run on port $API_PORT'"
            fi
            ;;
        14)
            NAMES[$i]="Port-Monitor"
            COMMANDS[$i]="watch -n 2 'echo \"=== Active Ports ===\"; lsof -i -P -n | grep LISTEN | grep -E \":(3[0-9]{3}|4[0-9]{3})\" | sort -k2; echo; echo \"=== Cloudflare Tunnel Status ===\"; systemctl status cloudflared | grep -E \"Active:|tunnel\"'"
            ;;
        *)
            print_color $RED "Invalid choice, using empty terminal"
            NAMES[$i]="Terminal"
            COMMANDS[$i]="cd $WORKING_DIR"
            ;;
    esac
done

# Create the tmux session with first pane
print_color $BLUE "\nCreating tmux session '$SESSION_NAME' with split view..."
tmux new-session -d -s "$SESSION_NAME" -n "Multi-View" -c "$WORKING_DIR"

# Create the split layout if more than 1 pane
if [ $PANE_COUNT -gt 1 ]; then
    create_split_layout $PANE_COUNT
fi

# Send commands to each pane
for (( i=0; i<$PANE_COUNT; i++ )); do
    if [ ! -z "${COMMANDS[$i]}" ]; then
        print_color $GREEN "Setting up pane $((i+1)): ${NAMES[$i]}"
        tmux send-keys -t $SESSION_NAME:0.$i "${COMMANDS[$i]}" Enter
    else
        print_color $GREEN "Setting up pane $((i+1)): ${NAMES[$i]} (empty terminal)"
    fi
    
    # Set pane title (border)
    tmux select-pane -t $SESSION_NAME:0.$i -T "${NAMES[$i]}"
done

# Enable pane borders and titles
tmux set -t $SESSION_NAME pane-border-status top
tmux set -t $SESSION_NAME pane-border-format " #{pane_title} "

# Select first pane
tmux select-pane -t $SESSION_NAME:0.0

# Attach to session
print_color $BLUE "\nWorkspace ready! Attaching to session..."
sleep 1

# Check if we're already in tmux
if [ -n "$TMUX" ]; then
    print_color $YELLOW "You're already in a tmux session. Switch to the new session with:"
    print_color $GREEN "tmux switch-client -t $SESSION_NAME"
    print_color $YELLOW "\nOr detach current session (Ctrl+b d) and run 'wiz' again"
else
    tmux attach-session -t "$SESSION_NAME"
fi

# Show Next.js specific message
if [ "$PROJECT_TYPE" = "nextjs" ]; then
    print_color $YELLOW "\nNote: Next.js dependencies are installing in the dev server pane."
    print_color $GREEN "The dev server will start automatically once installation completes."
fi

# Save configuration for future use
save_view_config() {
    print_color $YELLOW "\nSave this configuration as a view? (y/N):"
    read -r SAVE_CONFIG
    
    if [[ $SAVE_CONFIG =~ ^[Yy]$ ]]; then
        print_color $YELLOW "Enter view name (no spaces):"
        read -r VIEW_NAME
        VIEW_NAME=${VIEW_NAME// /_}  # Replace spaces with underscores
        
        if [ ! -z "$VIEW_NAME" ]; then
            VIEW_FILE="/home/wv3/tmux-scripts/views/${VIEW_NAME}.sh"
            
            # Create the view script
            cat > "$VIEW_FILE" << EOF
#!/bin/bash
# Auto-generated view: $VIEW_NAME
# Created: $(date)

SESSION_NAME="\${1:-$VIEW_NAME}"

# Kill existing session if it exists
tmux kill-session -t "\$SESSION_NAME" 2>/dev/null || true

# Create session
tmux new-session -d -s "\$SESSION_NAME" -n "Multi-View"

EOF

            # Add split layout function and call
            if [ $PANE_COUNT -gt 1 ]; then
                # Copy the create_split_layout function
                echo "" >> "$VIEW_FILE"
                echo "# Create split layout" >> "$VIEW_FILE"
                echo "create_split_layout() {" >> "$VIEW_FILE"
                echo "    local pane_count=\$1" >> "$VIEW_FILE"
                echo "    case \$pane_count in" >> "$VIEW_FILE"
                echo "        2) tmux split-window -h -t \$SESSION_NAME:0 ;;" >> "$VIEW_FILE"
                echo "        3) tmux split-window -h -t \$SESSION_NAME:0" >> "$VIEW_FILE"
                echo "           tmux split-window -v -t \$SESSION_NAME:0.1 ;;" >> "$VIEW_FILE"
                echo "        4) tmux split-window -h -t \$SESSION_NAME:0" >> "$VIEW_FILE"
                echo "           tmux split-window -v -t \$SESSION_NAME:0.0" >> "$VIEW_FILE"
                echo "           tmux split-window -v -t \$SESSION_NAME:0.2 ;;" >> "$VIEW_FILE"
                echo "        *) for (( i=1; i<\$pane_count; i++ )); do" >> "$VIEW_FILE"
                echo "               tmux split-window -t \$SESSION_NAME:0" >> "$VIEW_FILE"
                echo "               tmux select-layout -t \$SESSION_NAME:0 tiled" >> "$VIEW_FILE"
                echo "           done ;;" >> "$VIEW_FILE"
                echo "    esac" >> "$VIEW_FILE"
                echo "}" >> "$VIEW_FILE"
                echo "" >> "$VIEW_FILE"
                echo "create_split_layout $PANE_COUNT" >> "$VIEW_FILE"
            fi
            
            # Add commands and titles
            echo "" >> "$VIEW_FILE"
            echo "# Send commands to panes" >> "$VIEW_FILE"
            for (( i=0; i<$PANE_COUNT; i++ )); do
                if [ ! -z "${COMMANDS[$i]}" ]; then
                    echo "tmux send-keys -t \$SESSION_NAME:0.$i '${COMMANDS[$i]}' Enter" >> "$VIEW_FILE"
                fi
                echo "tmux select-pane -t \$SESSION_NAME:0.$i -T '${NAMES[$i]}'" >> "$VIEW_FILE"
            done
            
            # Add final setup
            cat >> "$VIEW_FILE" << 'EOF'

# Enable pane borders and titles
tmux set -t $SESSION_NAME pane-border-status top
tmux set -t $SESSION_NAME pane-border-format " #{pane_title} "

# Select first pane and attach
tmux select-pane -t $SESSION_NAME:0.0

if [ -n "$TMUX" ]; then
    echo "Switch to session: tmux switch-client -t $SESSION_NAME"
else
    tmux attach-session -t $SESSION_NAME
fi
EOF
            
            chmod +x "$VIEW_FILE"
            print_color $GREEN "View saved as: $VIEW_FILE"
            print_color $YELLOW "Run it with: $VIEW_FILE [session_name]"
        fi
    fi
}

save_view_config

print_color $GREEN "\nTmux wizard complete! 🚀"
print_color $YELLOW "\nUseful keys:"
print_color $GREEN "  Ctrl+b → Arrow keys : Navigate between panes"
print_color $GREEN "  Ctrl+b z           : Zoom/unzoom current pane"
print_color $GREEN "  Ctrl+b space       : Cycle through layouts"
print_color $GREEN "  Ctrl+b d           : Detach from session"