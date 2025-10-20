#!/bin/bash

# ==================================================
# CUSTOM PROTECT ALL - WITH CUSTOM WATERMARK
# Author: JereProtectBot
# Version: 2.0 Premium
# ==================================================

# Cek parameter
if [ $# -eq 0 ]; then
    echo "❌ Usage: $0 \"CUSTOM_WATERMARK_TEXT\""
    echo "💫 Example: $0 \"PROTECTED BY MY COMPANY\""
    exit 1
fi

CUSTOM_WATERMARK="$1"

echo "=================================================="
echo "🎨 JEREPROTECTBOT - CUSTOM INSTALL ALL PROTECTION"
echo "🔒 Version: 2.0 Premium"
echo "💫 Custom Watermark: $CUSTOM_WATERMARK"
echo "⏰ Started: $(date)"
echo "=================================================="

# Download dan execute installprotectall.sh dengan custom watermark
curl -s "https://raw.githubusercontent.com/yourusername/yourrepo/main/installprotectall.sh" -o /tmp/installprotectall_custom.sh

if [ $? -eq 0 ]; then
    # Replace default watermark dengan custom watermark
    sed -i "s/PROTECTED BY JEREXD BOT/$CUSTOM_WATERMARK/g" /tmp/installprotectall_custom.sh
    sed -i "s/𝗣𝗥𝗢𝗧𝗘𝗖𝗧𝗘𝗗 𝗕𝗬 𝗝𝗘𝗥𝗘𝗫𝗗 𝗕𝗢𝗧/$CUSTOM_WATERMARK/g" /tmp/installprotectall_custom.sh
    
    # Execute script
    bash /tmp/installprotectall_custom.sh "$CUSTOM_WATERMARK"
else
    echo "❌ Gagal download installprotectall.sh"
    exit 1
fi
