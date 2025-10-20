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

# Download script protect.sh
echo "📥 Downloading protect.sh from GitHub..."
curl -s "https://raw.githubusercontent.com/jerexd6677/jawirprotect/refs/heads/main/protect.sh" -o /tmp/protect_custom.sh

if [ $? -ne 0 ]; then
    echo "❌ Gagal download protect.sh"
    exit 1
fi

# Cek apakah file berhasil didownload
if [ ! -f "/tmp/protect_custom.sh" ]; then
    echo "❌ File protect.sh tidak ditemukan setelah download"
    exit 1
fi

# Replace semua watermark dengan custom watermark
echo "🔧 Applying custom watermark: $CUSTOM_WATERMARK"
sed -i "s|PROTECTED BY JEREXD BOT|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh
sed -i "s|𝗣𝗥𝗢𝗧𝗘𝗖𝗧𝗘𝗗 𝗕𝗬 𝗝𝗘𝗥𝗘𝗫𝗗 𝗕𝗢𝗧|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh
sed -i "s|PROTECTED BY JEREXD BOT|$CUSTOM_WATERMARK|g" /tmp/protect_custom.sh

# Juga replace watermark di dalam fungsi-fungsi install
sed -i "s|throw new DisplayException('🚫 Akses ditolak.*PROTECTED BY JEREXD BOT');|throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa mengakses. $CUSTOM_WATERMARK');|g" /tmp/protect_custom.sh

# Export variable environment untuk memastikan
export CUSTOM_WATERMARK="$CUSTOM_WATERMARK"

# Make executable dan execute
chmod +x /tmp/protect_custom.sh
echo "🚀 Executing custom protect script..."
bash /tmp/protect_custom.sh "$CUSTOM_WATERMARK"

# Cek hasil execution
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
