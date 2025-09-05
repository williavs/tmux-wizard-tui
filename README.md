# Tmux Wizard TUI 🧙

**Unix-style keyboard-driven tmux session manager with popup integration**

A minimal, focused TUI (Text User Interface) that transforms tmux session management into a delightful keyboard-driven experience. Built following Unix philosophy - simple, composable, and efficient.

## ✨ Key Features

- 🎯 **Unix-Style TUI** - Pure keyboard navigation with arrow keys
- 🪟 **Popup Integration** - Launch wizard in floating tmux popup window
- 🚀 **Next.js Projects** - Integrated create-next-app with template selection
- 📁 **Saved Sessions** - Browse and launch tmuxinator configs and saved scripts
- ⚡ **Session Management** - Create, switch, and manage tmux sessions
- 🎨 **Adaptive UI** - Compact mode for popups, full mode for terminals
- 🔧 **Multi-Pane Workspaces** - Configure 1-10 panes with custom applications

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/williavs/tmux-wizard-tui.git
cd tmux-wizard-tui
chmod +x src/tuiwiz.sh bin/popup-wizard
```

### 2. Add Popup Keybinding to ~/.tmux.conf
```bash
# Add this line to your tmux configuration
bind-key W display-popup -E -w 70% -h 60% -T "🧙 Tmux Wizard" "/path/to/tmux-wizard-tui/bin/popup-wizard"
```

### 3. Reload tmux config and use
```bash
tmux source-file ~/.tmux.conf
# Now press <prefix>W to launch wizard in popup!
```

## 🎮 Usage

### Popup Mode (Recommended)
- Press `<prefix>W` (where `<prefix>` is your tmux prefix key)
- Navigate with arrow keys `↑↓` 
- Select with `Enter`
- Go back with `←` or `h`
- Quit with `q`

### Terminal Mode
```bash
# Run directly in terminal
./src/tuiwiz.sh
```

## 🏗️ Architecture

```
tmux-wizard-tui/
├── bin/
│   └── popup-wizard           # Popup launcher script
├── src/
│   └── tuiwiz.sh             # Main TUI entry point
├── lib/
│   ├── tui.sh                # Core TUI implementation
│   ├── tmux-manager.sh       # Session management
│   ├── project-manager.sh    # Project scaffolding
│   ├── template-manager.sh   # Template handling
│   └── ui.sh                 # UI utilities
├── scripts/
│   ├── create-nextjs-shadcn.sh  # Next.js project creation
│   └── download-templates.sh    # Template management
├── data/
│   └── curated-templates.txt    # Next.js templates
└── obsolete/
    ├── tmux-wizard-monolith.sh  # Original monolithic version
    └── tmux-wizard.sh           # Legacy version
```

## 🎨 Project Types Supported

### Next.js Projects
- **create-next-app** - Official Next.js starter with TypeScript
- **Template Selection** - Choose from curated Next.js templates via fzf
- **Theme Selection** - Shadcn/UI themes with interactive selection
- **Multi-pane Setup** - Dev server, terminal, editor panes

### Generic Projects  
- **Multi-pane Workspaces** - 1-10 configurable panes
- **Custom Applications** - Terminal, editor, dev server options
- **Working Directory** - Specify project location

### Saved Sessions
- **Tmuxinator Configs** - Browse and launch existing tmuxinator sessions
- **Saved Scripts** - Launch previously saved tmux session scripts
- **Quick Access** - Fuzzy-find through all available sessions

## ⌨️ Keyboard Navigation

| Key | Action |
|-----|---------|
| `↑↓` | Navigate menu items |
| `Enter` | Select/confirm option |
| `←` or `h` | Go back |
| `q` | Quit wizard |
| `?` | Help (terminal mode only) |

## 🔧 Configuration

### Tmux Integration
The wizard integrates seamlessly with any tmux prefix:
```bash
# Works with default prefix (C-b)
bind-key W display-popup -E -w 70% -h 60% -T "🧙 Tmux Wizard" "/path/to/bin/popup-wizard"

# Works with custom prefix (C-a)
set-option -g prefix C-a
bind-key W display-popup -E -w 70% -h 60% -T "🧙 Tmux Wizard" "/path/to/bin/popup-wizard"
```

### Popup Customization
Modify popup size and appearance:
```bash
# Larger popup
bind-key W display-popup -E -w 85% -h 75% -T "🧙 Tmux Wizard" "/path/to/bin/popup-wizard"

# Custom title
bind-key W display-popup -E -w 70% -h 60% -T "My Wizard" "/path/to/bin/popup-wizard"
```

## 🎯 Design Philosophy

**Unix Philosophy**: Do one thing well
- Single-purpose tool for tmux session management
- Keyboard-driven interface (no mouse required)
- Composable with existing tmux workflows
- Minimal dependencies

**TUI Principles**: 
- Consistent navigation patterns
- Visual feedback for all actions
- Responsive design (adapts to terminal size)
- Graceful error handling

**Modern Integration**:
- Popup mode for quick access
- Automatic session switching
- Template-based project creation
- Saved session management

## 📋 Requirements

- **tmux** - Terminal multiplexer (tested with 3.0+)
- **bash** - Shell scripting (4.0+)
- **fzf** - Fuzzy finder for selections
- **tput** - Terminal control

Optional:
- **Node.js** - For Next.js project creation
- **tmuxinator** - For saved session configs

## 🚦 Advanced Usage

### Custom Templates
Add your own Next.js templates to `data/curated-templates.txt`:
```
my-template | Custom template description
another-template | Another custom template
```

### Integration with Existing Workflows
```bash
# Use in scripts
echo "nextjs" | ./src/tuiwiz.sh --batch-mode

# Chain with other commands
./src/tuiwiz.sh && tmux list-sessions
```

### Saved Sessions Directory Structure
```
~/.config/tmuxinator/    # Tmuxinator configs
~/tmux-scripts/views/    # Saved session scripts
```

## 🐛 Troubleshooting

### Popup Not Closing
Ensure you're using the `-E` flag in your tmux keybinding:
```bash
# Correct - popup closes automatically
bind-key W display-popup -E -w 70% -h 60% -T "🧙 Tmux Wizard" "/path/to/bin/popup-wizard"

# Incorrect - popup stays open
bind-key W display-popup -w 70% -h 60% -T "🧙 Tmux Wizard" "/path/to/bin/popup-wizard"
```

### Session Creation Issues
Check that tmux can create sessions:
```bash
# Test session creation manually
tmux new-session -d -s test-session
tmux list-sessions
tmux kill-session -t test-session
```

### Template Selection Problems
Verify fzf is installed and working:
```bash
# Test fzf
echo -e "option1\noption2\noption3" | fzf
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **tmux** - The terminal multiplexer that makes this all possible
- **fzf** - Fuzzy finder for beautiful selections
- **Next.js** - The React framework we integrate with
- **Unix philosophy** - Inspiration for the design approach

## 📈 Version History

- **v2.0.0** (2025-09) - TUI rewrite with popup integration
- **v1.0.0** - Original monolithic shell script version

---

**Made with ❤️ for tmux power users**

*Press `<prefix>W` and let the magic begin! 🧙*