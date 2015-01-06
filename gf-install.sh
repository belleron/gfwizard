#!/bin/bash
# Install/Update script for Git Wizard
# Author: Alex Sherman <alexs@spiralsolutions.com>
#
source sp-colors.sh
source sp-git-constants.sh
source sp-git-functions.sh

readonly IS_DEBUG=false
script=$(readlink -f "${BASH_SOURCE[0]}")

strCurrentDir=$(pwd)
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
print_info "SP-GitFlow" "Checking for updates..."
git pull
git submodule update --init --recursive
strAlias=$(grep -s 'sp.sh' $HOME/.bashrc)
if [ -z "$strAlias" ]; then
	print_info "Command alias" "Setting..."
	alias sp='sp.sh'
	echo  "alias sp='sp.sh'" >> $HOME/.bashrc
fi
# Set origin...
git config remote.origin.url git@gitlab.spiralsolutions.co.il:devops/sp-gitflow.git

#Composer update for GitLab
cd gitlab

git config --unset sp.cleantags
git config --add sp.cleantags false

../composer update
cd ..


doFlowConfig false

#Add to cronjob
strCronTag="# SP-INSTALL"

crontab -l 2>/dev/null | grep -x "$strCronTag" >/dev/null 2>/dev/null

RETVAL=$?
$IS_DEBUG && print_info "crontab" $RETVAL

if [[ $RETVAL -ne 0 ]]; then
	print_info "Crontab" "installing..."
	cmd="crontab -l 2>/dev/null | { cat; echo \"${strCronTag}\"; echo \"@daily ${script}\" ; echo; } | crontab -"
	eval $cmd 
fi
# End of crontab handling

cd $strCurrentDir
