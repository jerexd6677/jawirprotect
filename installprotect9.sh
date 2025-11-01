#!/bin/bash

echo "🚀 Installing Protect 9: Anti Server Modification..."
echo "🔒 PROTECT PANEL"

REMOTE_PATH="/var/www/pterodactyl/app/Services/Servers/DetailsModificationService.php"
BACKUP_PATH="${REMOTE_PATH}.backup_$(date +%Y%m%d_%H%M%S)"

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
    cp "$REMOTE_PATH" "$BACKUP_PATH"
    echo "📦 Backup created: $BACKUP_PATH"
fi

# Create directory jika tidak ada
mkdir -p "$(dirname "$REMOTE_PATH")"

# Install Protect 9
cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Services\Servers;

use Illuminate\Support\Arr;
use Pterodactyl\Models\Server;
use Illuminate\Support\Facades\Auth;
use Illuminate\Database\ConnectionInterface;
use Pterodactyl\Traits\Services\ReturnsUpdatedModels;
use Pterodactyl\Repositories\Wings\DaemonServerRepository;
use Pterodactyl\Exceptions\Http\Connection\DaemonConnectionException;
use Pterodactyl\Exceptions\DisplayException;

class DetailsModificationService
{
    use ReturnsUpdatedModels;

    public function __construct(
        private ConnectionInterface $connection,
        private DaemonServerRepository $serverRepository
    ) {}

    public function handle(Server $server, array $data): Server
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengubah detail server.');
        }

        return $this->connection->transaction(function () use ($data, $server) {
            $owner = $server->owner_id;

            $server->forceFill([
                'external_id' => Arr::get($data, 'external_id'),
                'owner_id' => Arr::get($data, 'owner_id'),
                'name' => Arr::get($data, 'name'),
                'description' => Arr::get($data, 'description') ?? '',
            ])->saveOrFail();

            if ($server->owner_id !== $owner) {
                try {
                    $this->serverRepository->setServer($server)->revokeUserJTI($owner);
                } catch (DaemonConnectionException $exception) {
                }
            }

            return $server;
        });
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ PROTECT 9: Anti Server Modification installed!"
echo "🔒 PROTECT PANEL"
