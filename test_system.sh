#!/bin/bash
# 彩票系统快速测试脚本

echo "=================================="
echo "   彩票系统 - 快速测试"
echo "=================================="
echo ""

# 1. 检查PHP
echo "[1/8] 检查PHP环境..."
if command -v php >/dev/null 2>&1; then
    PHP_VERSION=$(php -v | head -n 1)
    echo "✓ $PHP_VERSION"
else
    echo "✗ PHP未安装"
    exit 1
fi

# 2. 检查数据库连接
echo ""
echo "[2/8] 检查数据库配置..."
if [ -f "Application/Common/Conf/config.php" ]; then
    echo "✓ 配置文件存在"
else
    echo "✗ 配置文件不存在"
fi

# 3. 检查Workerman服务
echo ""
echo "[3/8] 检查Workerman服务..."
FT_PID=$(ps aux | grep "WorkermanftController" | grep -v grep | wc -l)
SSC_PID=$(ps aux | grep "WorkermansscController" | grep -v grep | wc -l)

if [ $FT_PID -gt 0 ]; then
    echo "✓ 幸运飞艇服务运行中"
else
    echo "✗ 幸运飞艇服务未运行"
fi

if [ $SSC_PID -gt 0 ]; then
    echo "✓ 时时彩服务运行中"
else
    echo "✗ 时时彩服务未运行"
fi

# 4. 检查端口
echo ""
echo "[4/8] 检查端口占用..."
if command -v netstat >/dev/null 2>&1; then
    PORT_15531=$(netstat -tln 2>/dev/null | grep ":15531" | wc -l)
    PORT_15532=$(netstat -tln 2>/dev/null | grep ":15532" | wc -l)
    
    if [ $PORT_15531 -gt 0 ]; then
        echo "✓ 端口 15531 (幸运飞艇) 正在监听"
    else
        echo "✗ 端口 15531 未监听"
    fi
    
    if [ $PORT_15532 -gt 0 ]; then
        echo "✓ 端口 15532 (时时彩) 正在监听"
    else
        echo "✗ 端口 15532 未监听"
    fi
else
    echo "⚠ 无法检查端口(netstat未安装)"
fi

# 5. 检查关键文件
echo ""
echo "[5/8] 检查关键文件..."
MISSING_FILES=0

check_file() {
    if [ -f "$1" ]; then
        echo "✓ $1"
    else
        echo "✗ $1 不存在"
        MISSING_FILES=$((MISSING_FILES+1))
    fi
}

check_file "Application/Home/Controller/RunController.class.php"
check_file "Application/Home/Controller/WorkermanftController.class.php"
check_file "Application/Home/Controller/WorkermansscController.class.php"
check_file "Template/Home/Run/xyft.html"
check_file "Template/Home/Run/ssc.html"

# 6. 检查数据库表
echo ""
echo "[6/8] 检查数据库表结构..."
echo "⚠ 需要手动验证以下表："
echo "  - think_number (开奖号码)"
echo "  - think_order (下注订单)"
echo "  - think_user (用户信息)"
echo "  - think_config (系统配置)"

# 7. 测试路由
echo ""
echo "[7/8] 关键路由列表..."
echo "  首页:     /index.php/Home/Shou/index"
echo "  游戏大厅: /index.php/Home/Run/index"
echo "  幸运飞艇: /index.php/Home/Run/xyft"
echo "  时时彩:   /index.php/Home/Run/ssc"
echo "  个人中心: /index.php/Home/User/index"
echo "  走势图:   /index.php/Home/Run/trend"

# 8. 检查日志文件
echo ""
echo "[8/8] 检查日志文件..."
if [ -f "webserver.log" ]; then
    LOG_SIZE=$(du -h webserver.log | cut -f1)
    echo "✓ webserver.log ($LOG_SIZE)"
else
    echo "⚠ webserver.log 不存在"
fi

# 总结
echo ""
echo "=================================="
echo "   测试完成"
echo "=================================="
echo ""

if [ $MISSING_FILES -gt 0 ]; then
    echo "⚠ 发现 $MISSING_FILES 个文件缺失"
fi

if [ $FT_PID -eq 0 ] || [ $SSC_PID -eq 0 ]; then
    echo ""
    echo "建议操作："
    echo "  1. 启动服务: ./start_ubuntu.sh start"
    echo "  2. 查看状态: ./start_ubuntu.sh status"
    echo "  3. 查看日志: tail -f webserver.log"
fi

echo ""
echo "如需详细信息，请查看: 接口修复完成报告_20251014.md"
echo ""
