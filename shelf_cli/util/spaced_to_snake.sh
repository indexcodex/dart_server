# Converts "hello world example" -> "hello_world_example"
spaced_to_snake() {
    input="$1"

    echo "$input" | awk '{
        for (i=1; i<=NF; i++) {
            $i = tolower($i)
        }
        printf "%s", $0
    }' | tr ' ' '_'
}