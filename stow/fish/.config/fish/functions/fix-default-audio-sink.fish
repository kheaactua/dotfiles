function fix-default-audio-sink --description "Set the default audio sink to the USB Composite Device (wpctl)"
    # This originally used pacmd, which is deprecated in favour of wpctl (WirePlumber).
    # The sink name only exists on the home machine; it may eventually need to
    # be read from a file on the host.
    if not type -q wpctl
        echo "fix-default-audio-sink: wpctl (WirePlumber) is not installed" >&2
        return 1
    end

    # Portable awk (no gawk-only match() array): the sink id is the last token
    # before ". USB Composite Device" in the Sinks section.
    set -l sink_id (wpctl status | awk '
        /Sinks:/ { in_sinks = 1; next }
        /Sources:/ { in_sinks = 0 }
        in_sinks && /USB Composite Device/ {
            sub(/\. USB Composite Device.*/, "")
            n = split($0, parts, " ")
            print parts[n]
            exit
        }')

    if test -n "$sink_id"
        wpctl set-default $sink_id
        echo "Default audio sink set to USB Composite Device Analog Stereo (ID: $sink_id)"
    else
        echo "Error: USB Composite Device Analog Stereo sink not found." >&2
        return 1
    end
end
