# Compiles the Dart server into a native executable
# Output format: bin/filename_v(version)

compile_server() {
    # Ask user for base filename
    printf "Enter filename: "
    read -r filename

    # Ask user for version
    printf "Enter version: "
    read -r version

    # Ensure bin directory exists (same level as export/)
    # -p: create parent directories if needed, and don’t error if it already exists
    mkdir -p bin

    # Build final output path
    # Example: bin/myserver_v1
    output="bin/${filename}_v${version}"

    # Inform user what will be built
    echo_blue "Compiling server..."

    # Run Dart compilation command
    if dart compile exe lib/main.dart --output="$output"; then

        # Success message
        echo_green "Successfully compiled $output"

    else
        # Failure message
        echo_red "Failed to compile $output"

        # Propagate error to caller
        return 1
    fi
}