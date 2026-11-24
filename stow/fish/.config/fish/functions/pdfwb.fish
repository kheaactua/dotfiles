function pdfwb --description "Convert a PDF to black and white (grayscale), writing <name>.bw.pdf"
    if test (count $argv) -ne 1
        echo "Usage: pdfwb <file.pdf>" >&2
        return 1
    end

    if not type -q gs
        echo "pdfwb: ghostscript (gs) is not installed" >&2
        return 1
    end

    set -l input $argv[1]
    set -l output (string replace -r '\.pdf$' '.bw.pdf' -- $input)
    if test "$output" = "$input"
        # Not named *.pdf; never overwrite the input
        set output "$input.bw.pdf"
    end

    gs \
        -sOutputFile="$output" \
        -sDEVICE=pdfwrite \
        -sColorConversionStrategy=Gray \
        -dProcessColorModel=/DeviceGray \
        -dCompatibilityLevel=1.4 \
        -dNOPAUSE \
        -dBATCH \
        -dPDFSETTINGS=/ebook \
        $input
end
