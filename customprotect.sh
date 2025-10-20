#!/bin/bash

# ==================================================
# CUSTOM PROTECT ALL - WITH CUSTOM WATERMARK
# Author: JereProtectBot
# Version: 2.0 Premium
# ==================================================

# Cek parameter
if [ $# -eq 0 ]; then
    echo "❌ Usage: $0 \"CUSTOM_WATERMARK_TEXT\""
    echo "💫 Example: $0 \"LINNSIGMA\""
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

# 🎨 FIX: Replace SEMUA watermark dengan custom
echo "🔧 Applying custom watermark: $CUSTOM_WATERMARK"

# Replace watermark di header
sed -i "s|💫 Watermark:.*|💫 Watermark: $CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# Replace watermark di variable default
sed -i "s|CUSTOM_WATERMARK:-\"𝗣𝗥𝗢𝗧𝗘𝗖𝗧𝗘𝗗 𝗕𝗬 𝗝𝗘𝗥𝗘𝗫𝗗 𝗕𝗢𝗧\"|CUSTOM_WATERMARK:-\"$CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh
sed -i "s|CUSTOM_WATERMARK:-𝗣𝗥𝗢𝗧𝗘𝗖𝗧𝗘𝗗 𝗕𝗬 𝗝𝗘𝗥𝗘𝗫𝗗 𝗕𝗢𝗧|CUSTOM_WATERMARK:-\"$CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# Replace watermark di dalam string PHP
sed -i "s|\\$CUSTOM_WATERMARK|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# Replace hardcoded watermark di semua protection
sed -i "s|PROTECTED BY JEREXD BOT|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh
sed -i "s|𝗣𝗥𝗢𝗧𝗘𝗖𝗧𝗘𝗗 𝗕𝗬 𝗝𝗘𝗥𝗘𝗫𝗗 𝗕𝗢𝗧|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# Replace di output messages
sed -i "s|🔒 𝗣𝗥𝗢𝗧𝗘𝗖𝗧𝗘𝗗 𝗕𝗬 𝗝𝗘𝗥𝗘𝗫𝗗 𝗕𝗢𝗧|🔒 $CUSTOM_WATERMARK|g" /tmp/protect_custom.sh
sed -i "s|💫 Custom Watermark:.*|💫 Custom Watermark: $CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# Export variable untuk memastikan
export CUSTOM_WATERMARK="$CUSTOM_WATERMARK"

# Execute script dengan parameter
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
