#!/bin/sh
# Use POSIX shell for maximum portability (macOS, Linux, Git Bash, etc.)

# Resolve the absolute path of the directory where this script lives
# This ensures all relative imports work no matter where you run the script from
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Import utility functions (e.g., colored echo helpers)
. "$SCRIPT_DIR/shelf_cli/util/rainbow_echo.sh"
. "$SCRIPT_DIR/shelf_cli/util/spaced_to_pascal.sh"
. "$SCRIPT_DIR/shelf_cli/util/spaced_to_camel.sh"
. "$SCRIPT_DIR/shelf_cli/util/spaced_to_kebab.sh"
. "$SCRIPT_DIR/shelf_cli/util/spaced_to_snake.sh"

# Import command modules (functions defined in these files)
. "$SCRIPT_DIR/shelf_cli/module/create_new_handler.sh"
. "$SCRIPT_DIR/shelf_cli/module/compile_server.sh"
. "$SCRIPT_DIR/shelf_cli/module/run_server.sh"
. "$SCRIPT_DIR/shelf_cli/module/clean_shelf.sh"

# Display CLI menu
echo "Welcome to Shelf-CLI! please select a command to run"
echo "(1) create new handler"
echo "(2) compile server"
echo "(3) run server"
echo "(4) clean shelf"

# Prompt user for input (POSIX-safe: avoid read -p)
printf "Run command number: "
read -r option   # -r prevents backslash escaping issues

# Handle user selection using case statement
case "${option}" in
    1)
        # Call function defined in create_new_handler.sh
        create_new_handler
        ;;
    2)
        # Call function defined in compile_server.sh
        compile_server
        ;;
    3)
        # Call function defined in run_server.sh
        run_server
        ;;
    4)
        # Call function defined in clean_shelf.sh
        clean_shelf
        ;;
    *)
        # Invalid input: print error in red (fallback using tput)
        echo_red "Selected option is invalid, please try again"
        ;;
esac