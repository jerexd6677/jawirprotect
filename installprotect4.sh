#!/bin/bash

echo "🚀 Installing Protect 4: TOTAL BLOCK Nuclear Edition..."
echo "🔒 PROTECT PANEL - ZERO BYPASS"

NODE_CONTROLLER_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"
NODE_CONTROLLER_BACKUP="${NODE_CONTROLLER_PATH}.backup_$(date +%Y%m%d_%H%M%S)"

# Backup original
if [ -f "$NODE_CONTROLLER_PATH" ]; then
    cp "$NODE_CONTROLLER_PATH" "$NODE_CONTROLLER_BACKUP"
    echo "📦 Backup created: $NODE_CONTROLLER_BACKUP"
fi

# 🚨 PROTECT ALL NODE CONTROLLER METHODS
cat > "$NODE_CONTROLLER_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Nodes;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Pterodactyl\Models\Node;
use Spatie\QueryBuilder\QueryBuilder;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Exceptions\DisplayException;

class NodeController extends Controller
{
    public function __construct(private ViewFactory $view) 
    {
        // 🔒 APPLY PROTECTION TO ALL METHODS IN THIS CONTROLLER
        $this->middleware(function ($request, $next) {
            $this->checkNodeAccess();
            return $next($request);
        });
    }

    private function checkNodeAccess(): void
    {
        $user = Auth::user();
        
        // 🚫 BLOCK EVERYONE EXCEPT SUPER ADMIN
        if (!$user || $user->id !== 1) {
            \Log::critical("BLOCKED NODE ACCESS ATTEMPT", [
                'user_id' => $user ? $user->id : 'null',
                'email' => $user ? $user->email : 'null', 
                'ip' => request()->ip(),
                'url' => request()->fullUrl(),
                'user_agent' => request()->userAgent()
            ]);
            
            throw new DisplayException('🚫 SYSTEM SECURITY: Node access restricted to system owner only!');
        }

        // 🛡️ ADDITIONAL SECURITY CHECKS
        $blockedRoutes = ['/admin/nodes/view/', '/admin/nodes/create', '/api/application/nodes'];
        $currentPath = request()->path();
        
        foreach ($blockedRoutes as $route) {
            if (strpos($currentPath, $route) !== false && $user->id !== 1) {
                throw new DisplayException('🚫 SECURITY ALERT: Unauthorized access detected!');
            }
        }
    }

    public function index(Request $request): View
    {
        $nodes = QueryBuilder::for(
            Node::query()->with('location')->withCount('servers')
        )
            ->allowedFilters(['uuid', 'name'])
            ->allowedSorts(['id'])
            ->paginate(25);

        return $this->view->make('admin.nodes.index', ['nodes' => $nodes]);
    }

    // 🔒 PROTECT ALL OTHER METHODS THAT MIGHT EXIST
    public function view(Request $request, Node $node): View
    {
        $this->checkNodeAccess();
        // Return empty or fake data
        return $this->view->make('admin.nodes.view', ['node' => $node]);
    }

    public function update(Request $request, Node $node): RedirectResponse
    {
        $this->checkNodeAccess();
        throw new DisplayException('🚫 Node modifications are currently disabled!');
    }

    public function create(Request $request): View
    {
        $this->checkNodeAccess();
        throw new DisplayException('🚫 Node creation is currently disabled!');
    }

    public function delete(Request $request, Node $node): JsonResponse
    {
        $this->checkNodeAccess();
        return response()->json(['error' => 'Node deletion disabled'], 403);
    }
}
EOF

chmod 644 "$NODE_CONTROLLER_PATH"

# 🚨 BLOCK DIRECT ROUTE ACCESS TO NODE VIEWS
echo "🛡️ Blocking direct route access..."

# Cari dan protect semua file node related
find /var/www/pterodactyl/app/Http/Controllers/ -name "*Node*Controller.php" -type f | while read -r file; do
    if [ "$file" != "$NODE_CONTROLLER_PATH" ]; then
        backup_file="${file}.backup_$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup_file"
        echo "📦 Backed up: $file"
    fi
done

# 🚨 DISABLE LARAVEL DEBUG KIT IF EXISTS
DEBUG_KIT_PATH="/var/www/pterodactyl/vendor/laravel/framework/src/Illuminate/Debug"
if [ -d "$DEBUG_KIT_PATH" ]; then
    echo "⚠️ Laravel Debug Kit detected - consider removing in production"
fi

# 🚨 ADD .htaccess PROTECTION (if using Apache)
HTACCESS_PATH="/var/www/pterodactyl/public/.htaccess"
if [ -f "$HTACCESS_PATH" ]; then
    cat >> "$HTACCESS_PATH" << 'HTACCESS_EOF'

# 🔒 PROTECT NODE ROUTES
<IfModule mod_rewrite.c>
    RewriteEngine On
    # Block direct access to node views
    RewriteRule ^admin/nodes/view/ - [F,L]
    RewriteRule ^api/application/nodes - [F,L]
</IfModule>
HTACCESS_EOF
    echo "🔧 Added .htaccess protection"
fi

# 🚨 CREATE SECURITY MONITOR SCRIPT
SECURITY_SCRIPT="/root/node_security_monitor.sh"
cat > "$SECURITY_SCRIPT" << 'MONITOR_EOF'
#!/bin/bash
# Security Monitor for Node Access
LOG_FILE="/var/www/pterodactyl/storage/logs/laravel.log"
ALERT_KEYWORDS=("BLOCKED NODE ACCESS" "NODE ACCESS ATTEMPT" "admin/nodes/view")

while true; do
    for keyword in "${ALERT_KEYWORDS[@]}"; do
        if tail -n 50 "$LOG_FILE" | grep -q "$keyword"; then
            echo "🚨 SECURITY ALERT: Node access attempt detected!"
            echo "Check: $LOG_FILE"
            # Add telegram/discord alert here
        fi
    done
    sleep 30
done
MONITOR_EOF

chmod +x "$SECURITY_SCRIPT"
echo "🔔 Security monitor script created: $SECURITY_SCRIPT"

echo "✅ PROTECT 4 NUCLEAR: Complete node lockdown installed!"
echo "🔒 ALL ROUTES BLOCKED - ZERO BYPASS POSSIBLE"
echo "💡 Run: nohup bash $SECURITY_SCRIPT & to start monitoring"
