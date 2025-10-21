#!/bin/bash

echo "🚀 Installing Protect 1: Anti Delete Server..."
echo "🔒 PROTECT BY JEREXD"

REMOTE_PATH="/var/www/pterodactyl/app/Services/Servers/ServerDeletionService.php"
BACKUP_PATH="${REMOTE_PATH}.backup_$(date +%Y%m%d_%H%M%S)"

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
    cp "$REMOTE_PATH" "$BACKUP_PATH"
    echo "📦 Backup created: $BACKUP_PATH"
fi

# Create directory jika tidak ada
mkdir -p "$(dirname "$REMOTE_PATH")"

# Install Protect 1
cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Services\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Exceptions\DisplayException;
use Illuminate\Http\Response;
use Pterodactyl\Models\Server;
use Illuminate\Support\Facades\Log;
use Illuminate\Database\ConnectionInterface;
use Pterodactyl\Repositories\Wings\DaemonServerRepository;
use Pterodactyl\Services\Databases\DatabaseManagementService;
use Pterodactyl\Exceptions\Http\Connection\DaemonConnectionException;

class ServerDeletionService
{
    protected bool $force = false;

    public function __construct(
        private ConnectionInterface $connection,
        private DaemonServerRepository $daemonServerRepository,
        private DatabaseManagementService $databaseManagementService
    ) {}

    public function withForce(bool $bool = true): self
    {
        $this->force = $bool;
        return $this;
    }

    public function handle(Server $server): void
    {
        $user = Auth::user();

        if ($user) {
            if ($user->id !== 1) {
                $ownerId = $server->owner_id
                    ?? $server->user_id
                    ?? ($server->owner?->id ?? null)
                    ?? ($server->user?->id ?? null);

                if ($ownerId === null) {
                    throw new DisplayException('Akses ditolak: informasi pemilik server tidak tersedia. PROTECT BY JEREXD');
                }

                if ($ownerId !== $user->id) {
                    throw new DisplayException('Akses ditolak: Anda hanya dapat menghapus server milik Anda sendiri. PROTECT BY JEREXD');
                }
            }
        }

        try {
            $this->daemonServerRepository->setServer($server)->delete();
        } catch (DaemonConnectionException $exception) {
            if (!$this->force && $exception->getStatusCode() !== Response::HTTP_NOT_FOUND) {
                throw $exception;
            }
            Log::warning($exception);
        }

        $this->connection->transaction(function () use ($server) {
            foreach ($server->databases as $database) {
                try {
                    $this->databaseManagementService->delete($database);
                } catch (\Exception $exception) {
                    if (!$this->force) {
                        throw $exception;
                    }
                    $database->delete();
                    Log::warning($exception);
                }
            }
            $server->delete();
        });
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ PROTECT 1: Anti Delete Server installed!"
echo "🔒 PROTECT BY JEREXD"
