#!/bin/bash

echo "🚀 Installing Protect 5: Anti Nest Access..."
echo "🔒 PROTECT BY JEREXD"

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/NestController.php"
BACKUP_PATH="${REMOTE_PATH}.backup_$(date +%Y%m%d_%H%M%S)"

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
    cp "$REMOTE_PATH" "$BACKUP_PATH"
    echo "📦 Backup created: $BACKUP_PATH"
fi

# Create directory jika tidak ada
mkdir -p "$(dirname "$REMOTE_PATH")"

# Install Protect 5
cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Nests;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Nests\NestUpdateService;
use Pterodactyl\Services\Nests\NestCreationService;
use Pterodactyl\Services\Nests\NestDeletionService;
use Pterodactyl\Contracts\Repository\NestRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Nest\StoreNestFormRequest;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Exceptions\DisplayException;

class NestController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected NestCreationService $nestCreationService,
        protected NestDeletionService $nestDeletionService,
        protected NestRepositoryInterface $repository,
        protected NestUpdateService $nestUpdateService,
        protected ViewFactory $view
    ) {}

    public function index(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa membuka menu Nests. PROTECT BY JEREXD');
        }

        return $this->view->make('admin.nests.index', [
            'nests' => $this->repository->getWithCounts(),
        ]);
    }

    public function view(int $nest): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa melihat detail nest. PROTECT BY JEREXD');
        }

        return $this->view->make('admin.nests.view', [
            'nest' => $this->repository->getWithEggServers($nest),
        ]);
    }

    public function create(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa membuat nest. PROTECT BY JEREXD');
        }

        return $this->view->make('admin.nests.new');
    }

    public function store(StoreNestFormRequest $request): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa membuat nest. PROTECT BY JEREXD');
        }

        $nest = $this->nestCreationService->handle($request->normalize());
        $this->alert->success('Nest berhasil dibuat!')->flash();
        return redirect()->route('admin.nests.view', $nest->id);
    }

    public function update(StoreNestFormRequest $request, int $nest): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa mengupdate nest. PROTECT BY JEREXD');
        }

        $this->nestUpdateService->handle($nest, $request->normalize());
        $this->alert->success('Nest berhasil diupdate!')->flash();
        return redirect()->route('admin.nests.view', $nest);
    }

    public function destroy(int $nest): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa menghapus nest. PROTECT BY JEREXD');
        }

        $this->nestDeletionService->handle($nest);
        $this->alert->success('Nest berhasil dihapus!')->flash();
        return redirect()->route('admin.nests');
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ PROTECT 5: Anti Nest Access installed!"
echo "🔒 PROTECT BY JEREXD"
