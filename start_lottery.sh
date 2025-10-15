#!/bin/bash
# ================================================================
# 彩票系统 - 完整启动脚本 (Ubuntu/Debian)
# 支持游戏: 幸运飞艇, 重庆时时彩
# ================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录 (自动检测)
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# 日志目录
LOG_DIR="$PROJECT_DIR/Runtime/Logs"
mkdir -p "$LOG_DIR"

# ================================================================
# 打印函数
# ================================================================
print_header() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${GREEN}           彩票系统 - 启动管理脚本 v2.0${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# ================================================================
# 检查函数
# ================================================================
check_php() {
    if ! command -v php &> /dev/null; then
        print_error "PHP未安装!"
        exit 1
    fi
    local php_version=$(php -v | head -n 1 | awk '{print $2}')
    print_success "PHP版本: $php_version"
}

check_extensions() {
    local required_exts=("mysqli" "pdo" "json" "sockets" "pcntl" "posix")
    for ext in "${required_exts[@]}"; do
        if php -m | grep -q "^$ext$"; then
            print_info "扩展 $ext: 已安装"
        else
            print_warning "扩展 $ext: 未安装"
        fi
    done
}

check_port() {
    local port=$1
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # 端口已占用
    elif ss -tuln 2>/dev/null | grep -q ":$port "; then
        return 0  # 端口已占用
    else
        return 1  # 端口未占用
    fi
}

# ================================================================
# 启动服务
# ================================================================
start_service() {
    print_header
    print_success "开始启动彩票系统..."
    echo ""
    
    # 检查环境
    print_info "检查 PHP 环境..."
    check_php
    check_extensions
    
    # 检查Workerman库
    print_info "检查 Workerman 库..."
    if [ -d "$PROJECT_DIR/vendor/workerman" ] || [ -d "$PROJECT_DIR/ThinkPHP/Library/Workerman" ]; then
        print_success "Workerman 已安装"
    else
        print_error "Workerman 未安装, 请运行: composer install"
        exit 1
    fi
    
    echo ""
    print_success "启动服务..."
    echo ""
    
    # 1. 启动幸运飞艇 WebSocket 服务器
    print_info "启动幸运飞艇服务器 (端口 15531)..."
    if check_port 15531; then
        print_warning "幸运飞艇服务器已在运行 (PID: $(lsof -ti:15531 2>/dev/null || ss -lptn 'sport = :15531' 2>/dev/null | grep -oP 'pid=\K[0-9]+'))"
    else
        nohup php "$PROJECT_DIR/index.php" Home/Workermanft/start > "$LOG_DIR/workerman_xyft.log" 2>&1 &
        sleep 2
        if check_port 15531; then
            print_success "幸运飞艇服务器启动成功 (PID: $!)"
        else
            print_error "幸运飞艇服务器启动失败, 查看日志: $LOG_DIR/workerman_xyft.log"
        fi
    fi
    
    # 2. 启动时时彩 WebSocket 服务器
    print_info "启动时时彩服务器 (端口 15532)..."
    if check_port 15532; then
        print_warning "时时彩服务器已在运行 (PID: $(lsof -ti:15532 2>/dev/null || ss -lptn 'sport = :15532' 2>/dev/null | grep -oP 'pid=\K[0-9]+'))"
    else
        nohup php "$PROJECT_DIR/index.php" Home/Workermanssc/start > "$LOG_DIR/workerman_ssc.log" 2>&1 &
        sleep 2
        if check_port 15532; then
            print_success "时时彩服务器启动成功 (PID: $!)"
        else
            print_error "时时彩服务器启动失败, 查看日志: $LOG_DIR/workerman_ssc.log"
        fi
    fi
    
    echo ""
    print_header
    print_success "🎉 系统启动完成!"
    echo ""
    
    # 显示访问地址
    print_info "访问地址:"
    print_success "  🌐 主系统:      http://localhost/index.php"
    print_success "  🎮 幸运飞艇:    http://localhost/index.php/Home/Run/xyft"
    print_success "  🎮 时时彩:      http://localhost/index.php/Home/Run/ssc"
    print_success "  📱 首页:        http://localhost/  (需配置Nginx)"
    print_success "  👤 个人中心:    http://localhost/index.php/Home/User/index"
    print_success "  🔐 后台管理:    http://localhost/index.php/Admin/Login/index"
    echo ""
    
    print_info "WebSocket服务:"
    print_success "  🎮 幸运飞艇:    ws://localhost:15531"
    print_success "  🎮 时时彩:      ws://localhost:15532"
    echo ""
    
    print_info "日志文件:"
    print_success "  📄 幸运飞艇:    $LOG_DIR/workerman_xyft.log"
    print_success "  📄 时时彩:      $LOG_DIR/workerman_ssc.log"
    echo ""
    
    print_info "查看状态: $0 status"
    print_info "停止服务: $0 stop"
    echo ""
}

# ================================================================
# 停止服务
# ================================================================
stop_service() {
    print_header
    print_info "停止所有服务..."
    echo ""
    
    # 停止幸运飞艇
    if check_port 15531; then
        print_info "停止幸运飞艇服务器..."
        php "$PROJECT_DIR/index.php" Home/Workermanft/stop > /dev/null 2>&1
        sleep 2
        if ! check_port 15531; then
            print_success "幸运飞艇服务器已停止"
        else
            print_warning "强制停止幸运飞艇服务器..."
            kill -9 $(lsof -ti:15531 2>/dev/null || ss -lptn 'sport = :15531' 2>/dev/null | grep -oP 'pid=\K[0-9]+') 2>/dev/null
            print_success "幸运飞艇服务器已强制停止"
        fi
    else
        print_info "幸运飞艇服务器未运行"
    fi
    
    # 停止时时彩
    if check_port 15532; then
        print_info "停止时时彩服务器..."
        php "$PROJECT_DIR/index.php" Home/Workermanssc/stop > /dev/null 2>&1
        sleep 2
        if ! check_port 15532; then
            print_success "时时彩服务器已停止"
        else
            print_warning "强制停止时时彩服务器..."
            kill -9 $(lsof -ti:15532 2>/dev/null || ss -lptn 'sport = :15532' 2>/dev/null | grep -oP 'pid=\K[0-9]+') 2>/dev/null
            print_success "时时彩服务器已强制停止"
        fi
    else
        print_info "时时彩服务器未运行"
    fi
    
    echo ""
    print_success "✅ 所有服务已停止"
    echo ""
}

# ================================================================
# 查看状态
# ================================================================
status_service() {
    print_header
    print_info "检查服务状态..."
    echo ""
    
    # 幸运飞艇状态
    if check_port 15531; then
        local pid=$(lsof -ti:15531 2>/dev/null || ss -lptn 'sport = :15531' 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1)
        print_success "幸运飞艇服务器: 运行中 (PID: $pid, 端口: 15531)"
    else
        print_error "幸运飞艇服务器: 未运行"
    fi
    
    # 时时彩状态
    if check_port 15532; then
        local pid=$(lsof -ti:15532 2>/dev/null || ss -lptn 'sport = :15532' 2>/dev/null | grep -oP 'pid=\K[0-9]+' | head -1)
        print_success "时时彩服务器: 运行中 (PID: $pid, 端口: 15532)"
    else
        print_error "时时彩服务器: 未运行"
    fi
    
    echo ""
    
    # Workerman进程
    print_info "Workerman 进程:"
    ps aux | grep -E "Workerman(ft|ssc)" | grep -v grep | awk '{printf "  PID: %s, CPU: %s%%, MEM: %s%%, CMD: %s\n", $2, $3, $4, $11}'
    
    echo ""
}

# ================================================================
# 重启服务
# ================================================================
restart_service() {
    stop_service
    sleep 3
    start_service
}

# ================================================================
# 查看日志
# ================================================================
view_logs() {
    print_header
    echo "选择要查看的日志:"
    echo "1) 幸运飞艇日志"
    echo "2) 时时彩日志"
    echo "3) 系统错误日志"
    read -p "请输入选项 [1-3]: " choice
    
    case $choice in
        1)
            print_info "幸运飞艇日志 (最后50行):"
            tail -50 "$LOG_DIR/workerman_xyft.log"
            ;;
        2)
            print_info "时时彩日志 (最后50行):"
            tail -50 "$LOG_DIR/workerman_ssc.log"
            ;;
        3)
            print_info "系统错误日志 (最后50行):"
            tail -50 "$LOG_DIR/$(date +%y_%m_%d).log"
            ;;
        *)
            print_error "无效选项"
            ;;
    esac
}

# ================================================================
# 主菜单
# ================================================================
show_menu() {
    print_header
    echo "请选择操作:"
    echo "1) 启动服务"
    echo "2) 停止服务"
    echo "3) 重启服务"
    echo "4) 查看状态"
    echo "5) 查看日志"
    echo "6) 退出"
    echo ""
    read -p "请输入选项 [1-6]: " choice
    
    case $choice in
        1) start_service ;;
        2) stop_service ;;
        3) restart_service ;;
        4) status_service ;;
        5) view_logs ;;
        6) exit 0 ;;
        *) print_error "无效选项" ;;
    esac
}

# ================================================================
# 命令行参数处理
# ================================================================
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        status_service
        ;;
    logs)
        view_logs
        ;;
    *)
        show_menu
        ;;
esac
