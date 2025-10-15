#!/usr/bin/env php
<?php
define('APP_PATH', __DIR__ . '/Application/');
define('RUNTIME_PATH', __DIR__ . '/Runtime/');
define('THINK_PATH', __DIR__ . '/ThinkPHP/');
define('APP_DEBUG', false);

$_SERVER['REQUEST_METHOD'] = 'GET';
$_SERVER['REMOTE_ADDR'] = '127.0.0.1';
$_SERVER['REQUEST_URI'] = '/';

require __DIR__ . '/ThinkPHP/ThinkPHP.php';

$controller = new \Home\Controller\WorkermanftController();
\Workerman\Worker::runAll();
