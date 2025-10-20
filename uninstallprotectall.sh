#!/bin/bash

echo "🔄 Memulai uninstall SEMUA Protect 1-9"
echo "🔒 PROTECT BY LINNSIGMA"

# List semua file yang akan di-uninstall
FILES=(
    "/var/www/pterodactyl/app/Services/Servers/ServerDeletionService.php"
    "/var/www/pterodactyl/app/Http/Controllers/Admin/UserController.php"
    "/var/www/pterodactyl/app/Http/Controllers/Admin/LocationController.php"
    "/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"
    "/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/NestController.php"
    "/var/www/pterodactyl/app/Http/Controllers/Admin/Settings/IndexController.php"
    "/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/FileController.php"
    "/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/ServerController.php"
    "/var/www/pterodactyl/app/Services/Servers/DetailsModificationService.php"
)

for file in "${FILES[@]}"; do
    echo "=== Uninstalling: $(basename $file) ==="
    BACKUP_FILE=$(ls "${file}.bak_"* 2>/dev/null | sort -r | head -n1)
    
    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        echo "📦 Mengembalikan backup: $BACKUP_FILE"
        cp "$BACKUP_FILE" "$file"
        chmod 644 "$file"
        echo "✅ Uninstall berhasil!"
    else
        echo "⚠️ Tidak ada backup ditemukan"
    fi
    echo ""
done

echo "🗑️ SEMUA PROTECT 1-9 BERHASIL DIUNINSTALL!"
echo "🔒 PROTECT BY LINNSIGMA"
