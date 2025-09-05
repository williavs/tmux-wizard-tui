# Tmux Wizard 🧙‍♂️

**A powerful, modular tmux workspace orchestrator for developers**

Tmux Wizard transforms the tedious process of setting up development environments into a delightful, interactive experience. With fuzzy-finding, intelligent templates, and modular architecture, it creates perfectly configured tmux workspaces in seconds.

## ✨ Features

- 🎯 **Interactive Project Selection** - Fuzzy-find templates with fzf
- 🚀 **Next.js Integration** - Built-in Shadcn/UI themes and templates  
- 🔧 **Modular Architecture** - Clean, testable, extensible codebase
- 🎨 **Beautiful UI** - Colored output and progress indicators
- ⚡ **Lightning Fast** - Optimized for developer workflow
- 🧪 **Fully Tested** - Comprehensive test suite
- 📦 **Zero Config** - Works out of the box with sensible defaults

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/tmux-wizard.git
cd tmux-wizard

# Make it executable
chmod +x src/tmux-wizard.sh

# Run the wizard
./src/tmux-wizard.sh
```

## 📋 Requirements

- **tmux** - Terminal multiplexer
- **fzf** - Fuzzy finder for interactive selections
- **bash** - Shell scripting (4.0+)
- **git** - Version control (for project templates)

Optional but recommended:
- **Node.js** - For Next.js/React projects
- **Python** - For Python projects  
- **Docker** - For containerized workflows

## 🎮 Usage Examples

### Create a Next.js Project with Shadcn/UI
```bash
./src/tmux-wizard.sh
# Select "Next.js Project"
# Choose your favorite theme with fzf
# Wizard creates project + tmux session automatically
```

### Set Up API Development Environment
```bash
./src/tmux-wizard.sh
# Select "Node.js API"
# Wizard sets up Express + testing + docs panes
```

### Custom Multi-Pane Workspace
```bash
./src/tmux-wizard.sh
# Choose number of panes (1-10)
# Select applications for each pane
# Intelligent layout optimization
```

## 🏗️ Architecture

Tmux Wizard uses a modular architecture for maintainability and extensibility:

```
tmux-wizard/
├── src/
│   └── tmux-wizard.sh      # Main entry point
├── lib/
│   ├── ui.sh               # User interface functions
│   ├── tmux-manager.sh     # Tmux session management
│   ├── project-manager.sh  # Project scaffolding
│   ├── template-manager.sh # Template handling
│   └── config.sh           # Configuration management
├── scripts/
│   ├── create-nextjs-shadcn.sh  # Next.js creation
│   └── ...                     # Additional project types
├── tests/
│   └── *.sh               # Test suite
└── docs/
    └── *.md               # Documentation
```

## 🎨 Supported Project Types

- **Next.js** - Full-stack React framework with Shadcn/UI themes
- **React** - Client-side React applications
- **Node.js API** - Express.js REST APIs
- **Python** - Flask/Django applications  
- **Static Sites** - HTML/CSS/JS projects
- **Generic** - Any project type with custom configuration

## 🔧 Configuration

Tmux Wizard works with zero configuration, but supports customization:

```bash
# Create config file
cp examples/config.example.sh ~/.tmux-wizard-config

# Edit your preferences
vim ~/.tmux-wizard-config
```

### Available Options

- **Default project directory** - Where to create projects
- **Preferred applications** - Default apps for panes
- **Theme preferences** - UI colors and styling
- **Template locations** - Custom template sources

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
./tests/run-all-tests.sh

# Run specific module tests
./tests/test-ui.sh
./tests/test-tmux.sh
./tests/test-projects.sh

# Integration tests
./tests/integration.sh
```

## 📚 Documentation

- [API Documentation](docs/API.md) - Module interfaces and functions
- [Contributing Guide](docs/CONTRIBUTING.md) - How to contribute
- [Examples](docs/EXAMPLES.md) - Usage examples and recipes
- [Changelog](CHANGELOG.md) - Version history

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/CONTRIBUTING.md) for details.

### Quick Contribution Steps

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for your changes
5. Run the test suite (`./tests/run-all-tests.sh`)
6. Commit your changes (`git commit -m 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [fzf](https://github.com/junegunn/fzf) - Amazing fuzzy finder
- [tmux](https://github.com/tmux/tmux) - Terminal multiplexer
- [Shadcn/UI](https://ui.shadcn.com/) - Beautiful UI components

## 🐛 Bug Reports & Feature Requests

Please use the [GitHub Issues](https://github.com/yourusername/tmux-wizard/issues) page to report bugs or request features.

## ⭐ Star History

If you find this project helpful, please consider giving it a star!

---

**Made with ❤️ by developers, for developers**