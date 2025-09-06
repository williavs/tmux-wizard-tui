#!/bin/bash
# Tmux Wizard - Project Management Module
# Handles project directory creation, template application, and setup

# Source UI and template manager
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# Project configuration
readonly DEFAULT_PROJECT_DIR="${TMUX_WIZARD_PROJECTS_DIR:-$HOME}"
readonly AI_INFRASTRUCTURE_SOURCE="${TMUX_WIZARD_AI_SOURCE:-$HOME/claude-code-work}"

# Project creation settings
PROJECT_TYPE=""
SESSION_NAME=""
WORKING_DIR=""
PROJECT_METHOD=""

# Set project variables
set_project_vars() {
    PROJECT_TYPE="$1"
    SESSION_NAME="$2"
    PROJECT_METHOD="${3:-template}"
    WORKING_DIR="$DEFAULT_PROJECT_DIR/$SESSION_NAME"
}

# Check if directory exists and is empty
check_directory_clean() {
    local dir_path="$1"
    
    if [[ -d "$dir_path" ]]; then
        if [[ -n "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
            print_warning "Directory $dir_path already exists and is not empty!"
            if confirm_action "Delete it and continue?"; then
                rm -rf "$dir_path"
                print_success "Removed existing directory"
                return 0
            else
                print_error "Cannot create project in non-empty directory"
                return 1
            fi
        fi
    fi
    
    return 0
}

# Create project directory
create_project_directory() {
    local project_dir="$1"
    local project_type="$2"
    
    if [[ -z "$project_dir" ]]; then
        print_error "Project directory path is required"
        return 1
    fi
    
    # Check if directory is clean
    if ! check_directory_clean "$project_dir"; then
        return 1
    fi
    
    # Create directory structure based on project type
    case "$project_type" in
        "nextjs")
            # Next.js projects will be created by external tools
            print_info "Directory will be created by Next.js setup"
            ;;
        "generic")
            print_info "Creating generic project structure..."
            mkdir -p "$project_dir"/{src,docs,scripts,tests}
            create_generic_project_files "$project_dir"
            ;;
        *)
            print_info "Creating basic project directory..."
            mkdir -p "$project_dir"
            ;;
    esac
    
    return 0
}

# Create generic project files
create_generic_project_files() {
    local project_dir="$1"
    local project_name
    project_name=$(basename "$project_dir")
    
    # Create basic README
    cat > "$project_dir/README.md" << EOF
# $project_name

A new project created with Tmux Wizard.

## Getting Started

This is a generic project template. Customize it for your needs:

- \`src/\` - Source code
- \`docs/\` - Documentation
- \`scripts/\` - Build and utility scripts
- \`tests/\` - Test files

## Development

Add your development instructions here.

## Contributing

Add contribution guidelines here.
EOF

    # Create basic .gitignore
    cat > "$project_dir/.gitignore" << EOF
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
*.swp
*.swo
*~
.vim/
.vscode/
.idea/

# Build outputs
dist/
build/
*.log

# Dependencies
node_modules/
EOF

    # Create basic project structure files
    echo "// Add your source code here" > "$project_dir/src/index.js"
    echo "# Project Documentation" > "$project_dir/docs/index.md"
    echo "# Test your project here" > "$project_dir/tests/README.md"
    
    touch "$project_dir/scripts/.gitkeep"
    
    print_success "Created generic project structure"
}

# Setup AI infrastructure (Claude Code integration)
setup_ai_infrastructure() {
    local project_dir="$1"
    local project_name="$2"
    
    if [[ ! -d "$AI_INFRASTRUCTURE_SOURCE/.claude" ]]; then
        print_info "AI infrastructure source not found, skipping"
        return 0
    fi
    
    print_info "Setting up AI infrastructure..."
    
    # Copy Claude configuration
    if cp -r "$AI_INFRASTRUCTURE_SOURCE/.claude" "$project_dir/" 2>/dev/null; then
        print_success "✓ Copied .claude configuration"
    else
        print_warning "Failed to copy .claude configuration"
    fi
    
    # Copy documentation
    if [[ -f "$AI_INFRASTRUCTURE_SOURCE/CLAUDE.md" ]]; then
        if cp "$AI_INFRASTRUCTURE_SOURCE/CLAUDE.md" "$project_dir/" 2>/dev/null; then
            print_success "✓ Copied CLAUDE.md documentation"
        else
            print_warning "Failed to copy CLAUDE.md"
        fi
    fi
    
    # Customize project name in settings
    local settings_file="$project_dir/.claude/settings.json"
    if [[ -f "$settings_file" ]]; then
        # Replace generic project name with actual project name
        sed -i "s/cc-hook-multi-agent-obvs/$project_name/g" "$settings_file" 2>/dev/null || true
        sed -i "s/claude-code-work/$project_name/g" "$settings_file" 2>/dev/null || true
        print_success "✓ Customized settings for: $project_name"
    fi
    
    return 0
}

# Create Next.js project using external script
create_nextjs_project() {
    local project_name="$1"
    local project_dir="$2"
    local template_name="${3:-minimal}"
    local theme_name="${4:-}"
    
    local nextjs_script="$(dirname "${BASH_SOURCE[0]}")/../scripts/create-nextjs-shadcn.sh"
    
    if [[ ! -f "$nextjs_script" ]]; then
        print_error "Next.js creation script not found: $nextjs_script"
        return 1
    fi
    
    print_info "Creating Next.js project with Shadcn UI..."
    
    # Call the external script
    if [[ -n "$theme_name" ]]; then
        "$nextjs_script" "$project_name" "$(dirname "$project_dir")" "$theme_name"
    else
        "$nextjs_script" "$project_name" "$(dirname "$project_dir")"
    fi
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        if [[ -n "$theme_name" ]]; then
            print_success "✓ Next.js app created with $theme_name theme!"
        else
            print_success "✓ Next.js app created with default setup!"
        fi
        return 0
    else
        print_error "Failed to create Next.js project"
        return 1
    fi
}

# Update package.json with project name
update_package_json() {
    local project_dir="$1"
    local project_name="$2"
    local package_file="$project_dir/package.json"
    
    if [[ ! -f "$package_file" ]]; then
        return 0  # No package.json to update
    fi
    
    print_info "Updating package.json with project name..."
    
    # Check if name field exists
    if grep -q '"name"' "$package_file"; then
        # Update existing name field
        sed -i "s/\"name\":[[:space:]]*\"[^\"]*\"/\"name\": \"$project_name\"/" "$package_file"
    else
        # Add name field after opening brace
        sed -i "1s/{/{\\n  \"name\": \"$project_name\",/" "$package_file"
    fi
    
    print_success "✓ Updated package.json with project name: $project_name"
}

# Apply template from local collection
apply_local_template() {
    local template_path="$1"
    local project_dir="$2"
    
    if [[ ! -d "$template_path" ]]; then
        print_error "Template not found: $template_path"
        return 1
    fi
    
    print_info "Applying template from: $template_path"
    
    # Copy template files (excluding .git and node_modules)
    rsync -av --exclude='.git' --exclude='node_modules' --exclude='.next' \
          "$template_path/" "$project_dir/" 2>/dev/null || {
        print_error "Failed to copy template files"
        return 1
    }
    
    print_success "✓ Template applied successfully"
    return 0
}

# Create complete project
create_project() {
    local project_type="$1"
    local project_name="$2"
    local project_method="${3:-template}"
    local template_or_theme="${4:-}"
    
    # Set up project variables
    set_project_vars "$project_type" "$project_name" "$project_method"
    
    print_info "Creating $project_type project: $project_name"
    
    case "$project_type" in
        "nextjs")
            case "$project_method" in
                "create-next-app"|"shadcn")
                    # Use external script for full Next.js setup
                    if ! create_nextjs_project "$project_name" "$WORKING_DIR" "minimal" "$template_or_theme"; then
                        return 1
                    fi
                    ;;
                "template")
                    # Create directory first, then apply template
                    if ! create_project_directory "$WORKING_DIR" "$project_type"; then
                        return 1
                    fi
                    
                    if [[ -n "$template_or_theme" ]]; then
                        # Apply specific template
                        local template_path="$HOME/templates/vercel/nextjs-examples/$template_or_theme"
                        if ! apply_local_template "$template_path" "$WORKING_DIR"; then
                            # Fallback to minimal Next.js
                            create_minimal_nextjs "$WORKING_DIR"
                        fi
                    else
                        # Create minimal Next.js project
                        create_minimal_nextjs "$WORKING_DIR"
                    fi
                    ;;
            esac
            ;;
        "generic")
            if ! create_project_directory "$WORKING_DIR" "$project_type"; then
                return 1
            fi
            ;;
        *)
            print_warning "Unknown project type: $project_type, creating generic project"
            if ! create_project_directory "$WORKING_DIR" "generic"; then
                return 1
            fi
            ;;
    esac
    
    # Setup AI infrastructure (if not already done by external scripts)
    if [[ "$project_method" != "create-next-app" ]]; then
        setup_ai_infrastructure "$WORKING_DIR" "$project_name"
    fi
    
    # Update package.json if it exists
    update_package_json "$WORKING_DIR" "$project_name"
    
    print_success "Project creation complete: $WORKING_DIR"
    return 0
}

# Create minimal Next.js project structure
create_minimal_nextjs() {
    local project_dir="$1"
    
    print_info "Creating minimal Next.js project..."
    
    # Create package.json
    cat > "$project_dir/package.json" << EOF
{
  "name": "$(basename "$project_dir")",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "15.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@types/react": "^18.0.0",
    "@types/react-dom": "^18.0.0",
    "eslint": "^8.0.0",
    "eslint-config-next": "15.0.0",
    "typescript": "^5.0.0"
  }
}
EOF

    # Create app directory structure
    mkdir -p "$project_dir/app"
    
    # Create root layout
    cat > "$project_dir/app/layout.tsx" << 'EOF'
export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
EOF

    # Create home page
    cat > "$project_dir/app/page.tsx" << 'EOF'
export default function Home() {
  return (
    <main>
      <h1>Hello Next.js!</h1>
      <p>Your project is ready to go.</p>
    </main>
  )
}
EOF

    # Create next.config.js
    cat > "$project_dir/next.config.js" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {}

module.exports = nextConfig
EOF

    # Create tsconfig.json
    cat > "$project_dir/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

    print_success "✓ Minimal Next.js project created"
}

# Get project working directory
get_working_dir() {
    echo "$WORKING_DIR"
}

# Check if project was created successfully  
validate_project() {
    local project_dir="$1"
    local project_type="$2"
    
    if [[ ! -d "$project_dir" ]]; then
        print_error "Project directory not found: $project_dir"
        return 1
    fi
    
    case "$project_type" in
        "nextjs")
            if [[ ! -f "$project_dir/package.json" ]]; then
                print_error "Next.js project validation failed: no package.json"
                return 1
            fi
            ;;
        "generic")
            if [[ ! -f "$project_dir/README.md" ]]; then
                print_error "Generic project validation failed: no README.md"
                return 1
            fi
            ;;
    esac
    
    print_success "✓ Project validation passed"
    return 0
}