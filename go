#!/usr/bin/env bash

#install homebrew
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# Make it so that we can use our Brewfile
brew tap 'homebrew/brewdler'
brew brewdle

#install module
perl Makefile.PL
make
make test
make install
