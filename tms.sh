{ # this ensures the entire script is downloaded #

tms_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

tms() {
    # 获取run脚本的绝对路径
    RUN_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # 假设main.py位于run脚本的同级目录下的bin文件夹内
    MAIN_PY_PATH="$(dirname "$RUN_SCRIPT_PATH")/tms.py"

    # 检查main.py是否存在
    if [ -f "$MAIN_PY_PATH" ]; then
        # 使用python执行main.py
        python "$MAIN_PY_PATH"
    else
        echo "Error: main.py does not exist at path: $MAIN_PY_PATH"
        exit 1
    fi
}

} # this ensures the entire script is downloaded #