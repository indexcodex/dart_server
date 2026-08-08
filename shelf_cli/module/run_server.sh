# Runs a compiled server binary from /bin folder
# Expected format: bin/filename_v(version)

run_server() {
    # Ask for filename
    printf "Enter filename: "
    read -r filename

    # Ask for version
    printf "Enter version: "
    read -r version

    # Build full binary path
    # Example: bin/myserver_v1
    binary="bin/${filename}_v${version}"

    echo_blue "Starting server $binary"

    # Check if file exists before running
    if [ ! -f "$binary" ]; then
        echo_red "Error: binary '$binary' not found"
        return 1
    fi

    # Ensure it is executable (safe fallback)
    chmod +x "$binary" 2>/dev/null

    # Run the server
    "./$binary"
}