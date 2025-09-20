#!/usr/bin/env bash

# Cursor AI Code Editor Installation Script
# This script installs Cursor using the official installation method
# Compatible with both bash and zsh shells

# Detect shell and set compatibility
if [[ -n "${ZSH_VERSION:-}" ]]; then
    # Zsh compatibility
    setopt shwordsplit
    setopt pipefail
    setopt errexit
    setopt nounset
else
    # Bash compatibility
    set -euo pipefail
fi

echo "🚀 Installing Cursor AI Code Editor..."
echo "====================================="

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "❌ Error: curl is required but not installed."
    echo "Please install curl first:"
    echo "  Ubuntu/Debian: sudo apt update && sudo apt install curl"
    echo "  CentOS/RHEL: sudo yum install curl"
    echo "  macOS: curl should be pre-installed"
    exit 1
fi

# Run the official Cursor installation command
echo "📥 Downloading and installing Cursor..."
echo "⚠️  Note: This will install Cursor AI Code Editor"

# Try to run installation with automatic responses
if curl https://cursor.com/install -fsS | bash; then
    echo "✅ Installation completed successfully"
else
    echo "❌ Installation failed"
    exit 1
fi

echo ""
echo "✅ Cursor AI Code Editor installation completed!"

# Configure PATH automatically
echo "🔧 Configuring PATH for Cursor Agent..."

# Detect shell and set appropriate config file
if [[ -n "${ZSH_VERSION:-}" ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
    SHELL_NAME="zsh"
else
    SHELL_CONFIG="$HOME/.bashrc"
    SHELL_NAME="bash"
fi

# Add ~/.local/bin to PATH if not already present
PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
if ! grep -q '\.local/bin' "$SHELL_CONFIG" 2>/dev/null; then
    echo "📝 Adding ~/.local/bin to PATH in $SHELL_CONFIG"
    echo "$PATH_EXPORT" >> "$SHELL_CONFIG"
    echo "✅ PATH configuration added to $SHELL_CONFIG"
else
    echo "✅ PATH configuration already exists in $SHELL_CONFIG"
fi

# Add to current session PATH immediately
export PATH="$HOME/.local/bin:$PATH"

# Also add to current shell's environment for immediate use
if [[ -n "${ZSH_VERSION:-}" ]]; then
    # For zsh - add to current session
    export PATH="$HOME/.local/bin:$PATH"
    # Also try to source the config if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        source "$HOME/.zshrc" 2>/dev/null || true
    fi
else
    # For bash - add to current session
    export PATH="$HOME/.local/bin:$PATH"
    # Also try to source the config if it exists
    if [[ -f "$HOME/.bashrc" ]]; then
        source "$HOME/.bashrc" 2>/dev/null || true
    fi
fi

echo "✅ PATH configured for immediate use in current session"

# Try to verify installation
echo "🔍 Verifying installation..."

# Check if cursor binary exists in common locations
CURSOR_PATHS=(
    "/usr/local/bin/cursor"
    "/opt/cursor/cursor"
    "/home/$USER/.local/bin/cursor"
    "/home/$USER/cursor/cursor"
)

CURSOR_FOUND=false
for path in "${CURSOR_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        echo "✅ Cursor binary found: $path"
        CURSOR_FOUND=true
        
        # Try to add to PATH temporarily for verification
        export PATH="$(dirname "$path"):$PATH"
        
        if command -v cursor &> /dev/null; then
            echo "✅ Cursor command accessible: $(which cursor)"
            if cursor --version &> /dev/null; then
                echo "✅ Cursor version: $(cursor --version)"
            else
                echo "⚠️  Cursor installed but version check failed"
            fi
        else
            echo "⚠️  Cursor binary exists but not in PATH"
        fi
        break
    fi
done

if [[ "$CURSOR_FOUND" == false ]]; then
    echo "⚠️  Cursor binary not found in common locations"
    echo "   Installation may have succeeded but binary location is unknown"
    echo "   Try running 'cursor' command or check your desktop applications"
fi

# Check for cursor-agent command
echo "🤖 Checking for Cursor Agent..."
if command -v cursor-agent &> /dev/null; then
    echo "✅ Cursor Agent is accessible from command line"
    if cursor-agent --version &> /dev/null; then
        echo "✅ Cursor Agent version: $(cursor-agent --version)"
        echo "✅ Cursor Agent ready to use immediately!"
    else
        echo "⚠️  Cursor Agent installed but version check failed"
    fi
else
    echo "⚠️  Cursor Agent not accessible from command line"
    echo "   Make sure ~/.local/bin is in your PATH"
fi

# Verify PATH is working immediately
echo "🔍 Verifying immediate PATH availability..."
if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    echo "✅ ~/.local/bin is in current session PATH"
    echo "✅ Commands should be available immediately"
else
    echo "⚠️  ~/.local/bin not found in current PATH"
    echo "   You may need to restart your terminal or run: source $SHELL_CONFIG"
fi

# Check if cursor is available as a command
if command -v cursor &> /dev/null; then
    echo "✅ Cursor is accessible from command line"
else
    echo "⚠️  Cursor not accessible from command line"
    echo "   This is normal for GUI applications - check your applications menu"
fi

echo ""
echo "📋 Next steps:"
echo "1. ✅ PATH already configured for immediate use!"
echo "   Commands are available right now in this session"
echo ""
echo "2. ✅ Verify Cursor Agent installation:"
echo "   cursor-agent --version"
echo ""
echo "3. ✅ Start using Cursor Agent immediately:"
echo "   cursor-agent"
echo ""
echo "4. For GUI application:"
echo "   - Look for Cursor in your applications menu"
echo "   - Launch Cursor from the desktop environment"
echo "   - Sign in with your account to access AI features"
echo ""
echo "5. For new terminal sessions:"
if [[ -n "${ZSH_VERSION:-}" ]]; then
    echo "   PATH is saved in ~/.zshrc for future sessions"
    echo "💡 Shell detected: zsh"
else
    echo "   PATH is saved in ~/.bashrc for future sessions"
    echo "💡 Shell detected: bash"
fi
echo ""
echo "6. Start coding with AI assistance!"
echo ""
echo "🎉 Happy coding with Cursor AI!"
