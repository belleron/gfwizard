#!/bin/bash

# Menu Functions of GIT FLOW wizard
# Author: Alex Sherman <alexs@spiralsolutions.com>
#

# Show main menu
function doMainMenu() {
	if ! $IS_DEBUG; then
		clear
	fi
	initVars true
    
	if $IS_DEBUG; then
		echo "boolGit:" $boolGit
	fi
	
	echo -e "Enter "${BRed}${MENU_EXIT}${Color_Off}" for exit."
	
    # define options as array
    declare -a options
    #$IS_DEBUG && 
    #options[${#options[*]}]=$strOptTest;    

	if ! $boolGitFlowInstalled; then
		showError "GitFlow not installed" false
		options[${#options[*]}]=$strOptFlowInstall;
	fi
    # define Menu Items
    if $boolGit; then
		printCurrentBranch true
		# General Git options
		options[${#options[*]}]=$strOptChangeBranch;
		options[${#options[*]}]=$strOptCommit;
		options[${#options[*]}]=$strOptPullBranch;
		options[${#options[*]}]=$strOptPushBranch;
		if $boolGitFlowInstalled; then
			if $boolGitFlow; then 
				case $strCurrentType in
					$strGitFeature)
						#options[${#options[*]}]=$strOptFeaturePull;  		        
						#options[${#options[*]}]=$strOptFeaturePublish;
						options[${#options[*]}]=$strOptFeatureTag;
						options[${#options[*]}]=$strOptFeatureFinish;
						options[${#options[*]}]=$strOptFeatureMerge;
						#options[${#options[*]}]=$strOptFeatureStart;
						options[${#options[*]}]=$strOptMergeFromDevelop;
						;;
					$strGitRelease)
						#options[${#options[*]}]=$strOptReleaseStart;
						#options[${#options[*]}]=$strOptReleasePull;
						#options[${#options[*]}]=$strOptReleasePublish;		        
						options[${#options[*]}]=$strOptReleaseTag;
						options[${#options[*]}]=$strOptReleaseFinish;
						;;
					$strGitDevelop)
						options[${#options[*]}]=$strOptFeatureStart;
						options[${#options[*]}]=$strOptReleaseStart;
						;;
					$strGitMaster)
						options[${#options[*]}]=$strOptHotfixStart;
						;;
					$strGitHotfix)
						options[${#options[*]}]=$strOptHotfixStart;
						options[${#options[*]}]=$strOptHotfixFinish;
						;;
					*)
						echo "Not recognized branch name"
						;;
				esac
			else
				showError "GitFlow not initialized" false
				options[${#options[*]}]=$strOptInitFlow;
			fi
		fi # end of GitFlow present options

		options[${#options[*]}]=$strOptListTags
		options[${#options[*]}]=$strDoHardReset
		options[${#options[*]}]=$strOptFlowConfig
		
		options[${#options[*]}]=$strOptPhpLintCheck;
		options[${#options[*]}]=$strOptCleanTags;
	else
		echo "Not a GIT repository";		
		options[${#options[*]}]=$strOptInit;
	fi

	options[${#options[*]}]=$strOptDoConfig;
	options[${#options[*]}]=$strOptDoWizUpdate;
    
	#handle menu selection
	select opt in "${options[@]}"; 
	do
    	handleMainMenu "$opt" "$REPLY"
	done
}
