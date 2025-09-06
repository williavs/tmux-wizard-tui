#!/bin/bash
# Tmux Wizard - Template Management Module
# Handles template discovery, caching, and application

# Source UI functions
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# Template system configuration
readonly TEMPLATES_BASE_DIR="${TMUX_WIZARD_TEMPLATES_DIR:-$HOME/.tmux-wizard/templates}"
readonly TEMPLATES_CACHE_DIR="$TEMPLATES_BASE_DIR/.cache"
readonly TEMPLATES_INDEX_FILE="$TEMPLATES_CACHE_DIR/index.json"
readonly CURATED_TEMPLATES_FILE="$(dirname "${BASH_SOURCE[0]}")/../data/curated-templates.txt"

# Template sources configuration
declare -A TEMPLATE_SOURCES=(
    ["vercel-examples"]="https://github.com/vercel/next.js.git|examples"
    ["vercel-commerce"]="https://github.com/vercel/commerce.git|."
    ["clerk-templates"]="https://github.com/clerkinc/clerk-nextjs-examples.git|."
    ["shadcn-examples"]="https://github.com/shadcn-ui/ui.git|apps/www/registry/default/example"
)

# Initialize template system
init_template_system() {
    print_info "Initializing template system..."
    
    # Create necessary directories
    mkdir -p "$TEMPLATES_BASE_DIR" "$TEMPLATES_CACHE_DIR"
    
    # Copy curated templates if they don't exist
    if [[ ! -f "$TEMPLATES_CACHE_DIR/curated-templates.txt" && -f "$CURATED_TEMPLATES_FILE" ]]; then
        cp "$CURATED_TEMPLATES_FILE" "$TEMPLATES_CACHE_DIR/curated-templates.txt"
        print_success "Copied curated templates list"
    fi
    
    # Initialize empty index if it doesn't exist
    if [[ ! -f "$TEMPLATES_INDEX_FILE" ]]; then
        echo '{"templates":[],"last_updated":"","sources":{}}' > "$TEMPLATES_INDEX_FILE"
        print_success "Created template index"
    fi
}

# Get available templates (curated by default)
get_available_templates() {
    local mode=${1:-"curated"}  # curated, full, or remote
    local temp_file="/tmp/tmux_wizard_templates_$$.txt"
    
    case $mode in
        "curated")
            if [[ -f "$TEMPLATES_CACHE_DIR/curated-templates.txt" ]]; then
                cat "$TEMPLATES_CACHE_DIR/curated-templates.txt"
            else
                # Fallback to embedded curated list
                get_embedded_curated_templates
            fi
            ;;
        "full")
            get_local_templates
            ;;
        "remote")
            get_remote_templates
            ;;
        *)
            print_error "Invalid template mode: $mode"
            return 1
            ;;
    esac
}

# Get embedded curated templates (shipped with the tool)
get_embedded_curated_templates() {
    cat << 'EOF'
━━━ 🚀 POPULAR STARTERS ━━━
minimal                          | Clean Next.js 15 with TypeScript
app-router                       | Next.js 15 App Router Demo
blog                             | Blog with MDX and Tailwind
dashboard                        | Admin dashboard with Tailwind
api-routes                       | API routes examples
auth-example                     | Authentication example

━━━ 🎨 UI FRAMEWORKS ━━━
shadcn-dashboard                 | Dashboard with Shadcn/UI
tailwind-starter                 | Tailwind CSS starter
mui-nextjs                       | Material-UI with Next.js
chakra-ui                        | Chakra UI starter

━━━ 🔐 AUTHENTICATION ━━━
nextauth-example                 | NextAuth.js example
clerk-auth                       | Clerk authentication
supabase-auth                    | Supabase auth example

━━━ 💾 DATABASE EXAMPLES ━━━
prisma-example                   | Prisma ORM example
supabase-starter                 | Supabase starter
planetscale                      | PlanetScale example

━━━ 🛒 E-COMMERCE ━━━
commerce-starter                 | E-commerce with Stripe
shopify-starter                  | Shopify integration
marketplace                      | Marketplace template

━━━ 🤖 AI & MODERN ━━━
ai-chatbot                       | AI chatbot example
realtime-chat                    | Real-time chat app
streaming-example                | Streaming data example
EOF
}

# Select template using fzf
select_template() {
    local mode=${1:-"curated"}
    local prompt="Select Next.js Template"
    local header="↑↓ Navigate • Enter to select • Esc to cancel"
    
    init_template_system
    
    # Ask for template mode if not specified
    if [[ $mode == "interactive" ]]; then
        print_color $GREEN "Template Selection Mode:"
        print_color $YELLOW "1) Popular templates (curated, fast)"
        print_color $YELLOW "2) All local templates (if downloaded)"
        print_color $YELLOW "3) Browse remote templates (requires internet)"
        echo -n "Choice (1-3, default: 1): "
        read -r -t 10 MODE_CHOICE
        MODE_CHOICE=${MODE_CHOICE:-1}
        
        case $MODE_CHOICE in
            2) mode="full" ;;
            3) mode="remote" ;;
            *) mode="curated" ;;
        esac
    fi
    
    # Get templates based on mode
    local templates
    templates=$(get_available_templates "$mode")
    
    if [[ -z "$templates" ]]; then
        print_error "No templates found for mode: $mode"
        return 1
    fi
    
    # Show template count and search hints
    local template_count
    template_count=$(echo "$templates" | grep -v "━━━" | grep -c "|" || echo "0")
    print_color $GREEN "$template_count templates available"
    print_color $YELLOW "🔍 Search tips: type 'auth', 'blog', 'dashboard', 'ai', etc."
    echo
    
    # Use fzf for selection
    local selected
    selected=$(echo "$templates" | select_with_fzf "$prompt" "$templates" 15 "$header")
    local exit_code=$?
    
    case $exit_code in
        0)
            # Extract template name (before the |)
            echo "$selected" | awk -F' \\| ' '{print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
            return 0
            ;;
        2)
            print_info "Template selection cancelled"
            return 2
            ;;
        *)
            print_error "Template selection failed"
            return 1
            ;;
    esac
}

# Download template collections (bulk download)
download_template_collections() {
    print_info "Starting template collection download..."
    
    if ! confirm_action "This will download 200+ templates (~500MB). Continue?"; then
        print_info "Download cancelled"
        return 1
    fi
    
    init_template_system
    
    local total_sources=${#TEMPLATE_SOURCES[@]}
    local current=0
    
    for source_name in "${!TEMPLATE_SOURCES[@]}"; do
        current=$((current + 1))
        show_progress $current $total_sources "Downloading $source_name"
        
        download_template_source "$source_name" "${TEMPLATE_SOURCES[$source_name]}"
        
        if [[ $? -eq 0 ]]; then
            print_success "Downloaded $source_name"
        else
            print_warning "Failed to download $source_name (skipping)"
        fi
    done
    
    # Update index after all downloads
    update_template_index
    print_success "Template collection download complete!"
    print_info "You can now use 'full' mode for local template browsing"
}

# Download individual template source
download_template_source() {
    local source_name=$1
    local source_config=$2
    local repo_url=$(echo "$source_config" | cut -d'|' -f1)
    local subdir=$(echo "$source_config" | cut -d'|' -f2)
    local target_dir="$TEMPLATES_BASE_DIR/$source_name"
    
    # Skip if already exists and recent
    if [[ -d "$target_dir" ]]; then
        local age
        age=$(find "$target_dir" -maxdepth 0 -mtime +7 -print 2>/dev/null)
        if [[ -z "$age" ]]; then
            return 0  # Less than 7 days old, skip
        fi
    fi
    
    # Clone or update repository
    if [[ -d "$target_dir/.git" ]]; then
        # Update existing repo
        (cd "$target_dir" && git pull --quiet) 2>/dev/null || return 1
    else
        # Clone new repo
        rm -rf "$target_dir"
        git clone --quiet --depth 1 "$repo_url" "$target_dir" 2>/dev/null || return 1
    fi
    
    return 0
}

# Get local templates from downloaded collections
get_local_templates() {
    local temp_file="/tmp/tmux_wizard_local_templates_$$.txt"
    
    {
        echo "━━━ 📦 LOCAL COLLECTIONS ━━━"
        
        # Scan downloaded template directories
        if [[ -d "$TEMPLATES_BASE_DIR" ]]; then
            find "$TEMPLATES_BASE_DIR" -type d -name "*.json" -o -name "package.json" 2>/dev/null | while read -r template_dir; do
                local template_name
                template_name=$(basename "$(dirname "$template_dir")")
                local description="Local template"
                
                # Try to get description from package.json
                if [[ -f "$template_dir" && $(basename "$template_dir") == "package.json" ]]; then
                    description=$(grep '"description"' "$template_dir" 2>/dev/null | sed 's/.*"description":[[:space:]]*"\([^"]*\)".*/\1/' || echo "Local template")
                fi
                
                printf "%-30s | %s\n" "$template_name" "$description"
            done | sort
        fi
        
        echo "━━━ 🌟 CURATED FAVORITES ━━━"
        get_embedded_curated_templates | grep -v "━━━"
        
    } > "$temp_file"
    
    cat "$temp_file"
    rm -f "$temp_file"
}

# Get remote templates (GitHub API)
get_remote_templates() {
    print_info "Fetching remote templates..."
    
    local temp_file="/tmp/tmux_wizard_remote_templates_$$.txt"
    
    {
        echo "━━━ 🌐 REMOTE TEMPLATES ━━━"
        
        # Fetch from GitHub API (example - would need actual implementation)
        # This is a placeholder for remote template discovery
        echo "vercel/nextjs-dashboard        | Official Vercel Dashboard"
        echo "shadcn-ui/taxonomy             | Modern Next.js 13 starter"
        echo "steven-tey/precedent           | Opinionated Next.js starter"
        echo "nextui-org/nextui-dashboard    | NextUI Dashboard Template"
        
        echo ""
        echo "━━━ 🌟 ALWAYS AVAILABLE ━━━"
        get_embedded_curated_templates | grep -v "━━━"
        
    } > "$temp_file"
    
    cat "$temp_file"
    rm -f "$temp_file"
}

# Update template index for fast searching
update_template_index() {
    print_info "Updating template index..."
    
    local index_data='{"templates":[],"last_updated":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","sources":{}}'
    
    # Scan all template directories and build index
    if [[ -d "$TEMPLATES_BASE_DIR" ]]; then
        # This would build a comprehensive index for fast searching
        # Implementation would scan package.json files, extract metadata, etc.
        pass
    fi
    
    echo "$index_data" > "$TEMPLATES_INDEX_FILE"
    print_success "Template index updated"
}

# Get template info
get_template_info() {
    local template_name=$1
    
    # Try to find template in various locations
    local template_dirs=(
        "$TEMPLATES_BASE_DIR/vercel-examples/$template_name"
        "$TEMPLATES_BASE_DIR/clerk-templates/$template_name"
        "$TEMPLATES_BASE_DIR/$template_name"
    )
    
    for dir in "${template_dirs[@]}"; do
        if [[ -d "$dir" && -f "$dir/package.json" ]]; then
            echo "Found: $dir"
            echo "Description: $(grep '"description"' "$dir/package.json" 2>/dev/null | sed 's/.*"description":[[:space:]]*"\([^"]*\)".*/\1/')"
            echo "Dependencies: $(grep -A 20 '"dependencies"' "$dir/package.json" 2>/dev/null | grep -c '":"')"
            return 0
        fi
    done
    
    print_warning "Template '$template_name' not found locally. Use download_template_collections first."
    return 1
}

# Check if templates are available locally
has_local_templates() {
    [[ -d "$TEMPLATES_BASE_DIR" ]] && [[ $(find "$TEMPLATES_BASE_DIR" -name "package.json" 2>/dev/null | head -1) ]]
}

# Show template system status
show_template_status() {
    section_header "Template System Status"
    
    print_color $GREEN "Base Directory: $TEMPLATES_BASE_DIR"
    print_color $GREEN "Cache Directory: $TEMPLATES_CACHE_DIR"
    
    if has_local_templates; then
        local template_count
        template_count=$(find "$TEMPLATES_BASE_DIR" -name "package.json" 2>/dev/null | wc -l)
        print_success "$template_count local templates available"
    else
        print_info "No local template collections downloaded"
        print_info "Run download_template_collections() to get full collection"
    fi
    
    if [[ -f "$TEMPLATES_CACHE_DIR/curated-templates.txt" ]]; then
        local curated_count
        curated_count=$(grep -c "|" "$TEMPLATES_CACHE_DIR/curated-templates.txt" 2>/dev/null || echo "0")
        print_success "$curated_count curated templates available"
    else
        print_warning "Curated templates not found"
    fi
}