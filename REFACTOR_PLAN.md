# Tmux Wizard Refactoring Plan

## Current State
- Monolithic script: 1,179 lines
- Mixed responsibilities: UI, project creation, tmux management, template selection
- Hard to test and maintain
- Specific to WillyV3's homelab setup

## Proposed Modular Structure

### Core Modules (`lib/`)

1. **`lib/ui.sh`** - User interface functions
   - `print_color()` - Colored output
   - `confirm_action()` - Y/N prompts  
   - `select_with_fzf()` - FZF selection wrapper
   - Progress indicators

2. **`lib/tmux-manager.sh`** - Tmux session management
   - `create_session()` - Session creation
   - `create_split_layout()` - Pane layouts
   - `check_existing_session()` - Session detection
   - `attach_to_session()` - Attach logic

3. **`lib/project-manager.sh`** - Project scaffolding
   - `create_project_directory()` - Directory setup
   - `setup_project_structure()` - File structure
   - `install_dependencies()` - Package management
   - `apply_template()` - Template application

4. **`lib/template-manager.sh`** - Template handling
   - `list_available_templates()` - Template discovery
   - `select_template()` - Template selection UI
   - `apply_nextjs_template()` - Next.js specific logic
   - `apply_generic_template()` - Generic project setup

5. **`lib/config.sh`** - Configuration management
   - Default settings
   - User preferences
   - Path management
   - Environment detection

### Scripts (`scripts/`)

1. **`scripts/create-nextjs-shadcn.sh`** - Next.js project creation (existing)
2. **`scripts/create-react-app.sh`** - React project creation
3. **`scripts/create-node-api.sh`** - Node.js API creation
4. **`scripts/create-python-app.sh`** - Python project creation

### Main Entry Point (`src/`)

1. **`src/tmux-wizard.sh`** - Main orchestrator (much smaller)
   - Load modules
   - Parse arguments
   - Coordinate workflow
   - Error handling

### Examples (`examples/`)

1. **`examples/nextjs-project.sh`** - Next.js project example
2. **`examples/api-project.sh`** - API project example  
3. **`examples/custom-layout.sh`** - Custom tmux layout

### Tests (`tests/`)

1. **`tests/test-ui.sh`** - UI function tests
2. **`tests/test-tmux.sh`** - Tmux management tests
3. **`tests/test-projects.sh`** - Project creation tests
4. **`tests/integration.sh`** - End-to-end tests

### Documentation (`docs/`)

1. **`docs/README.md`** - Main documentation
2. **`docs/API.md`** - Module API documentation
3. **`docs/CONTRIBUTING.md`** - Contribution guidelines
4. **`docs/EXAMPLES.md`** - Usage examples

## Benefits of Refactoring

1. **Modularity** - Each component has single responsibility
2. **Testability** - Individual modules can be tested
3. **Extensibility** - Easy to add new project types
4. **Maintainability** - Smaller, focused files
5. **Open Source Ready** - Clean, documented codebase
6. **Reusability** - Modules can be used independently

## Migration Strategy

1. Extract UI functions first (lowest risk)
2. Extract tmux management (medium risk)
3. Extract project creation logic (higher risk)
4. Create new main script that uses modules
5. Add comprehensive tests
6. Add documentation and examples

## Open Source Considerations

- Remove homelab-specific paths
- Make configuration flexible
- Add proper error handling
- Include installation script
- Add CI/CD pipeline
- Choose appropriate license (MIT?)