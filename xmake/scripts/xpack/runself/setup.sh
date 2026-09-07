#!/bin/sh
# makeself extracts the archive to a temporary directory and runs this script
# from there, so the install prefix is the current working directory.
PREFIX="$(pwd)"
export PREFIX
