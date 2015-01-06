#!/bin/bash

# GIT FLOW wizard
# Author: Alex Sherman <alex@belleron.com>
#

readonly IS_DEBUG=false
source gf-colors.sh
source gf-git-constants.sh
source gf-git-functions.sh
source gf-git-operations.sh
source gf-git-menu.sh


checkDirWritable true

if ! $IS_DEBUG; then
	clear
fi

doMainMenu
