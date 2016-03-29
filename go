#!/usr/bin/env bash

#install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Make it so that we can use our Brewfile
brew tap 'homebrew/brewdler'
brew brewdle

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Display full POSIX path as Finder window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Show the /Volumes folder
sudo chflags nohidden /Volumes

#install module
perl Makefile.PL
make
make test
sudo make install
