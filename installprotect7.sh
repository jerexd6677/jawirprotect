#!/bin/bash

echo "🚀 Installing Protect 7: Anti File Access..."
echo "🔒 PROTECT PANEL"

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/FileController.php"
BACKUP_PATH="${REMOTE_PATH}.backup_$(date +%Y%m%d_%H%M%S)"

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
    cp "$REMOTE_PATH" "$BACKUP_PATH"
    echo "📦 Backup created: $BACKUP_PATH"
fi

# Create directory jika tidak ada
mkdir -p "$(dirname "$REMOTE_PATH")"

# Install Protect 7 - VERSI DIPERBAIKI
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
            throw new DisplayException('🚫 Akses ditolak! Anda tidak memiliki akses ke server ini.');
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

    // 🔧 FUNGSI UNTUK UNARCHIVE/ARCHIVE FILE - TETAP ADA
    public function compress(CompressFilesRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->compressFiles(
            $request->input('root'),
            $request->input('files')
        );
        Activity::event('server:file.compress')->property('files', $request->input('files'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function decompress(DecompressFilesRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->decompressFile(
            $request->input('root'),
            $request->input('file')
        );
        Activity::event('server:file.decompress')->property('file', $request->input('file'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function rename(RenameFileRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->renameFile(
            $request->input('root'),
            $request->input('rename_from'),
            $request->input('rename_to')
        );
        Activity::event('server:file.rename')
            ->property('old', $request->input('rename_from'))
            ->property('new', $request->input('rename_to'))
            ->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function copy(CopyFileRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->copyFile(
            $request->input('location'),
            $request->input('file')
        );
        Activity::event('server:file.copy')->property('file', $request->input('file'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function pull(PullFileRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->pullFile(
            $request->input('url'),
            $request->input('directory', '/'),
            $request->input('filename'),
            $request->input('use_header', false),
            $request->input('foreground', false)
        );
        Activity::event('server:file.pull')->property('url', $request->input('url'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }

    public function chmod(ChmodFilesRequest $request, Server $server): JsonResponse
    {
        $this->checkServerAccess($server);
        $this->fileRepository->setServer($server)->chmodFiles(
            $request->input('root'),
            $request->input('files')
        );
        Activity::event('server:file.chmod')->property('files', $request->input('files'))->log();
        return new JsonResponse([], Response::HTTP_NO_CONTENT);
    }
}
EOF

chmod 644 "$REMOTE_PATH"
echo "✅ PROTECT 7: Anti File Access installed!"
echo "🔒 PROTECT PANEL"
