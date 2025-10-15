<?php
/**
 * 接口统一对接脚本
 * 用于规范化系统接口调用
 */

// 定义游戏统一代号映射
define('GAME_MAPPING', [
    // 中文名 => 英文代号
    '幸运飞艇' => 'pk10',
    '时时彩' => 'ssc',
    'ssc' => 'ssc',
    '北京28' => 'bj28',
    'bj28' => 'bj28',
    '加拿大28' => 'jnd28',
    'jnd28' => 'jnd28',
    '快3' => 'k3',
    'k3' => 'k3',
    '六合彩' => 'lhc',
    'lhc' => 'lhc',
    '新疆28' => 'xjp28',
    'xjp28' => 'xjp28',
]);

// WebSocket端口映射
define('WEBSOCKET_PORTS', [
    'pk10' => 15531,
    'ssc' => 15532,
    'lhc' => 15533,
    'bj28' => 15534,
    'jnd28' => 15535,
    'xjp28' => 15537,
    'k3' => 15538,
]);

// 游戏名称映射
define('GAME_NAMES', [
    'pk10' => '幸运飞艇',
    'ssc' => '时时彩',
    'bj28' => '北京28',
    'jnd28' => '加拿大28',
    'k3' => '快3',
    'lhc' => '六合彩',
    'xjp28' => '新疆28',
]);

/**
 * 获取游戏代号
 * @param string $game 游戏名称（中文或英文）
 * @return string 统一的游戏代号
 */
function getGameCode($game) {
    $mapping = GAME_MAPPING;
    return isset($mapping[$game]) ? $mapping[$game] : $game;
}

/**
 * 获取游戏名称
 * @param string $code 游戏代号
 * @return string 游戏中文名称
 */
function getGameName($code) {
    $names = GAME_NAMES;
    return isset($names[$code]) ? $names[$code] : $code;
}

/**
 * 获取WebSocket端口
 * @param string $game 游戏代号
 * @return int WebSocket端口号
 */
function getWebSocketPort($game) {
    $game = getGameCode($game);
    $ports = WEBSOCKET_PORTS;
    return isset($ports[$game]) ? $ports[$game] : 0;
}

/**
 * 获取WebSocket URL
 * @param string $game 游戏代号
 * @param string $host 主机地址（可选）
 * @return string WebSocket完整URL
 */
function getWebSocketUrl($game, $host = '') {
    if (empty($host)) {
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    }
    $port = getWebSocketPort($game);
    if ($port > 0) {
        return "ws://{$host}:{$port}";
    }
    return '';
}

/**
 * 统一接口返回格式
 * @param int $status 状态码 0=成功 其他=失败
 * @param string $msg 消息
 * @param mixed $data 数据
 * @return array
 */
function apiResponse($status = 0, $msg = 'success', $data = []) {
    return [
        'status' => $status,
        'msg' => $msg,
        'data' => $data,
        'time' => time()
    ];
}

/**
 * 错误返回
 * @param string $msg 错误消息
 * @param int $code 错误码
 * @return array
 */
function apiError($msg = 'error', $code = 1) {
    return apiResponse($code, $msg, []);
}

/**
 * 成功返回
 * @param mixed $data 数据
 * @param string $msg 消息
 * @return array
 */
function apiSuccess($data = [], $msg = 'success') {
    return apiResponse(0, $msg, $data);
}

/**
 * 验证参数
 * @param array $params 参数数组
 * @param array $rules 验证规则
 * @return bool|string true或错误消息
 */
function validateParams($params, $rules) {
    foreach ($rules as $field => $rule) {
        // 必填验证
        if (isset($rule['required']) && $rule['required']) {
            if (!isset($params[$field]) || $params[$field] === '') {
                return "{$rule['name']}不能为空";
            }
        }
        
        // 类型验证
        if (isset($params[$field]) && isset($rule['type'])) {
            switch ($rule['type']) {
                case 'int':
                    if (!is_numeric($params[$field])) {
                        return "{$rule['name']}必须是数字";
                    }
                    break;
                case 'float':
                    if (!is_numeric($params[$field])) {
                        return "{$rule['name']}必须是数字";
                    }
                    break;
                case 'string':
                    if (!is_string($params[$field])) {
                        return "{$rule['name']}必须是字符串";
                    }
                    break;
            }
        }
        
        // 范围验证
        if (isset($params[$field]) && isset($rule['range'])) {
            $value = $params[$field];
            if ($value < $rule['range'][0] || $value > $rule['range'][1]) {
                return "{$rule['name']}必须在{$rule['range'][0]}到{$rule['range'][1]}之间";
            }
        }
        
        // 长度验证
        if (isset($params[$field]) && isset($rule['length'])) {
            $len = mb_strlen($params[$field], 'UTF-8');
            if (isset($rule['length']['min']) && $len < $rule['length']['min']) {
                return "{$rule['name']}长度不能小于{$rule['length']['min']}";
            }
            if (isset($rule['length']['max']) && $len > $rule['length']['max']) {
                return "{$rule['name']}长度不能大于{$rule['length']['max']}";
            }
        }
    }
    return true;
}

/**
 * 游戏接口配置
 */
class GameApiConfig {
    
    // 下注接口参数规则
    public static function getBetRules() {
        return [
            'game' => [
                'required' => true,
                'name' => '游戏类型',
                'type' => 'string'
            ],
            'number' => [
                'required' => true,
                'name' => '期号',
                'type' => 'string'
            ],
            'type' => [
                'required' => true,
                'name' => '玩法类型',
                'type' => 'int'
            ],
            'jincai' => [
                'required' => true,
                'name' => '竞猜内容',
                'type' => 'string'
            ],
            'del_points' => [
                'required' => true,
                'name' => '下注金额',
                'type' => 'float',
                'range' => [1, 1000000]
            ]
        ];
    }
    
    // 充值接口参数规则
    public static function getRechargeRules() {
        return [
            'money' => [
                'required' => true,
                'name' => '充值金额',
                'type' => 'float',
                'range' => [1, 1000000]
            ],
            'pay_type' => [
                'required' => true,
                'name' => '支付方式',
                'type' => 'int'
            ],
            'pay_img' => [
                'required' => true,
                'name' => '支付凭证',
                'type' => 'string'
            ]
        ];
    }
    
    // 提现接口参数规则
    public static function getWithdrawRules() {
        return [
            'money' => [
                'required' => true,
                'name' => '提现金额',
                'type' => 'float',
                'range' => [10, 1000000]
            ],
            'pay_type' => [
                'required' => true,
                'name' => '提现方式',
                'type' => 'int'
            ]
        ];
    }
}

/**
 * API路由映射
 */
class ApiRouteMapping {
    
    // 前台接口路由
    public static function getFrontRoutes() {
        return [
            // 用户相关
            'user.login' => '/Home/Index/login',
            'user.register' => '/Home/Index/register',
            'user.logout' => '/Home/Index/logout',
            'user.info' => '/Home/User/index',
            'user.pwd' => '/Home/User/pwd',
            
            // 游戏相关
            'game.index' => '/Home/Run/index',
            'game.data' => '/Home/Run/get_data',
            'game.history' => '/Home/Run/history',
            'game.bet' => '/Home/Cai/add',
            'game.cancel' => '/Home/Cai/cancel',
            
            // 账户相关
            'account.recharge' => '/Home/Fen/addlist',
            'account.withdraw' => '/Home/Fen/xialist',
            'account.recharge_list' => '/Home/Fen/chong_list',
            'account.withdraw_list' => '/Home/Fen/xia_list',
            
            // 订单相关
            'order.list' => '/Home/Shou/record',
            'order.detail' => '/Home/Shou/detail',
            
            // 代理相关
            'agent.promote' => '/Home/User/tuiguang',
            'agent.subordinate' => '/Home/User/xiaji',
            'agent.commission' => '/Home/User/yongjin',
        ];
    }
    
    // 后台接口路由
    public static function getAdminRoutes() {
        return [
            // 管理员
            'admin.login' => '/Admin/Login/login',
            'admin.logout' => '/Admin/Login/logout',
            
            // 会员管理
            'member.list' => '/Admin/Member/index',
            'member.disable' => '/Admin/Member/disable',
            'member.enable' => '/Admin/Member/endisable',
            'member.edit' => '/Admin/Member/edit',
            'member.set_robot' => '/Admin/Member/set_robot',
            'member.set_agent' => '/Admin/Member/set_agent',
            
            // 订单管理
            'order.list' => '/Admin/Order/index',
            'order.delete' => '/Admin/Order/del',
            'order.cancel' => '/Admin/Order/admin_cancel',
            'order.statistics' => '/Admin/Order/win_lose',
            
            // 充值提现管理
            'recharge.list' => '/Admin/Fen/addlist',
            'recharge.check' => '/Admin/Fen/check',
            'withdraw.list' => '/Admin/Fen/xialist',
            'withdraw.check' => '/Admin/Fen/ignore',
            
            // 采集管理
            'caiji.bj28' => '/Admin/Caiji/bj28',
            'caiji.jnd28' => '/Admin/Caiji/jnd28',
            'caiji.ssc' => '/Admin/Caiji/ssc',
            'caiji.lhc' => '/Admin/Caiji/lhc',
            'caiji.pk10' => '/Admin/Caiji/幸运飞艇',
            
            // 系统设置
            'setting.site' => '/Admin/Site/site',
            'setting.game' => '/Admin/Site/game',
            'setting.pay' => '/Admin/Site/pay',
        ];
    }
    
    /**
     * 获取路由URL
     * @param string $key 路由键名
     * @param string $type 类型 front或admin
     * @return string
     */
    public static function getRoute($key, $type = 'front') {
        $routes = $type == 'admin' ? self::getAdminRoutes() : self::getFrontRoutes();
        return isset($routes[$key]) ? $routes[$key] : '';
    }
}

// 使用示例：
/*
// 1. 获取游戏代号
$gameCode = getGameCode('幸运飞艇'); // 返回 'pk10'

// 2. 获取WebSocket URL
$wsUrl = getWebSocketUrl('pk10'); // 返回 'ws://localhost:15531'

// 3. 统一返回格式
$result = apiSuccess(['user_id' => 123], '登录成功');
// 返回: ['status' => 0, 'msg' => '登录成功', 'data' => ['user_id' => 123], 'time' => 1697270400]

// 4. 参数验证
$params = ['game' => 'bj28', 'number' => '20251014001', ...];
$validation = validateParams($params, GameApiConfig::getBetRules());
if ($validation !== true) {
    echo $validation; // 输出错误信息
}

// 5. 获取路由
$loginUrl = ApiRouteMapping::getRoute('user.login'); // 返回 '/Home/Index/login'
*/
?>
