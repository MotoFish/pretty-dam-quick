#!/usr/bin/env bash

perl Makefile.PL
make
make test
make install
