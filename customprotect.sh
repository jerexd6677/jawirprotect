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

# 🎨 FIX: Replace SEMUA watermark dengan custom
echo "🔧 Applying custom watermark: $CUSTOM_WATERMARK"

# 1. Replace DEFAULT watermark variable di awal script
sed -i "s|CUSTOM_WATERMARK:-\".*\"|CUSTOM_WATERMARK:-\"$CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh
sed -i "s|CUSTOM_WATERMARK:-\".*\"|CUSTOM_WATERMARK:-\"$CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# 2. Replace watermark di header output
sed -i "s|💫 Watermark:.*|💫 Watermark: $CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# 3. Replace watermark di main function output
sed -i "s|log \"💫 Watermark:.*|log \"💫 Watermark: $CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh
sed -i "s|echo \"💫 Custom Watermark:.*|echo \"💫 Custom Watermark: $CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# 4. Replace watermark di semua echo output
sed -i "s|echo \"🔒 .*\"|echo \"🔒 $CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh
sed -i "s|echo \"💫 .*\"|echo \"💫 $CUSTOM_WATERMARK\"|g" /tmp/protect_custom.sh

# 5. Replace hardcoded watermark di semua protection
sed -i "s|PROTECTED BY JEREXD BOT|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh
sed -i "s|𝗣𝗥𝗢𝗧𝗘𝗖𝗧𝗘𝗗 𝗕𝗬 𝗝𝗘𝗥𝗘𝗫𝗗 𝗕𝗢𝗧|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# 6. Replace watermark variable di PHP files
sed -i "s|\\$CUSTOM_WATERMARK|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# 7. Replace watermark sebelumnya yang mungkin stuck
sed -i "s|LINNSIGMA|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# Debug: Tampilkan perubahan
echo "🔍 Debug - Watermark replacements applied"
grep -n "Watermark:" /tmp/protect_custom.sh | head -5

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
