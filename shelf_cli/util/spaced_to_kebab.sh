# Converts "hello world" -> "hello-world"
spaced_to_kebab() {
    input="$1"

    echo "$input" | awk '{
        for (i=1; i<=NF; i++) {
            $i = tolower($i)
        }
        printf "%s", $0
    }' | tr ' ' '-'
}