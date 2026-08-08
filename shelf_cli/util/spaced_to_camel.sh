# Converts "hello world" -> "helloWorld"
spaced_to_camel() {
    echo "$1" | awk '{
        for (i=1; i<=NF; i++) {
            if (i == 1)
                $i = tolower($i)
            else
                $i = toupper(substr($i,1,1)) substr($i,2)
        }
        printf "%s", $0
    }' | tr -d ' '
}