#!/bin/bash

# Terima custom watermark dari parameter atau environment variable
CUSTOM_WATERMARK="${1:-${CUSTOM_WATERMARK:-𝗣𝗥𝗢𝗧𝗘𝗖𝗧𝗘𝗗 𝗕𝗬 𝗝𝗘𝗥𝗘𝗫𝗗 𝗕𝗢𝗧}}"

echo "=================================================="
echo "🛡️  JEREPROTECTBOT - INSTALL ALL PROTECTION"
echo "🔒 Version: 2.0 Premium"
echo "💫 Watermark: $CUSTOM_WATERMARK"
echo "⏰ Started: $(date)"
echo "=================================================="

# Fungsi untuk log
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Fungsi backup file
backup_file() {
    local file_path=$1
    if [ -f "$file_path" ]; then
        local timestamp=$(date -u +"%Y%m%d_%H%M%S")
        local backup_path="${file_path}.backup_${timestamp}"
        cp "$file_path" "$backup_path"
        log "📦 Backup created: $backup_path"
        return 0
    else
        log "⚠️  File tidak ditemukan: $file_path"
        return 1
    fi
}

# Fungsi create directory jika tidak ada
ensure_directory() {
    local dir_path=$(dirname "$1")
    if [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
        chmod 755 "$dir_path"
        log "📁 Directory created: $dir_path"
    fi
}

# ==================== PROTECT 1: ANTI DELETE SERVER ====================
install_protect1() {
    log "🚀 Installing PROTECT 1: Anti Delete Server..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Services/Servers/ServerDeletionService.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
    cat > "$REMOTE_PATH" << EOF
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
    protected bool \$force = false;

    public function __construct(
        private ConnectionInterface \$connection,
        private DaemonServerRepository \$daemonServerRepository,
        private DatabaseManagementService \$databaseManagementService
    ) {}

    public function withForce(bool \$bool = true): self
    {
        \$this->force = \$bool;
        return \$this;
    }

    public function handle(Server \$server): void
    {
        \$user = Auth::user();

        if (\$user) {
            if (\$user->id !== 1) {
                \$ownerId = \$server->owner_id
                    ?? \$server->user_id
                    ?? (\$server->owner?->id ?? null)
                    ?? (\$server->user?->id ?? null);

                if (\$ownerId === null) {
                    throw new DisplayException('Akses ditolak: informasi pemilik server tidak tersedia. $CUSTOM_WATERMARK');
                }

                if (\$ownerId !== \$user->id) {
                    throw new DisplayException('Akses ditolak: Anda hanya dapat menghapus server milik Anda sendiri. $CUSTOM_WATERMARK');
                }
            }
        }

        try {
            \$this->daemonServerRepository->setServer(\$server)->delete();
        } catch (DaemonConnectionException \$exception) {
            if (!\$this->force && \$exception->getStatusCode() !== Response::HTTP_NOT_FOUND) {
                throw \$exception;
            }
            Log::warning(\$exception);
        }

        \$this->connection->transaction(function () use (\$server) {
            foreach (\$server->databases as \$database) {
                try {
                    \$this->databaseManagementService->delete(\$database);
                } catch (\\Exception \$exception) {
                    if (!\$this->force) {
                        throw \$exception;
                    }
                    \$database->delete();
                    Log::warning(\$exception);
                }
            }
            \$server->delete();
        });
    }
}
EOF

    chmod 644 "$REMOTE_PATH"
    log "✅ PROTECT 1: Anti Delete Server installed!"
}

# ==================== PROTECT 2: ANTI USER MODIFICATION ====================
install_protect2() {
    log "🚀 Installing PROTECT 2: Anti User Modification..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/UserController.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
    # 🎯 FIX: Gunakan template yang LENGKAP dan sudah include protection
    cat > "$REMOTE_PATH" << EOF
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Pterodactyl\Models\Model;
use Illuminate\Support\Collection;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Spatie\QueryBuilder\QueryBuilder;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\Translation\Translator;
use Pterodactyl\Services\Users\UserUpdateService;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Users\UserCreationService;
use Pterodactyl\Services\Users\UserDeletionService;
use Pterodactyl\Http\Requests\Admin\UserFormRequest;
use Pterodactyl\Http\Requests\Admin\NewUserFormRequest;
use Pterodactyl\Contracts\Repository\UserRepositoryInterface;

class UserController extends Controller
{
    use AvailableLanguages;

    /**
     * UserController constructor.
     */
    public function __construct(
        protected AlertsMessageBag \$alert,
        protected UserCreationService \$creationService,
        protected UserDeletionService \$deletionService,
        protected Translator \$translator,
        protected UserUpdateService \$updateService,
        protected UserRepositoryInterface \$repository,
        protected ViewFactory \$view
    ) {}

    /**
     * Display user index page.
     */
    public function index(Request \$request): View
    {
        \$users = QueryBuilder::for(
            User::query()->select('users.*')
                ->selectRaw('COUNT(DISTINCT(subusers.id)) as subuser_of_count')
                ->selectRaw('COUNT(DISTINCT(servers.id)) as servers_count')
                ->leftJoin('subusers', 'subusers.user_id', '=', 'users.id')
                ->leftJoin('servers', 'servers.owner_id', '=', 'users.id')
                ->groupBy('users.id')
        )
            ->allowedFilters(['username', 'email', 'uuid'])
            ->allowedSorts(['id', 'uuid'])
            ->paginate(50);

        return \$this->view->make('admin.users.index', ['users' => \$users]);
    }

    /**
     * Display new user page.
     */
    public function create(): View
    {
        return \$this->view->make('admin.users.new', [
            'languages' => \$this->getAvailableLanguages(true),
        ]);
    }

    /**
     * Display user view page.
     */
    public function view(User \$user): View
    {
        return \$this->view->make('admin.users.view', [
            'user' => \$user,
            'languages' => \$this->getAvailableLanguages(true),
        ]);
    }

    /**
     * Delete a user from the system.
     */
    public function delete(Request \$request, User \$user): RedirectResponse
    {
        // === PROTECTION: Hanya admin ID 1 yang bisa hapus user lain ===
        if (\$request->user()->id !== 1) {
            throw new DisplayException("❌ Hanya admin ID 1 yang dapat menghapus user lain! $CUSTOM_WATERMARK");
        }

        if (\$request->user()->id === \$user->id) {
            throw new DisplayException(\$this->translator->get('admin/user.exceptions.user_has_servers'));
        }

        \$this->deletionService->handle(\$user);

        return redirect()->route('admin.users');
    }

    /**
     * Create a user.
     */
    public function store(NewUserFormRequest \$request): RedirectResponse
    {
        \$user = \$this->creationService->handle(\$request->normalize());
        \$this->alert->success(\$this->translator->get('admin/user.notices.account_created'))->flash();

        return redirect()->route('admin.users.view', \$user->id);
    }

    /**
     * Update a user on the system.
     */
    public function update(UserFormRequest \$request, User \$user): RedirectResponse
    {
        // === PROTECTION: Hanya admin ID 1 yang bisa ubah data penting ===
        \$restrictedFields = ['email', 'username', 'first_name', 'last_name', 'password'];

        foreach (\$restrictedFields as \$field) {
            if (\$request->filled(\$field) && \$request->user()->id !== 1) {
                throw new DisplayException("⚠️ Data sensitif hanya bisa diubah oleh admin ID 1. $CUSTOM_WATERMARK");
            }
        }

        // === PROTECTION: Cegah turunkan level admin ===
        if (\$user->root_admin && \$request->user()->id !== 1) {
            throw new DisplayException("🚫 Tidak dapat menurunkan hak admin pengguna ini. $CUSTOM_WATERMARK");
        }

        \$this->updateService
            ->setUserLevel(User::USER_LEVEL_ADMIN)
            ->handle(\$user, \$request->normalize());

        \$this->alert->success(\$this->translator->get('admin/user.notices.account_updated'))->flash();

        return redirect()->route('admin.users.view', \$user->id);
    }

    /**
     * Get a JSON response of users on the system.
     */
    public function json(Request \$request): Model|Collection
    {
        \$users = QueryBuilder::for(User::query())->allowedFilters(['email'])->paginate(25);

        // Handle single user requests.
        if (\$request->query('user_id')) {
            \$user = User::query()->findOrFail(\$request->input('user_id'));
            \$user->md5 = md5(strtolower(\$user->email));

            return \$user;
        }

        return \$users->map(function (\$item) {
            \$item->md5 = md5(strtolower(\$item->email));

            return \$item;
        });
    }
}
EOF

    chmod 644 "$REMOTE_PATH"
    log "✅ PROTECT 2: Anti User Modification installed!"
}

        

# ==================== PROTECT 3: ANTI LOCATION ACCESS ====================
install_protect3() {
    log "🚀 Installing PROTECT 3: Anti Location Access..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/LocationController.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
    cat > "$REMOTE_PATH" << EOF
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
        protected AlertsMessageBag \$alert,
        protected LocationCreationService \$creationService,
        protected LocationDeletionService \$deletionService,
        protected LocationRepositoryInterface \$repository,
        protected LocationUpdateService \$updateService,
        protected ViewFactory \$view
    ) {}

    public function index(): View
    {
        \$user = Auth::user();
        if (!\$user || \$user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengakses locations. $CUSTOM_WATERMARK');
        }

        return \$this->view->make('admin.locations.index', [
            'locations' => \$this->repository->getAllWithDetails(),
        ]);
    }

    public function view(int \$id): View
    {
        \$user = Auth::user();
        if (!\$user || \$user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa melihat detail location. $CUSTOM_WATERMARK');
        }

        return \$this->view->make('admin.locations.view', [
            'location' => \$this->repository->getWithNodes(\$id),
        ]);
    }

    public function create(LocationFormRequest \$request): RedirectResponse
    {
        \$user = Auth::user();
        if (!\$user || \$user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa membuat location. $CUSTOM_WATERMARK');
        }

        \$location = \$this->creationService->handle(\$request->normalize());
        \$this->alert->success('Location berhasil dibuat!')->flash();
        return redirect()->route('admin.locations.view', \$location->id);
    }

    public function update(LocationFormRequest \$request, Location \$location): RedirectResponse
    {
        \$user = Auth::user();
        if (!\$user || \$user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengupdate location. $CUSTOM_WATERMARK');
        }

        if (\$request->input('action') === 'delete') {
            return \$this->delete(\$location);
        }

        \$this->updateService->handle(\$location->id, \$request->normalize());
        \$this->alert->success('Location berhasil diupdate!')->flash();
        return redirect()->route('admin.locations.view', \$location->id);
    }

    public function delete(Location \$location): RedirectResponse
    {
        \$user = Auth::user();
        if (!\$user || \$user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa menghapus location. $CUSTOM_WATERMARK');
        }

        \$this->deletionService->handle(\$location->id);
        \$this->alert->success('Location berhasil dihapus!')->flash();
        return redirect()->route('admin.locations');
    }
}
EOF

    chmod 644 "$REMOTE_PATH"
    log "✅ PROTECT 3: Anti Location Access installed!"
}

# ==================== PROTECT 4: ANTI NODE ACCESS ====================
install_protect4() {
    log "🚀 Installing PROTECT 4: Anti Node Access..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
    cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Nodes;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\Node;
use Spatie\QueryBuilder\QueryBuilder;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Exceptions\DisplayException;

class NodeController extends Controller
{
    public function __construct(private ViewFactory $view) {}

    public function index(Request $request): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang dapat membuka menu Nodes. PROTECTED BY JEREXD BOT');
        }

        $nodes = QueryBuilder::for(
            Node::query()->with('location')->withCount('servers')
        )
            ->allowedFilters(['uuid', 'name'])
            ->allowedSorts(['id'])
            ->paginate(25);

        return $this->view->make('admin.nodes.index', ['nodes' => $nodes]);
    }
}
EOF

    chmod 644 "$REMOTE_PATH"
    log "✅ PROTECT 4: Anti Node Access installed!"
}

# ==================== PROTECT 5: ANTI NEST ACCESS ====================
install_protect5() {
    log "🚀 Installing PROTECT 5: Anti Nest Access..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/NestController.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
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
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa membuka menu Nests. PROTECTED BY JEREXD BOT');
        }

        return $this->view->make('admin.nests.index', [
            'nests' => $this->repository->getWithCounts(),
        ]);
    }

    public function view(int $nest): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa melihat detail nest. PROTECTED BY JEREXD BOT');
        }

        return $this->view->make('admin.nests.view', [
            'nest' => $this->repository->getWithEggServers($nest),
        ]);
    }

    public function create(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa membuat nest. PROTECTED BY JEREXD BOT');
        }

        return $this->view->make('admin.nests.new');
    }

    public function store(StoreNestFormRequest $request): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa membuat nest. PROTECTED BY JEREXD BOT');
        }

        $nest = $this->nestCreationService->handle($request->normalize());
        $this->alert->success('Nest berhasil dibuat!')->flash();
        return redirect()->route('admin.nests.view', $nest->id);
    }

    public function update(StoreNestFormRequest $request, int $nest): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa mengupdate nest. PROTECTED BY JEREXD BOT');
        }

        $this->nestUpdateService->handle($nest, $request->normalize());
        $this->alert->success('Nest berhasil diupdate!')->flash();
        return redirect()->route('admin.nests.view', $nest);
    }

    public function destroy(int $nest): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin utama (ID 1) yang bisa menghapus nest. PROTECTED BY JEREXD BOT');
        }

        $this->nestDeletionService->handle($nest);
        $this->alert->success('Nest berhasil dihapus!')->flash();
        return redirect()->route('admin.nests');
    }
}
EOF

    chmod 644 "$REMOTE_PATH"
    log "✅ PROTECT 5: Anti Nest Access installed!"
}

# ==================== PROTECT 6: ANTI SETTINGS ACCESS ====================
install_protect6() {
    log "🚀 Installing PROTECT 6: Anti Settings Access..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Settings/IndexController.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
    cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Settings;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\Contracts\Console\Kernel;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Helpers\SoftwareVersionService;
use Pterodactyl\Contracts\Repository\SettingsRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Settings\BaseSettingsFormRequest;
use Pterodactyl\Exceptions\DisplayException;

class IndexController extends Controller
{
    use AvailableLanguages;

    public function __construct(
        private AlertsMessageBag $alert,
        private Kernel $kernel,
        private SettingsRepositoryInterface $settings,
        private SoftwareVersionService $versionService,
        private ViewFactory $view
    ) {}

    public function index(): View
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengakses settings. PROTECTED BY JEREXD BOT');
        }

        return $this->view->make('admin.settings.index', [
            'version' => $this->versionService,
            'languages' => $this->getAvailableLanguages(true),
        ]);
    }

    public function update(BaseSettingsFormRequest $request): RedirectResponse
    {
        $user = Auth::user();
        if (!$user || $user->id !== 1) {
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengupdate settings. PROTECTED BY JEREXD BOT');
        }

        foreach ($request->normalize() as $key => $value) {
            $this->settings->set('settings::' . $key, $value);
        }

        $this->kernel->call('queue:restart');
        $this->alert->success('Panel settings berhasil diupdate!')->flash();
        return redirect()->route('admin.settings');
    }
}
EOF

    chmod 644 "$REMOTE_PATH"
    log "✅ PROTECT 6: Anti Settings Access installed!"
}

# ==================== PROTECT 7: ANTI FILE ACCESS ====================
install_protect7() {
    log "🚀 Installing PROTECT 7: Anti File Access..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/FileController.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
    cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Carbon\CarbonImmutable;
use Illuminate\Http\Response;
use Illuminate\Http\JsonResponse;
use Pterodactyl\Models\Server;
use Pterodactyl\Facades\Activity;
use Pterodactyl\Services\Nodes\NodeJWTService;
use Pterodactyl\Repositories\Wings\DaemonFileRepository;
use Pterodactyl\Transformers\Api\Client\FileObjectTransformer;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\CopyFileRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\PullFileRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\ListFilesRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\ChmodFilesRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\DeleteFileRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\RenameFileRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\CreateFolderRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\CompressFilesRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\DecompressFilesRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\GetFileContentsRequest;
use Pterodactyl\Http\Requests\Api\Client\Servers\Files\WriteFileContentRequest;
use Pterodactyl\Exceptions\DisplayException;

class FileController extends ClientApiController
{
    public function __construct(
        private NodeJWTService $jwtService,
        private DaemonFileRepository $fileRepository
    ) {
        parent::__construct();
    }

    private function checkServerAccess(Server $server)
    {
        $user = request()->user();

        if ($user->id === 1) {
            return;
        }

        if ($server->owner_id !== $user->id) {
            throw new DisplayException('🚫 Akses ditolak! Anda tidak memiliki akses ke server ini. PROTECTED BY JEREXD BOT');
        }
    }

    public function directory(ListFilesRequest $request, Server $server): array
    {
        $this->checkServerAccess($server);

        $contents = $this->fileRepository
            ->setServer($server)
            ->getDirectory($request->get('directory') ?? '/');

        return $this->fractal->collection($contents)
            ->transformWith($this->getTransformer(FileObjectTransformer::class))
            ->toArray();
    }

    public function contents(GetFileContentsRequest $request, Server $server): Response
    {
        $this->checkServerAccess($server);

        $response = $this->fileRepository->setServer($server)->getContent(
            $request->get('file'),
            config('pterodactyl.files.max_edit_size')
        );

        Activity::event('server:file.read')->property('file', $request->get('file'))->log();
        return new Response($response, Response::HTTP_OK, ['Content-Type' => 'text/plain']);
    }

    public function download(GetFileContentsRequest $request, Server $server): array
    {
        $this->checkServerAccess($server);

        $token = $this->jwtService
            ->setExpiresAt(CarbonImmutable::now()->addMinutes(15))
            ->setUser($request->user())
            ->setClaims([
                'file_path' => rawurldecode($request->get('file')),
                'server_uuid' => $server->uuid,
            ])
            ->handle($server->node, $request->user()->id . $server->uuid);

        Activity::event('server:file.download')->property('file', $request->get('file'))->log();

        return [
            'object' => 'signed_url',
            'attributes' => [
                'url' => sprintf(
                    '%s/download/file?token=%s',
                    $server->node->getConnectionAddress(),
                    $token->toString()
                ),
            ],
        ];
    }

    public function write(WriteFileContentRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->putContent($request->get('file'), $request->getContent());
        Activity::event('server:file.write')->property('file', $request->get('file'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function create(CreateFolderRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->createDirectory($request->input('name'), $request->input('root', '/'));
        Activity::event('server:file.create-directory')->property('name', $request->input('name'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function delete(DeleteFileRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->deleteFiles($request->input('root'), $request->input('files'));
        Activity::event('server:file.delete')->property('files', $request->input('files'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }
}
EOF

    chmod 644 "$REMOTE_PATH"
    log "✅ PROTECT 7: Anti File Access installed!"
}

# ==================== PROTECT 8: ANTI SERVER ACCESS ====================
install_protect8() {
    log "🚀 Installing PROTECT 8: Anti Server Access..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/ServerController.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
    cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Server;
use Pterodactyl\Transformers\Api\Client\ServerTransformer;
use Pterodactyl\Services\Servers\GetUserPermissionsService;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\GetServerRequest;
use Pterodactyl\Exceptions\DisplayException;

class ServerController extends ClientApiController
{
    public function __construct(private GetUserPermissionsService $permissionsService)
    {
        parent::__construct();
    }

    public function index(GetServerRequest $request, Server $server): array
    {
        $authUser = Auth::user();

        if ($authUser->id !== 1 && (int) $server->owner_id !== (int) $authUser->id) {
            throw new DisplayException('🚫 Akses ditolak! Hanya bisa melihat server milik sendiri. PROTECTED BY JEREXD BOT');
        }

        return $this->fractal->item($server)
            ->transformWith($this->getTransformer(ServerTransformer::class))
            ->addMeta([
                'is_server_owner' => $request->user()->id === $server->owner_id,
                'user_permissions' => $this->permissionsService->handle($server, $request->user()),
            ])
            ->toArray();
    }
}
EOF

    chmod 644 "$REMOTE_PATH"
    log "✅ PROTECT 8: Anti Server Access installed!"
}

# ==================== PROTECT 9: ANTI SERVER MODIFICATION ====================
install_protect9() {
    log "🚀 Installing PROTECT 9: Anti Server Modification..."
    
    REMOTE_PATH="/var/www/pterodactyl/app/Services/Servers/DetailsModificationService.php"
    ensure_directory "$REMOTE_PATH"
    backup_file "$REMOTE_PATH"
    
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
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengubah detail server. PROTECTED BY JEREXD BOT');
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
    log "✅ PROTECT 9: Anti Server Modification installed!"
}

# ==================== MAIN INSTALLATION ====================
main() {
    log "🎯 Starting installation of ALL 9 Protections..."
    
    # Install semua protect
    install_protect1
    install_protect2
    install_protect3
    install_protect4
    install_protect5
    install_protect6
    install_protect7
    install_protect8
    install_protect9
    
    log "=================================================="
    log "🎉 SEMUA 9 PROTECTION BERHASIL DIINSTALL!"
    log "🔒 Panel Pterodactyl Anda sekarang terlindungi"
    log "💫 Watermark: $CUSTOM_WATERMARK"
    log "⏰ Selesai: $(date)"
    log "=================================================="
    
    echo ""
    echo "✅ INSTALASI SELESAI!"
    echo "🛡️  Semua 9 layer protection telah aktif"
    echo "🔒 Panel Pterodactyl Anda sekarang aman"
    echo "💫 Custom Watermark: $CUSTOM_WATERMARK"
    echo "📝 Restart panel jika diperlukan: cd /var/www/pterodactyl && php artisan optimize:clear"
}

# Jalankan instalasi
main
