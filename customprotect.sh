#!/bin/bash

# ==================================================
# CUSTOM PROTECT ALL - WITH CUSTOM WATERMARK
# Author: JereProtectBot
# Version: 2.0 Premium
# ==================================================

# Cek parameter
if [ $# -eq 0 ]; then
    echo "❌ Usage: $0 \"CUSTOM_WATERMARK_TEXT\""
    echo "💫 Example: $0 \"PROTECT BY LINNSIGMA\""
    exit 1
fi

CUSTOM_WATERMARK="$1"

echo "=================================================="
echo "🎨 JEREPROTECTBOT - CUSTOM INSTALL ALL PROTECTION"
echo "🔒 Version: 2.0 Premium"
echo "💫 Custom Watermark: $CUSTOM_WATERMARK"
echo "⏰ Started: $(date)"
echo "=================================================="

# Download script protect.sh
echo "📥 Downloading protect.sh from GitHub..."
curl -s "https://raw.githubusercontent.com/jerexd6677/jawirprotect/main/protect.sh" -o /tmp/protect_custom.sh

if [ $? -ne 0 ] || [ ! -f "/tmp/protect_custom.sh" ]; then
    echo "❌ Gagal download protect.sh"
    exit 1
fi

# 🎨 FIX: Replace watermark di script
echo "🔧 Applying custom watermark: $CUSTOM_WATERMARK"

# Replace default watermark di variable
sed -i "s|CUSTOM_WATERMARK:-\".*\"|CUSTOM_WATERMARK:-\"$CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# Replace watermark di header output
sed -i "s|echo \"💫 Watermark:.*|echo \"💫 Watermark: $CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# Replace watermark di log output
sed -i "s|log \"💫 Watermark:.*|log \"💫 Watermark: $CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# Replace watermark di final output
sed -i "s|echo \"💫 Watermark:.*|echo \"💫 Watermark: $CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# Replace watermark di semua echo output
sed -i "s|echo \"🔒 .*\"|echo \"🔒 $CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# Replace hardcoded watermark di semua protection
sed -i "s|PROTECT BY LINNSIGMA|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# Execute script yang sudah dimodifikasi
chmod +x /tmp/protect_custom.sh
echo "🚀 Executing custom protect script..."
bash /tmp/protect_custom.sh "$CUSTOM_WATERMARK"

if [ $? -eq 0 ]; then
    echo "=================================================="
    echo "✅ CUSTOM PROTECT ALL BERHASIL DIINSTALL!"
    echo "💫 Watermark: $CUSTOM_WATERMARK"
    echo "🔒 Semua 9 protection aktif dengan custom text"
    echo "=================================================="
else
    echo "❌ Gagal execute custom protect script"
    exit 1
fi
