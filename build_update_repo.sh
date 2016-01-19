#!/bin/bash

xdg-app build-update-repo --prune --prune-depth=20  ${EXPORT_ARGS-} repo
