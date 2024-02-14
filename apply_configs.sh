#!/bin/bash
cd $(dirname -- "$0")
DO_NOT_INSTALL=true ./install.sh apply_configs $@
#DO_NOT_INSTALL=true ./install.sh
