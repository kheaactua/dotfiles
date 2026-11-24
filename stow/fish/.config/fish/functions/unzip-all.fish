function unzip-all --description "Unzip every .zip below the given paths into a folder named after each archive"
    if not type -q fd
        echo "unzip-all: fd is not installed" >&2
        return 1
    end

    # fd's own placeholders ({//}, {/.}, {}) must reach fd unexpanded
    fd '\.zip$' $argv -x unzip -d '{//}/{/.}' '{}'
end
