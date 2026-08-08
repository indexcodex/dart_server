#!/bin/sh

create_new_handler() {
    # Ask for handler name
    printf "Enter the handler name in lowercase, use space as separator (eg hello world): "
    read -r handler_input

    # Convert formats
    camel=$(spaced_to_camel "$handler_input")
    kebab=$(spaced_to_kebab "$handler_input")
    snake=$(spaced_to_snake "$handler_input")

    echo_blue "Select handler type:"
    echo " (1) GET handler"
    echo " (2) POST handler"

    printf "Choice: "
    read -r choice

    # Determine template based on choice
    case "$choice" in
        1)
            template="shelf_cli/files/get_handler.dart"
            echo_green "Selected GET handler"
            ;;
        2)
            template="shelf_cli/files/post_handler.dart"
            echo_green "Selected POST handler"
            ;;
        *)
            echo_red "Invalid option"
            return 1
            ;;
    esac

    # Ensure export folder exists
    mkdir -p export

    # Output file name (optional: you can rename it)
    output="export/${snake}.dart"

    # Copy template into export file
    cp "$template" "$output"

    # Replace placeholders safely
    sed -i '' "s/handlername/$camel/g" "$output"
    sed -i '' "s/handlerendpoint/$kebab/g" "$output"

    echo_green "Handler generated: $output"
}