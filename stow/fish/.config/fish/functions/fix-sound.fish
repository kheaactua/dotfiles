function fix-sound --description "Print how to list and set the default audio sink"
    # Sometimes on reboot the default sinks aren't set
    echo "List sinks"
    echo "  pacmd list-sinks | grep -e 'name:' -e 'index:'"
    echo "Set default sink"
    echo "  pacmd set-default-sink <sink_name>"
    echo
    echo "Usually we're looking for <alsa_output.usb-Jieli_Technology_USB_Composite_Device-00.iec958-stereo>"
end
