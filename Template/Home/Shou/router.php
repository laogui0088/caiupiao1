<?php
/**
 * PHP 内置服务器路由文件
 * 用于处理 Template/Home/Shou 目录的静态文件访问
 */

// 获取请求的 URI
$uri = urldecode(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// 如果是根目录，返回静态首页
if ($uri === '/' || $uri === '') {
    $file = __DIR__ . '/index_static.html';
    if (file_exists($file)) {
        header('Content-Type: text/html; charset=UTF-8');
        readfile($file);
        return true;
    }
}

// 如果请求的是实际存在的文件，直接返回
$file = __DIR__ . $uri;
if (is_file($file)) {
    // 根据文件扩展名设置正确的 Content-Type
    $ext = pathinfo($file, PATHINFO_EXTENSION);
    $mimeTypes = [
        'html' => 'text/html',
        'css' => 'text/css',
        'js' => 'application/javascript',
        'json' => 'application/json',
        'png' => 'image/png',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'gif' => 'image/gif',
        'svg' => 'image/svg+xml',
        'ico' => 'image/x-icon',
        'woff' => 'font/woff',
        'woff2' => 'font/woff2',
        'ttf' => 'font/ttf',
    ];
    
    if (isset($mimeTypes[$ext])) {
        header('Content-Type: ' . $mimeTypes[$ext]);
    }
    
    readfile($file);
    return true;
}

// 如果文件不存在，返回 404
http_response_code(404);
echo '404 - File Not Found';
return false;
