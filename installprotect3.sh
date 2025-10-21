#!/bin/bash

echo "🚀 Installing Protect 3: Anti Location Access..."
echo "🔒 PROTECT BY JEREXD"

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/LocationController.php"
BACKUP_PATH="${REMOTE_PATH}.backup_$(date +%Y%m%d_%H%M%S)"

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
    cp "$REMOTE_PATH" "$BACKUP_PATH"
    echo "📦 Backup created: $BACKUP_PATH"
fi

# Create directory jika tidak ada
mkdir -p "$(dirname "$REMOTE_PATH")"

# Install Protect 3
cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Location;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Http\Requests\Admin\LocationFormRequest;
use Pterodactyl\Services\Locations\LocationUpdateService;
use Pterodactyl\Services\Locations\LocationCreationService;
use Pterodactyl\Services\Locations\LocationDeletionService;
use Pterodactyl\Contracts\Repository\LocationRepositoryInterface;

class LocationController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected LocationCreationService $creationService,
        protected LocationDeletionService $deletionService,
        protected LocationRepositoryInterface $repository,
        protected LocationUpdateService $updateService,
        protected ViewFactory $view
    ) {}

    public function index(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengakses locations. PROTECT BY JEREXD');
        }

        return $this->view->make('admin.locations.index', [
            'locations' => $this->repository->getAllWithDetails(),
        ]);
    }

    public function view(int $id): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa melihat detail location. PROTECT BY JEREXD');
        }

        return $this->view->make('admin.locations.view', [
            'location' => $this->repository->getWithNodes($id),
        ]);
    }

    public function create(LocationFormRequest $request): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa membuat location. PROTECT BY JEREXD');
        }

        $location = $this->creationService->handle($request->normalize());
        $this->alert->success('Location berhasil dibuat!')->flash();
        return redirect()->route('admin.locations.view', $location->id);
    }

    public function update(LocationFormRequest $request, Location $location): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengupdate location. PROTECT BY JEREXD');
        }

        if ($request->input('action') === 'delete') {
            return $this->delete($location);
        }

        $this->updateService->handle($location->id, $request->normalize());
        $this->alert->success('Location berhasil diupdate!')->flash();
        return redirect()->route('admin.locations.view', $location->id);
    }

    public function delete(Location $location): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa menghapus location. PROTECT BY JEREXD');
        }

        $this->deletionService->handle($location->id);
        $this->alert->success('Location berhasil dihapus!')->flash();
        return redirect()->route('admin.locations');
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ PROTECT 3: Anti Location Access installed!"
echo "🔒 PROTECT BY JEREXD"
