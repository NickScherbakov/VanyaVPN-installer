#!/bin/bash
# VanyaVPN System Installation Script by Comrade

# ===== CONFIGURATION =====
APP_NAME="VanyaVPN"
APPIMAGE_SOURCE="$HOME/Downloads/VanyaVPN.AppImage"
INSTALL_DIR="/opt/$APP_NAME"
BIN_SYMLINK="/usr/local/bin/vanyavpn"
DESKTOP_FILE="/usr/share/applications/vanyavpn.desktop"
ICON_NAME="network-vpn"  # Fallback icon (change if you have specific icon)

# ===== INSTALLATION =====
echo "🛠️ Installing $APP_NAME as system application..."

# 1. Verify AppImage exists
if [ ! -f "$APPIMAGE_SOURCE" ]; then
    echo "❌ Error: $APPIMAGE_SOURCE not found!"
    exit 1
fi

# 2. Create installation directory
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"  # Avoid needing sudo for updates

# 3. Move and make executable
echo "📦 Moving AppImage to $INSTALL_DIR..."
mv "$APPIMAGE_SOURCE" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/VanyaVPN.AppImage"

# 4. Create desktop integration
echo "🎨 Creating desktop menu entry..."
cat <<EOF | sudo tee "$DESKTOP_FILE" >/dev/null
[Desktop Entry]
Name=$APP_NAME
Comment=Secure VPN Client
Exec="$INSTALL_DIR/VanyaVPN.AppImage" --no-sandbox
Icon=$ICON_NAME
Terminal=false
Type=Application
Categories=Network;Security;VPN;
StartupWMClass=$APP_NAME
EOF

# 5. Create terminal symlink
echo "🔗 Creating terminal command..."
sudo ln -sf "$INSTALL_DIR/VanyaVPN.AppImage" "$BIN_SYMLINK"

# 6. Update databases
echo "🔄 Updating system databases..."
sudo update-desktop-database
sudo ldconfig

# ===== SANDBOX FIX =====
# Try to extract and fix sandbox if needed
echo "🔒 Attempting sandbox configuration..."
TEMP_DIR=$(mktemp -d)
"$INSTALL_DIR/VanyaVPN.AppImage" --appimage-extract --destination="$TEMP_DIR" &>/dev/null

if [ -f "$TEMP_DIR/chrome-sandbox" ]; then
    echo "🛡️ Found Chromium sandbox - configuring..."
    sudo chown root:root "$TEMP_DIR/chrome-sandbox"
    sudo chmod 4755 "$TEMP_DIR/chrome-sandbox"
    
    # Repackage if sandbox was found
    if command -v appimagetool &>/dev/null; then
        echo "📦 Repackaging with fixed sandbox..."
        appimagetool "$TEMP_DIR" "$INSTALL_DIR/VanyaVPN-Fixed.AppImage"
        mv "$INSTALL_DIR/VanyaVPN-Fixed.AppImage" "$INSTALL_DIR/VanyaVPN.AppImage"
        chmod +x "$INSTALL_DIR/VanyaVPN.AppImage"
    else
        echo "ℹ️ Install 'appimagetool' to permanently fix sandbox:"
        echo "   sudo apt install appimagetool"
    fi
fi
rm -rf "$TEMP_DIR"

# ===== AUTOSTART OPTION =====
read -p "🤔 Enable autostart on login? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⚡ Enabling autostart..."
    mkdir -p "$HOME/.config/autostart"
    cp "$DESKTOP_FILE" "$HOME/.config/autostart/"
fi

# ===== COMPLETION =====
echo ""
echo "✅ Installation complete!"
echo "   You can now:"
echo "   1. Launch from your application menu"
echo "   2. Run 'vanyavpn' in terminal"
echo "   3. Reboot to test autostart (if enabled)"

exit 0