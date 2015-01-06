#!/usr/bin/env bash
# Install/Update script for Git Wizard
# Author: Alex Sherman <alex@belleron.com>
#
source gf-colors.sh
source gf-git-constants.sh
source gf-git-functions.sh

readonly IS_DEBUG=false
readonly GFWIZARD_REPO="https://github.com/belleron/gfwizard.git"

script=$(readlink -f "${BASH_SOURCE[0]}")

strCurrentDir=$(pwd)
cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
print_info "GF-GitFlow" "Checking for updates..."
git pull
git submodule update --init --recursive
strAlias=$(grep -s 'gf.sh' $HOME/.bashrc)
if [ -z "$strAlias" ]; then
	print_info "Command alias" "Setting..."
	alias gf='gf.sh'
	echo  "alias gf='gf.sh'" >> $HOME/.bashrc
fi
# Set origin...
git config remote.origin.url $GFWIZARD_REPO

#Composer update for GitLab
cd gitlab

git config --unset gf.cleantags
git config --add gf.cleantags false

../composer update
cd ..


doFlowConfig false

#Add to cronjob
strCronTag="# GF-INSTALL"

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
