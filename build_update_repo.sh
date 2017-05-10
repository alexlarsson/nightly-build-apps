#!/bin/bash

flatpak build-update-repo --generate-static-deltas --gpg-sign=44F17A57 --gpg-homedir=/home/jgrulich/.gnupg/ --prune --prune-depth=8  ${EXPORT_ARGS-} repo
