function post_st --description "Upload stdin to 0x0.st and print the URL"
    curl -F 'file=@-' 0x0.st
end
