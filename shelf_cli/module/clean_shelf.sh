clean_shelf() {
    printf "Delete bin/ and export/ folders? (y/n): "
    read -r permission

    case "$permission" in
        y|Y)
            echo_blue "Deleting folders..."

            rm -rf "$SCRIPT_DIR/bin"
            rm -rf "$SCRIPT_DIR/export"

            echo_green "Cleanup complete"
            ;;
        *)
            echo_blue "Cancelled"
            ;;
    esac
}