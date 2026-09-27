#!/bin/bash
# ==============================================================================
# Script to set up Kanata as a user-level service (Official Guide Recommendation)
# ==============================================================================

set -euo pipefail

# CHECK FOR ROOT/SUDO
if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script must be run with sudo to configure udev rules and groups." >&2
  exit 1
fi

if [ -z "$SUDO_USER" ]; then
  echo "[ERROR] Please run this script with sudo (e.g. sudo ./kanata_setup_ubuntu.sh)." >&2
  exit 1
fi

REAL_USER="$SUDO_USER"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
USER_KANATA_CONFIG_SRC="$SCRIPT_DIR/kanata_config_ubuntu.kbd"

if [ ! -f "$USER_KANATA_CONFIG_SRC" ]; then
    echo "[ERROR] Kanata config file not found at: $USER_KANATA_CONFIG_SRC" >&2
    exit 1
fi

# 1. Groups & udev rules
echo "[INFO] Setting up uinput group and udev rules..."
groupadd -f uinput
echo 'KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"' > /etc/udev/rules.d/50-kanata.rules
udevadm control --reload-rules
udevadm trigger
modprobe uinput || true

# 2. Add user to groups
echo "[INFO] Adding user $REAL_USER to input and uinput groups..."
usermod -aG input,uinput "$REAL_USER"

# 3. Download & Install Kanata binary
KANATA_VERSION="v1.12.0"
KANATA_URL="https://github.com/jtroo/kanata/releases/download/${KANATA_VERSION}/linux-binaries-x64.zip"
KANATA_BIN_PATH="/usr/local/bin/kanata"

if [ -x "$KANATA_BIN_PATH" ] && "$KANATA_BIN_PATH" --version 2>/dev/null | grep -q "${KANATA_VERSION#v}"; then
    echo "[INFO] Kanata ${KANATA_VERSION} is already installed at $KANATA_BIN_PATH, skipping download."
else
    echo "[INFO] Downloading Kanata ${KANATA_VERSION}..."
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf '$TEMP_DIR'" EXIT

    curl -fSL -o "$TEMP_DIR/kanata.zip" "$KANATA_URL" || {
        echo "[ERROR] Failed to download Kanata from $KANATA_URL" >&2
        exit 1
    }

    unzip -q -o "$TEMP_DIR/kanata.zip" -d "$TEMP_DIR" || {
        echo "[ERROR] Failed to unzip Kanata." >&2
        exit 1
    }

    # Find the kanata binary — name may vary between releases
    KANATA_EXTRACTED=""
    for candidate in "$TEMP_DIR/kanata_linux_x64" "$TEMP_DIR/kanata"; do
        if [ -f "$candidate" ]; then
            KANATA_EXTRACTED="$candidate"
            break
        fi
    done

    if [ -z "$KANATA_EXTRACTED" ]; then
        echo "[ERROR] Could not find kanata binary in the downloaded zip. Contents:" >&2
        ls -la "$TEMP_DIR" >&2
        exit 1
    fi

    cp "$KANATA_EXTRACTED" "$KANATA_BIN_PATH"
    chmod 755 "$KANATA_BIN_PATH"
    rm -rf "$TEMP_DIR"
    trap - EXIT

    echo "[INFO] Kanata installed at $KANATA_BIN_PATH"
    "$KANATA_BIN_PATH" --version
fi

# 4. Stop and disable any system-wide kanata service, and remove the unit file
echo "[INFO] Checking for conflicting system-wide kanata service..."
if systemctl list-unit-files kanata.service >/dev/null 2>&1; then
    systemctl stop kanata.service 2>/dev/null || true
    systemctl disable kanata.service 2>/dev/null || true
fi
# Remove leftover system-wide unit files that could shadow or conflict
for svc_file in /etc/systemd/system/kanata.service /usr/lib/systemd/system/kanata.service; do
    if [ -f "$svc_file" ]; then
        echo "[INFO] Removing conflicting system-wide unit: $svc_file"
        rm -f "$svc_file"
    fi
done
systemctl daemon-reload 2>/dev/null || true

# 5. Create user systemd unit
echo "[INFO] Creating user systemd service for $REAL_USER..."
SYSTEMD_USER_DIR="$REAL_HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"
chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config" "$REAL_HOME/.config/systemd" "$REAL_HOME/.config/systemd/user" 2>/dev/null || true

cat << EOF > "$SYSTEMD_USER_DIR/kanata.service"
[Unit]
Description=Kanata keyboard remapper
Documentation=https://github.com/jtroo/kanata

[Service]
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Type=simple
ExecStart=$KANATA_BIN_PATH --cfg $USER_KANATA_CONFIG_SRC
Restart=on-failure
RestartSec=5
StartLimitBurst=3
StartLimitIntervalSec=30

[Install]
WantedBy=default.target
EOF

chown "$REAL_USER:$REAL_USER" "$SYSTEMD_USER_DIR/kanata.service"

# 6. Enable and start user service
echo "[INFO] Reloading user systemd and enabling service..."
export XDG_RUNTIME_DIR=/run/user/$(id -u "$REAL_USER")
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user daemon-reload
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user enable kanata.service

# Check if user actually has the required groups in their current session
# before attempting to start the service
NEEDS_RELOGIN=false
CURRENT_GROUPS=$(sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" id -Gn 2>/dev/null || id -Gn "$REAL_USER")
if ! echo "$CURRENT_GROUPS" | grep -qw "input" || ! echo "$CURRENT_GROUPS" | grep -qw "uinput"; then
    NEEDS_RELOGIN=true
fi

if [ "$NEEDS_RELOGIN" = true ]; then
    echo ""
    echo "================================================================"
    echo "[IMPORTANT] Group changes have been applied but require a"
    echo "            logout and login to take effect."
    echo ""
    echo "  Please log out, log back in, and then run:"
    echo "    systemctl --user restart kanata.service"
    echo ""
    echo "  Or reboot and the service will start automatically."
    echo "================================================================"
else
    echo "[INFO] Starting kanata service..."
    # Reset any previous failure state so systemd doesn't refuse to restart
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user reset-failed kanata.service 2>/dev/null || true
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user restart kanata.service

    # 7. Verify the service is up and running
    # We need to confirm it stays active, not just briefly starts before crashing.
    # Strategy: poll for up to 8s. Require "active" on 2 consecutive checks (1s apart)
    # to rule out crash-restart loops where the process briefly appears active.
    echo "[INFO] Verifying kanata service (waiting up to 8s)..."
    MAX_WAIT=8
    WAITED=0
    CONSECUTIVE_ACTIVE=0
    REQUIRED_ACTIVE=2
    SERVICE_OK=false
    STATE=""
    while [ "$WAITED" -lt "$MAX_WAIT" ]; do
        sleep 1
        WAITED=$((WAITED + 1))
        STATE=$(sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user is-active kanata.service 2>/dev/null || true)
        if [ "$STATE" = "active" ]; then
            CONSECUTIVE_ACTIVE=$((CONSECUTIVE_ACTIVE + 1))
            if [ "$CONSECUTIVE_ACTIVE" -ge "$REQUIRED_ACTIVE" ]; then
                SERVICE_OK=true
                break
            fi
        elif [ "$STATE" = "failed" ] || [ "$STATE" = "inactive" ]; then
            # No point waiting further if it already failed
            break
        else
            # "activating" (auto-restart) — reset consecutive counter
            CONSECUTIVE_ACTIVE=0
        fi
    done

    echo ""
    echo "================================================================"
    if [ "$SERVICE_OK" = true ]; then
        echo "[OK] Kanata service is running! (stable for ${REQUIRED_ACTIVE}s, verified after ${WAITED}s)"
        echo "================================================================"
        echo ""
        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user status kanata.service --no-pager 2>&1 || true
    else
        echo "[FAIL] Kanata service is NOT running (state: $STATE)"
        echo "================================================================"
        echo ""
        echo "--- Service status ---"
        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" systemctl --user status kanata.service --no-pager 2>&1 || true
        echo ""
        echo "--- Recent logs ---"
        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" journalctl --user -u kanata.service --no-pager -n 15 2>&1 || true
        echo ""
        echo "If you see 'Permission denied', log out, log back in, and run:"
        echo "  systemctl --user restart kanata.service"
        exit 1
    fi
fi

echo ""
echo "[INFO] Kanata setup complete!"
exit 0
