{ # this ensures the entire script is downloaded #

tms_echo() {
  command printf %s\\n "$*" 2>/dev/null
}

tms() {
    TMS_PY_PATH="$HOME/.tms/tms.py"
    if [ -f "$TMS_PY_PATH" ]; then
        python3 "$TMS_PY_PATH" "$@"
    else
        tms_echo "Error: tms.py does not exist at path: $TMS_PY_PATH"
        exit 1
    fi
}

} # this ensures the entire script is downloaded #