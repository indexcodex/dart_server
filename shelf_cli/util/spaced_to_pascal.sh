# Converts "hello world" -> "HelloWorld"
spaced_to_pascal() {
    echo "$1" | awk '{
        for (i=1; i<=NF; i++) {
            $i = toupper(substr($i,1,1)) substr($i,2)
        }
        printf "%s", $0
    }' | tr -d ' '
}