function detect_docker -d "Detect if running in Docker (1 if Docker, 0 otherwise)"
    if test -f /.dockerenv
        echo 1
    else
        echo 0
    end
end
