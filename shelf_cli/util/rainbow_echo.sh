# Print text in a specified color using tput
print_color() {
  color="$1"     # First argument = color code (0–7)
  shift          # Remove first argument so remaining args are the message

  # Set foreground color (silence errors if terminal doesn't support it)
  tput setaf "$color" 2>/dev/null

  # Print all remaining arguments as the message
  # "$@" preserves spacing and multiple words
  echo "$@"

  # Reset terminal formatting back to default
  tput sgr0 2>/dev/null
}

# Convenience wrapper functions for each color
# These make the API cleaner and more readable in your CLI

echo_black()   { print_color 0 "$@"; }  # Black text
echo_red()     { print_color 1 "$@"; }  # Red text (errors)
echo_green()   { print_color 2 "$@"; }  # Green text (success)
echo_yellow()  { print_color 3 "$@"; }  # Yellow text (warnings)
echo_blue()    { print_color 4 "$@"; }  # Blue text
echo_magenta() { print_color 5 "$@"; }  # Magenta text
echo_cyan()    { print_color 6 "$@"; }  # Cyan text
echo_white()   { print_color 7 "$@"; }  # White text