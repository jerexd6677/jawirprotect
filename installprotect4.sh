#!/bin/bash

echo "🚀 Installing Protect 4: Anti Node Access..."
echo "🔒 PROTECT BY LINNSIGMA"

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"
BACKUP_PATH="${REMOTE_PATH}.backup_$(date +%Y%m%d_%H%M%S)"

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
    cp "$REMOTE_PATH" "$BACKUP_PATH"
    echo "📦 Backup created: $BACKUP_PATH"
fi

# Create directory jika tidak ada
mkdir -p "$(dirname "$REMOTE_PATH")"

# Install Protect 4
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
            throw new DisplayException('🚫 Akses ditolak! Hanya admin ID 1 yang dapat membuka menu Nodes. PROTECT BY LINNSIGMA');
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
echo "✅ PROTECT 4: Anti Node Access installed!"
echo "🔒 PROTECT BY LINNSIGMA"
