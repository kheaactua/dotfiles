# Initialize environment modules

set module_files /usr/share/modules/init/fish /etc/modules/init/fish

set found 0
for file in $module_files
  if test -f $file
    source $file
    set found 1
    break
  end
end

if test $found -eq 0
  echo "Environment modules not installed"
end

set -e file
set -e found
set -e module_files

# Add user modulefiles directory if it exists
if type -q module; and test -e "$HOME/.modulefiles"
  module use "$HOME/.modulefiles"
end
