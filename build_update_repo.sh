#!/bin/bash

xdg-app build-update-repo --generate-static-deltas --prune --prune-depth=8  ${EXPORT_ARGS-} repo
