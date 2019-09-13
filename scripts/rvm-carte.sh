#!/usr/bin/env bash

# Xcode scripting does not invoke rvm. To get the correct ruby,
# we must invoke rvm manually. This requires loading the rvm 
# *shell function*, which can manipulate the active shell-script
# environment.
# cf. http://rvm.io/workflow/scripting

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then

  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"

elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then

  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else

  printf "ERROR: An RVM installation was not found.\n"
  exit 128
fi

# rvm will use the controlling versioning (e.g. .ruby-version) for the
# pwd using this function call.
rvm use .

ruby -v

rvm info

if [[ $1 == "pre" ]]
then
    ./scripts/invoke-rvm.sh
    ruby ${PODS_ROOT}/Carte/Sources/Carte/carte.rb pre
elif [[ $1 == "post" ]]
then
    ./scripts/invoke-rvm.sh
    ruby ${PODS_ROOT}/Carte/Sources/Carte/carte.rb post
else
    echo "Invalid argument"
    exit 1
fi
