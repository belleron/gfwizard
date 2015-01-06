#!/usr/bin/env bash

# Functions for use in GIT FLOW wizard
# Author: Alex Sherman <alexs@spiralsolutions.com>
#

# Initialize global vars
function initVars() {
	if [ -f "$CONFIG_FILE" ]; then
		source $CONFIG_FILE
	fi	

	if  $IS_DEBUG; then 
		print_msg "Init Vars started..." true
		print_info "PARAM1 (force)" $1
	fi

	#check the force flag
	if $1; then
		boolForce=true
	else
		boolForce=false
	fi


	if [ -z $boolInitialized -o $boolInitialized -o $boolForce ]; then
		if $IS_DEBUG; then
			echo "Initializing..."
		fi
	
		#check if Git installed
		intGitErrors=$(hash git 2>&1 >/dev/null | grep -c "not found")
		if [ 0 -eq $intGitErrors ]; then
			boolGitInstalled=true
		else
			boolGitInstalled=false
		fi

		if $boolGitInstalled; then
			intFlowErrors=$(git flow 2>&1 >/dev/null | grep 'is not a git command' -c)
			if [ 0 -eq $intFlowErrors ]; then
				boolGitFlowInstalled=true
			else
				boolGitFlowInstalled=false
			fi
		
			# Check if Git Repo present
			if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
				boolGit=true
				
				#Check if GitFlow was initialized
				intHasGitFlow=$(git config -l | grep "^gitflow" -c)
				if [ 0 -eq $intHasGitFlow ]; then
					boolGitFlow=false
				else
					boolGitFlow=true
				fi
				
				#Get current bracn name
		        strBranch=$(git rev-parse --abbrev-ref HEAD)
		        #Parse branch for type detection
				arrBranchParts=(${strBranch//// });
				strCurrentType=${arrBranchParts[0]};		        
				strVersionPrefix=$(git config gitflow.prefix.versiontag)
				getLatestVersion
		    else
				boolGit=false
		    fi
			boolInitialized=true
		else 
			#no Git
			showError "Git is not found on system or not in \$PATH"	true
			exit
		fi #end of git present on system
	fi #end of Init Required

	if [ -z $boolStartUpInitialize ]; then
		print_msg "Initializing..."
		boolStartUpInitialize=true
		if $boolGit; then
			doFindStaleBranches
			if [ -z $2 ]; then
				clear
			fi			
		fi
	fi

	if $IS_DEBUG; then
		print_info "boolForce" $boolForce
		print_info "boolGitInstalled" $boolGitInstalled
		print_info "boolGitFlowInstalled" $boolGitFlowInstalled
		print_info "boolGit" $boolGit
		print_info "boolGitFlow" $boolGitFlow
		print_info "boolInitialized" $boolInitialized
  	    print_msg "InitVars - Done"
	fi
}

function showWizardVersion() {
	strCurrentWorkingDir=$(pwd)
	cd $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
	
	strWizardBranch=$(git rev-parse --abbrev-ref HEAD)
	
	if [ "$strWizardBranch" != "master" ]; then
		print_info "Wizard Branch" "${BRed}${strWizardBranch}${Color_Off}"
	fi
	getLatestVersion
	print_info "Master Wizard Version" "${strLatestVersion}"
	

	cd $strCurrentWorkingDir
}


function doFindStaleBranches() {
	local boolAllowCleanup=true
	local intChanges=$(git status --porcelain | grep  -v -c "??")
	if ((0 < $intChanges )); then
		showError "You did not commit all changes. Please commit all before repository cleanup!" true
		local boolAllowCleanup=false
	fi

	local cmd="git log --pretty=format:%H origin/${strBranch}..${strBranch} | grep -c ^"
	local intNotPushed=$(eval $cmd)
	if (( 0 < $intNotPushed )); then
		showError "You did not push all changes. Please push all before repository cleanup!" true
		local boolAllowFinish=false
	fi

	if $boolAllowCleanup; then
		print_msg "Checking for stale branches fully merged to develop..."
		git checkout ${strGitDevelop}
		git fetch --all
		git pull
		git remote prune origin
		arrBranchesToRemove=$(git branch -a --merged | sed 's/*//' | grep -v ${strGitDevelop} | grep -v ${strGitMaster} )
		if [ -n "$arrBranchesToRemove" ]; then
			for strBranchToRemove in $arrBranchesToRemove
			do
				if [[ $strBranchToRemove == "remotes/origin/"* ]]; then
					print_info "Stale branch (remote)" "${strBranchToRemove#"remotes/origin/"}" 
				else
					print_info "Stale branch (local )" "$strBranchToRemove"
				fi
			done
			doConfirm "doCleanBranches" "Do you want to remove stale branches?" "-----------------------"
		else
			echo "No brnaches to remove"
		fi
		git checkout ${strBranch}
#	else
#		pause
	fi
}

function doCleanBranches() {
	local boolError=false
	if [ -n "$arrBranchesToRemove" ]; then
		print_msg "Removing stale branches..."
		for strBranchToRemove in $arrBranchesToRemove
		do
			unset cmd
			if [[ $strBranchToRemove == "remotes/origin/"* ]]; then
				strBranchToRemove="${strBranchToRemove#"remotes/origin/"}"
				$IS_DEBUG && print_info "Removing remote" "$strBranchToRemove "	
				cmd="git push origin :${strBranchToRemove}"
				$IS_DEBUG && print_info "Command" "$cmd"
			else
				$IS_DEBUG && print_info "Removing local " "$strBranchToRemove "	
				cmd="git branch -d ${strBranchToRemove}"
				$IS_DEBUG && print_info "Command" "$cmd"
			fi
			if [ -n "$cmd" ]; then
				eval "$cmd"
				if [[ $? -ne 0 ]]; then
					print_error "Removing $strBranchToRemove" "Error occured"
					boolError=true
				else
					print_info "Removing $strBranchToRemove" "Success"
				fi
			else
				print_error "Removing $strBranchToRemove" "Command not set"
			fi
		done
	else
		echo "No brnaches to remove"
	fi

	if $boolError; then
		print_error "Removing branches" "Errors occured. Please review messages above."
		pause
	fi
}

function cleanVersionTags() {
	print_msg "Checking for stale or invalid tags..."
	fetchTags true
	cmd="git tag -l | grep -c -v '${strTagRegex}'"
	intStaleTags=$(eval $cmd)
	if  [ $intStaleTags -gt 0 ]; then
		print_msg "Cleaning version tags..."
		cmd="git tag -l | grep -v '${strTagRegex}'"
		tags=$(eval $cmd)
		for tag in $tags 
		do 
			git tag -d $tag
			git push origin :$tag
		done
	fi
}


# Check if current dir is writable
# @param $1 bool - if true, halt on not writable current folder
function checkDirWritable() {
	strDir=$(pwd)
	if [ ! -w $strDir ]; then 
	 	showError "Current folder is not writeble" false
	 	if $1; then
	 		exit 1
	 	fi
	fi
}


# Show confirm dialog
# @param $1 string command to execute on YES
# @param [$2] Prompt question
# @param [$3] string additional message to show before the confirm dialog
# @param [$4] default answer [Y/N]
function doConfirm() {
	#get user's confirtmation
	local debug=$IS_DEBUG

	if $debug; then
		echo "Comand to execute: "$1
	fi
	echo -e $3
	strPrompt=${2:-"Do you wish to continue?"}

	case $4 in
		[nN] )
			read -p "$strPrompt [y/N]" strContinue
			strContinue=${strContinue:-N}
			;;
		* )
			read -p "$strPrompt [Y/n]" strContinue
			strContinue=${strContinue:-Y}
			;;
	esac
	
	if $debug; then
		echo "$strContinue"
	fi
	
	case $strContinue in 
		[yY] )
			eval "$1"
			;;
	esac
}

# Wait until user hits Enter
# @param [$1] Message to show on waiting...
function pause(){
	if [ -z $1 ]; then 
		read -p "Hit [Enter] to continue..."
	else
		read -p "$*"
	fi
}


# Show formatted error message
# @param $1 string error message text
# @param [$2] bool pause after error, default = true
function showError() {
	echo -e ${BRed}${1}${Color_Off}
	if [ ! $2 ]; then
		pause
	fi
}

function printCurrentBranch() {
	local debug=$IS_DEBUG
	echo -e "Current branch is: "${On_Blue}${strBranch}${Color_Off};
	if [ $1 ]; then
		echo -e "Current dir: "${BCyan}$(pwd)${Color_Off}
	fi

	if [[ $2 ]]; then
		echo -e "Current version on master: "${BYellow}${strLatestVersion}${Color_Off}
	fi
}

# sets global var $strTagPrefix
# @param branch type
function getTagPrefix() {
	local debug=$IS_DEBUG
	#debug=true
	local boolForSearch=$1
	local strType=$2
	if [ -z $strType ]; then
		strType=$strCurrentType
	fi
	$debug && print_info "Tag prefix for Search" $boolForSearch
	local strCurrentPrefix
	# echo $strCurrentType
	#Define tag prefix
	case $strType in
		$strGitFeature)
			strCurrentPrefix="${strBranch}/build."
			;;
		$strGitRelease)
			strCurrentPrefix="${strCurrentType}/${strVersionPrefix}${arrBranchParts[1]}."
			;;
		$strGitMaster)
			strCurrentPrefix=$(git config gitflow.prefix.versiontag)
			;;
		*)
			strCurrentPrefix=""
			#Do not add astrisk in case of empty tagPrefix in any case
			boolForSearch=false;
			;;
	esac
	if $boolForSearch; then 
	 	strTagPrefix="${strCurrentPrefix}*"
	else 
		strTagPrefix="${strCurrentPrefix}"
	fi
	$IS_DEBUG && print_info "Tag for search" "$boolForSearch"
	$IS_DEBUG && print_info "Tag Prefix" "$strTagPrefix"
}

function getLastBuildByTag() {
	intLastBuild=0
	for tag in $(git tag -l $1*)
	do
		intBuild=${tag##*.}
		if (( $intLastBuild < $intBuild )); then
			intLastBuild=$intBuild
		fi
	done
}


function printCurrentTags() {
	getTagPrefix true
	local cmd
	print_msg "Current Tags" true
	if [ -z $strTagPrefix ]; then
		cmd="git tag -l"
	else
		cmd="git tag -l \"${strTagPrefix}\""
	fi
		
	$IS_DEBUG && print_info "Command" "$cmd"
	eval $cmd
	print_msg "---------------"
}

function printCurrentRemoteTags() {
	getTagPrefix
	echo "Remote Tags:"
	echo "---------------"
	git ls-remote origin --tags refs/tags/$strTagPrefix* | cut -f 2
	echo "---------------"
}

function printMenuUp() {
	echo -e "Enter "${BRed}${MENU_UP}${Color_Off}" for main menu."
}

function pushTags() {
	#doConfirm "git push --tag" "Push tags to remote?"
	git push --tag
}

function fetchTags() {
	if [ $1 ]; then
		echo "Loading remote tags..."
		git fetch --tags -q
	else 
		doConfirm "git fetch --tags -q" "Fetch tags from remote?"
	fi
}

function getLatestVersion() {
	getTagPrefix true $strGitMaster
	local cmd
	local debug=$IS_DEBUG
	unset strLatestVersion
	#debug=true
	$debug && print_info "Prefix" "$strTagPrefix"
	if [ -z "$strTagPrefix" ]; then	
		#No Prefix for search	
		print_msg "Ooops"
	else		
		cmd="git tag -l \"${strTagPrefix}\""
		arrVersions=$(eval $cmd)
		$debug && echo $arrVersions
		for ver in $arrVersions
		do
			if [ -z $strLatestVersion ]; then
				#Firsh version in list
				strLatestVersion=$ver
			else
				cmd="php -r 'echo version_compare(\"$ver\",\"$strLatestVersion\",\">\");'"
				res=$(eval $cmd)
				$debug && print_info "$ver >? $strLatestVersion" "$res"
				if [ "$res" == "1" ]; then
					$debug && print_info "New version" "$ver"
					strLatestVersion=$ver
				else
					$debug && print_info "New version" "$strLatestVersion"
				fi
				
			fi
		done
	fi
	
	$debug && print_info "Latest version found"  "$strLatestVersion"

	$debug && print_info "Version prefix" "$strVersionPrefix"
	strVerNum=${strLatestVersion##$strVersionPrefix}
	$debug && print_info "Version" "$strVerNum"
	regex="(([0-9]+)\.)+(([0-9]+)\.)+([0-9]+)"
	if [[ $strVerNum =~ $regex ]]; then
		strVerMajor=${BASH_REMATCH[2]}
		strVerMinor=${BASH_REMATCH[4]}
		strVerHotfix=${BASH_REMATCH[5]}
	else
		$debug && echo "Not matched"
	fi
	$debug && print_info "Major" "$strVerMajor"
	$debug && print_info "Minor" "$strVerMinor"
	$debug && print_info "Hotfix" "$strVerHotfix"	
}

function doStartHotfix() {
	local strNewHotfix=$1
	git flow hotfix start "$strNewHotfix"
	echo "Publishing new hotfix to remote..."
	git flow hotfix publish "$strNewHotfix"


}

function doStartRelease() {
	strNewVersion=$1
	git flow release start "$strNewVersion"
	echo "Publishing new release to remote..."
	git flow release publish "$strNewVersion"
}


function doFlowConfig() {
	local boolDoNotCleanInitMessages=$1
	initVars true $boolDoNotCleanInitMessages
	if $boolGitFlow; then
		print_info "Version tag prefix" "Setting  to: $strFlowVersionPrefix"
		git config gitflow.prefix.versiontag $strFlowVersionPrefix
	fi
}

function getParams() {
	ARGV0=$0 # First argument is shell command (as in C)
	echo "Command: $ARGV0"

	ARGC=$#  # Number of args, not counting $0
	echo "Number of args: $ARGC"

	i=1  # Used as argument index
	while [ $i -le $ARGC ]; do # "-le" means "less or equal", see "man test".
		# "${!i} "expands" (resolves) to $1, $2,.. by first expanding i, and
		# using the result (1,2,3..) as a variable which is then expanded.
		echo "Argv[$i] = ${!i}"
		i=$((i+1))
	done
}

function print_msg() {
	if [ -z $2 ]; then
		echo -e ${BIBlue}$1${Color_Off}
	else
		echo -e ${UBlue}$1${Color_Off}
	fi
}

function print_info() {
	echo -e ${Yellow}$1": "${Green}$2${Color_Off}
}

function print_warn() {
	echo -e ${Yellow}$1": "${BBlue}$2${Color_Off}
}
function print_error() {
	echo -e ${Yellow}$1": "${Red}$2${Color_Off}
}

function print_fatal() {
	echo -e ${Red}$1${Color_Off}
}
