<?php
/**
 * 雷达数据接口
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

$dataDir = __DIR__ . '/radar_data/';
if (!is_dir($dataDir)) mkdir($dataDir, 0755, true);

$action = $_GET['action'] ?? $_POST['action'] ?? '';
$roomId = strtoupper($_GET['room'] ?? $_POST['room'] ?? '');

switch ($action) {
    case 'create':
        $roomId = substr(str_shuffle('ABCDEFGHJKLMNPQRSTUVWXYZ23456789'), 0, 6);
        file_put_contents($dataDir . $roomId . '.json', json_encode([
            'map' => 'db',
            'bounds' => ['minX' => 0, 'minY' => 0, 'maxX' => 100000, 'maxY' => 100000],
            'players' => [],
            'time' => time()
        ]));
        echo json_encode(['ok' => true, 'room' => $roomId]);
        break;
    
    case 'update':
        if (!$roomId) { echo json_encode(['ok' => false]); break; }
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        file_put_contents($dataDir . $roomId . '.json', json_encode([
            'map' => $data['map'] ?? 'db',
            'bounds' => $data['bounds'] ?? ['minX' => 0, 'minY' => 0, 'maxX' => 100000, 'maxY' => 100000],
            'players' => $data['players'] ?? [],
            'items' => $data['items'] ?? [],
            'time' => time()
        ]));
        echo json_encode(['ok' => true]);
        break;
    
    case 'get':
        if (!$roomId) { echo json_encode(['ok' => false, 'msg' => '房间号错误']); break; }
        $file = $dataDir . $roomId . '.json';
        if (!file_exists($file)) { echo json_encode(['ok' => false, 'msg' => '房间不存在']); break; }
        $data = json_decode(file_get_contents($file), true);
        if (time() - ($data['time'] ?? 0) > 60) {
            echo json_encode(['ok' => false, 'msg' => '房间已离线']);
            break;
        }
        echo json_encode([
            'ok' => true, 
            'map' => $data['map'], 
            'bounds' => $data['bounds'] ?? ['minX' => 0, 'minY' => 0, 'maxX' => 100000, 'maxY' => 100000],
            'players' => $data['players'],
            'items' => $data['items'] ?? []
        ]);
        break;
    
    default:
        echo json_encode(['ok' => false, 'msg' => '未知操作']);
}

// 清理旧房间
foreach (glob($dataDir . '*.json') as $file) {
    if (time() - filemtime($file) > 600) unlink($file);
}
