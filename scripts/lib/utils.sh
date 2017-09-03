#
#!/bin/sh
#
#

#########-----########
# import_share_libs _file_path_
# import_share_libs(){
#   local relativeDir="${relativeDir}${2:-}"
#   local all=$(find $PWD$relativeDir -type f -name *.sh)
#   local found
#   for script in $all; do
#     if [[ "$script" =~ .*/$1.* ]]; then
#       source $script
#       found=true
#     break
#     fi
#   done

#   if [[ ! $found ]]; then
#     import_share_libs $1 "/.."
#   fi
# }
# import_share_libs 'scripts/lib/assert'
#########-----########

set -euo pipefail
trap "echo 'error: Script failed: see failed command above'" ERR

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

source $DIR/assert.sh

##### color #####

# tput command Usage

# Foreground & background colour commands

# tput setab [1-7] # Set the background colour using ANSI escape
# tput setaf [1-7] # Set the foreground colour using ANSI escape

# Colours are as follows:

# Num  Colour    #define         R G B

# 0    black     COLOR_BLACK     0,0,0
# 1    red       COLOR_RED       1,0,0
# 2    green     COLOR_GREEN     0,1,0
# 3    yellow    COLOR_YELLOW    1,1,0
# 4    blue      COLOR_BLUE      0,0,1
# 5    magenta   COLOR_MAGENTA   1,0,1
# 6    cyan      COLOR_CYAN      0,1,1
# 7    white     COLOR_WHITE     1,1,1

# There are also non-ANSI versions of the colour setting functions (setb instead of setab, and setf instead of setaf)
# which use different numbers, not given here.
# Text mode commands

# tput bold    # Select bold mode
# tput dim     # Select dim (half-bright) mode
# tput smul    # Enable underline mode
# tput rmul    # Disable underline mode
# tput rev     # Turn on reverse video mode
# tput smso    # Enter standout (bold) mode
# tput rmso    # Exit standout mode

# Cursor movement commands

# tput cup Y X # Move cursor to screen postion X,Y (top left is 0,0)
# tput cuf N   # Move N characters forward (right)
# tput cub N   # Move N characters back (left)
# tput cuu N   # Move N lines up
# tput ll      # Move to last line, first column (if no cup)
# tput sc      # Save the cursor position
# tput rc      # Restore the cursor position
# tput lines   # Output the number of lines of the terminal
# tput cols    # Output the number of columns of the terminal

# Clear and insert commands

# tput ech N   # Erase N characters
# tput clear   # Clear screen and move the cursor to 0,0
# tput el 1    # Clear to beginning of line
# tput el      # Clear to end of line
# tput ed      # Clear to end of screen
# tput ich N   # Insert N characters (moves rest of line forward!)
# tput il N    # Insert N lines

# Other commands

# tput sgr0    # Reset text format to the terminal's default
# tput bel     # Play a bell

# $1: the prefix this log will use as "[prefix] xxxx"
use_red_green_echo() {
  prefix="$1"
  red() {
    echo "$(tput bold)$(tput setaf 1)[$prefix] $*$(tput sgr0)";
  }
  
  green() {
    echo "$(tput bold)$(tput setaf 2)[$prefix] $*$(tput sgr0)";
  }
  
  yellow() {
    echo "$(tput bold)$(tput setaf 3)[$prefix] $*$(tput sgr0)";
  }
}

##### common #####


##### npm #####

# $1: caller's path to package.json file
npm_install_if_needed(){
  local need=$($DIR/npm-dependency-checker.sh check_if_need_npm_install_with_finger_print_file "$1")
  if [[ $need == 1 ]]; then
    echo '--------------------'
    echo "Package dependency has changed, start npm install"
    echo '--------------------'
    
    if [[ $NODE_ENV == 'production' ]]; then
      npm i --only=production
    else
      npm i
    fi
    
    # npm i success, save the finger print, so next time the checker will know if dependency changes
    $DIR/npm-dependency-checker.sh gene_package_json_dependency_finger_print_file "$1"
  else
    echo '--------------------'
    echo "No dependency changes, no need to run npm install"
    echo '--------------------'
  fi
}
