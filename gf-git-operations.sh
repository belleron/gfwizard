#!/usr/bin/env bash

# Functions for operations in use at GIT FLOW wizard
# Author: Alex Sherman <alex@belleron.com>
#

function handleMainMenu() {
	if $IS_DEBUG; then
		echo "Handle main menu"
		echo "PARAM1 (option):" $1
		echo "PARAM2 (reply):" $2
	fi
	strOption=$1
	intReply=$2
	
	case $strOption in
		$strOptTest)
			doFindStaleBranches
			exit
			echo "Testing..."
			vvv="v2.00.01"

			#echo "Script folder:" $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
			#echo "Current folder:" $(pwd)
			getLatestVersion
			print_info "Version prefix" "$strVersionPrefix"
			strVerNum=${strLatestVersion##$strVersionPrefix}
			print_info "Version" "$strVerNum"
			regex="(([0-9]+)\.)+(([0-9]+)\.)+([0-9]+)"
			if [[ "$strVerNum" =~ $regex ]]; then
				echo "Match"
			else
				echo "No match"
			fi
			;;

		$strOptFlowInstall)
			echo "On Ubuntu 12.04+ use: apt-get install git-flow"
			echo "On eralier version or if you cannot use apt:"
			echo "1) If this script was installed from Git, use:"
			echo "   $ git submodule update --init --recursive"
			echo "2) Follow instructions from:"
			echo "https://github.com/nvie/gitflow/wiki/Linux"
			;;
		$strOptInit)
			read -p "Remote GIT origin: " strRemoteOrigin
			if [ ! -z "$strRemoteOrigin" ]; then
				git clone --recursive "$strRemoteOrigin" . #note the dot at the end...
			fi
			initVars true
			if $boolGit; then
				initFlow
			fi
			;;
		$strOptInitFlow) 
			initFlow
			;;
		$strOptFlowConfig)
			doFlowConfig
			;;
		$strOptCommit)
			doCommit
			;;
		$strOptListTags)
			fetchTags true
			printCurrentTags
			#printCurrentRemoteTags
			;;
		$strOptPullBranch)
			git pull origin "$strBranch"
			;;
		$strOptPushBranch)
			git push origin "$strBranch"
			pushTags
			;;
		$strOptChangeBranch)
			local intNewFiles=$(git status --porcelain | grep -c ??)
			local intChanges=$(git status --porcelain | grep  -v -c ??)
			if ((0 < $intChanges || 0 < $intNewFiles)); then
				doConfirm "doCommit" "Do you want to commit before branch change?" "There are \033[1;31m$intChanges\033[0m changed files, and \033[1;31m$intNewFiles\033[0m new files."
				pause
			fi
			changeBranch
			;;
		$strOptMergeFromDevelop)
			doConfirm "doMergeDevelop" "Do you want to merge from develop to current branch?"
			;;
		$strOptFeatureStart)
			echo "Enter 0 for cancel."
			read -p "Enter new feature name: feature/" strNewFeature
			if [ $strNewFeature != "0" ]; then
				git flow feature start "$strNewFeature"
				echo "Publishing new feature to remote..."
				git flow feature publish "$strNewFeature"
				#doConfirm "git flow feature publish $strNewFeature" "Publish the new feature to remote origin?"
			fi
			;;
		$strOptFeaturePull)
			git flow feature pull origin
			;;
		$strOptFeatureTag)
			createTag
			;;			
		$strOptFeatureFinish)
			doPreFinishCheck false # without remind to merge from develop since 1.2.9
			if $boolAllowFinish; then
				doConfirm "endFeature" "Finish Feature. Branch will be DELETED and MERGED! Continue?"
			fi
			;;
		$strOptFeatureMerge)
			doPreFinishCheck false
			if $boolAllowFinish; then
				mergeFeature
			fi
			;;
		$strOptFeaturePublish)
			git flow feature publish ${strBranch#"feature/"}
			;;
		$strOptReleaseStart)
			startRelease
			;;
		$strOptReleaseTag)
			createTag
			;;
		$strOptReleaseFinish)
			doPreFinishCheck false
			if $boolAllowFinish; then 
				doConfirm "endRelease" "Finish Release. Branch will be DELETED, MERGED and Tagged! Continue?"
			fi
			;;
		$strOptHotfixStart)
			startHotfix
			;;	
		$strOptHotfixFinish)
			doPreFinishCheck false
			if $boolAllowFinish; then
				git flow hotfix finish -Fp	${strBranch#"hotfix/"}
				if [ $? == 0 ]; then
					git push origin :${strBranch}
				fi
			fi
			;;
		$strOptPhpLintCheck)
			print_info "PHP Lint check" "Starting..."
			gf-php_lint_check.sh
			RETVAL=$?
			if [ $RETVAL -ne 0 ]; then
				print_error "PHP Lint check" "Failed. Errors found"
			else
				print_info "PHP Lint check" "Finished OK."	
			fi
			;;
		$strOptCleanTags)
			cleanVersionTags		
			;;	
		$strOptDoConfig)
		    initVars
		    clear
		    print_msg "Current Settings"
		    showWizardVersion
		    [ -z $strGitLabKey ] && strKeyMsg="${BRed}Not set${Color_Off}" || strKeyMsg="$strGitLabKey" ;
			print_info "GitLab API Key" "$strKeyMsg"
			print_info "Push on commit default" "$strPushOnCommitDefault"
			doConfirm "doConfig" "Do you want to change settings?" "" "N"
			;;
		$strOptDoWizUpdate)
			doConfirm "gf-install.sh" "Run update script?"
			;;
		$strDoHardReset)
			doConfirm "git reset --hard" "Do hard reset?" ${BRed}"This will reset repository to the last commit."${Color_Off} "N"
			;;
		# *******************************************		
		# *************** Default *******************
		# *******************************************		
		*)
			echo "Exit: $intReply"
			if [ $MENU_EXIT == $intReply ]; then
				clear
				if $boolGit; then
					printCurrentBranch
				fi
		   		echo "Have a nice day."
				return 0;
			fi
			;;
    esac
	pause
    doMainMenu
}

function doConfig() {
    initVars
    clear
    print_msg "Change Settings" 
    boolHasChanges=false
    
    # ************************
    # **** GITLAB API KEY ****
    # ************************
	read -p "Enter GitLab API Key [${strGitLabKey}]: " strNewGitLabKey

	if [ "" ==  "${strNewGitLabKey}" ] || [ "${strGitLabKey}" == "${strNewGitLabKey}" ]; then
		print_warn "GitLab API Key" "No change."
	else 
		print_info "GitLab API Key" "${strNewGitLabKey}"
		strGitLabKey="${strNewGitLabKey}"
		boolHasChanges=true
	fi

    # ************************
    # **** PUSH ON COMMIT ****
    # ************************

	read -p "Push on commit default (Y/N) [${strPushOnCommitDefault}]:" strNewPushOnCommitDefault
	if [ "" ==  "${strNewPushOnCommitDefault}" ] || [ "${strNewPushOnCommitDefault}" == "${strPushOnCommitDefault}" ]; then
		print_warn "Push on commit default" "No change."
	else 
		strNewPushOnCommitDefault="${strNewPushOnCommitDefault^^}"

		case $strNewPushOnCommitDefault in
			[YN] )
				print_info "Push on commit default" "${strNewPushOnCommitDefault}"
				strPushOnCommitDefault="${strNewPushOnCommitDefault}"
				boolHasChanges=true
				;;
			* )
				print_error "Push on commit default" "Allowed values only Y/N. (${strNewPushOnCommitDefault})"
				;;
		esac			
	fi	
	
	$boolHasChanges && doConfirm "writeConfig" "Save new settings?" || print_msg "No changes done. Exit."
}

function writeConfig() {
	#Locate to config file folder
	print_info "Config file" $CONFIG_FILE
	echo "#!/usr/bin/env bash" > $CONFIG_FILE
	echo "strGitLabKey=\"${strGitLabKey}\"" >> $CONFIG_FILE
	echo "strPushOnCommitDefault=\"${strPushOnCommitDefault}\"" >> $CONFIG_FILE
	echo "# ************" >> $CONFIG_FILE
	echo "# Static Lines" >> $CONFIG_FILE
	echo "# ************" >> $CONFIG_FILE
	echo "strGFWizardRepo=\"${strGFWizardRepo}\"" >> $CONFIG_FILE
	echo "export GF_GITLAB_DOMAIN=\"${GF_GITLAB_DOMAIN}\"" >> $CONFIG_FILE
	echo "export GF_GITLAB_PROTOCOL=\"${GF_GITLAB_PROTOCOL}\"" >> $CONFIG_FILE
}

function doPreFinishCheck() {
	unset boolAllowFinish
	local intChanges=$(git status --porcelain | grep  -v -c "??")
	if ((0 < $intChanges )); then
		showError "You did not commit all changes. Please commit all before finish!" true
		boolAllowFinish=false
		return
	fi

	local cmd="git log --pretty=format:%H origin/${strBranch}..${strBranch} | grep -c ^"
	local intNotPushed=$(eval $cmd)
	if (( 0 < $intNotPushed )); then
		showError "You did not push all changes. Please push all before finish!" true
		boolAllowFinish=false
		return
	fi

	if $1; then
		doConfirm "doMergeDevelop" "Do you want to merge from develop before finish?"
	fi

	#Do Done/Approved tag check
	# checkDoneTag

	# No errors so far, raise allow finish
	if [ -z $boolAllowFinish ]; then
		boolAllowFinish=true
	fi


}

function checkDoneTag() {
	fetchTags true
	getTagPrefix false
	getLastBuildByTag $strTagPrefix

	local strLastTagApproved=$(git tag -l ${strTagPrefix}${intLastBuild}${strTagSuffixApproved})
	local strLastTagDone=$(git tag -l ${strTagPrefix}${intLastBuild}${strTagSuffixDone})
	if [ ! -z $strLastTagApproved ]; then
		# 'Approved' tag found, get related commit
		local strLastCommitTagged=$(git rev-list ${strTagPrefix}${intLastBuild}${strTagSuffixApproved} | head -n 1)
	elif [ ! -z $strLastTagDone ]; then
		# 'Done' tag found, get related commit
		local strLastCommitTagged=$(git rev-list ${strTagPrefix}${intLastBuild}${strTagSuffixDone} | head -n 1)
	fi

	if [ ! -z $strLastCommitTagged ]; then 
		local strLastCommitHash=$(git log -1 --pretty=%H)
		if [ $strLastCommitHash != $strLastCommitTagged ]; then
			showError "Last commit is not tagged as \"Done\" or \"Approved\"!" true
			boolAllowFinish=false
			doConfirm "createTag" "Cerate Tag now?"
			return
			
		fi	
	else
		showError "No \"Done\" or \"Approved\" tag for last build!" true
		boolAllowFinish=false
		doConfirm "createTag" "Cerate Tag now?"
		return
	fi	
}

function changeBranch() {
    initVars
    clear
	printMenuUp
	printCurrentBranch 
	echo -e "Enter ${BRed}${MENU_REMOTE}${Color_Off} for getting a remote branch."
    echo "Change branch to local: ";

	select branch in $( git for-each-ref  --format='%(refname)' refs\/heads | sed 's/refs\/heads\///' );
	do
		case $REPLY in
			$MENU_UP)
				break;
				;;
			$MENU_REMOTE)
				changeBranchRemote
				;;
			*)
				git checkout "$branch"
				break;
				;;
		esac
	done
	if $IS_DEBUG; then
		pause
	fi
}


function doCommit() {
	echo -e "\nChanges:"
	echo "---------------"
	git status -s
	echo "---------------"
	local intNewFiles=$(git status --porcelain | grep -c ??)
	if ((0 < $intNewFiles)); then
		doConfirm "git add ." "Do you want to add all unstaged files?" "Files not staged: \033[1;31m$intNewFiles\033[0m"
	fi
	local intChanges=$(git status --porcelain | grep  -v -c ??)
	if ((0 < $intChanges)); then
		read -p "Please enter commit message: " strCommitMsg
		git commit -a -m "$strCommitMsg"
		doConfirm "git push origin \"${strBranch}\"" "Push changes to origin?" "" "${strPushOnCommitDefault}"
	else
		echo "Nothing to commit."
	fi
}

function changeBranchRemote() {
    initVars
	git fetch origin
	doConfirm "git pull; pause" "Pull from remote?"
    clear
    printMenuUp
	printCurrentBranch true
	
    echo "Fetch branch from remote: ";

	select branch in $( git ls-remote --heads origin | sed 's/refs\/heads\///' | cut -f2 );
	do
		case $REPLY in
			$MENU_UP)
				break 2;
				;;
			*)
				git checkout -b "$branch" --track "origin/$branch"
				break 2;
				;;
		esac
	done
}

function createTag() {
	fetchTags true
	#Get tag prefix for search
	getTagPrefix true
	printCurrentTags
	getLastBuildByTag $strTagPrefix
	echo "Last build is: ${intLastBuild}"
	#Get plain tag prefix - not for search
	getTagPrefix false
	#Submenu options
	declare -a optionsTags
	case $strCurrentType in
		$strGitFeature)
    		optionsTags[${#optionsTags[*]}]=$strTagOpBuild;
			optionsTags[${#optionsTags[*]}]=$strTagOpDone;
			;;
		$strGitRelease)
    		optionsTags[${#optionsTags[*]}]=$strTagOpBuild;
			optionsTags[${#optionsTags[*]}]=$strTagOpApproved;
			;;
	esac

	printMenuUp
	select opt in "${optionsTags[@]}"; 
	do
		case $opt in
			$strTagOpBuild)
				let "intBuild=$intLastBuild + 1"
				strTag=${strTagPrefix}${intBuild}
				break
				;;
			$strTagOpDone)
				strTag=${strTagPrefix}${intLastBuild}${strTagSuffixDone}
				break
				;;
			$strTagOpApproved)
				strTag=${strTagPrefix}${intLastBuild}${strTagSuffixApproved}
				break
				;;
			*)
				if [ $MENU_UP == $REPLY ]; then
					break
				fi
				;;
		esac
			
	done
	if [ ! -z "$strTag" ]; then
		doConfirm "doTag $strTag" "Apply the Tag?" "New TAG: ${On_Blue}${strTag}${Color_Off}"
	fi
}


function doTag() {
	if [ ! -z "$1" ]; then
		read -p "Enter tag message []: " strTagMessage
		git tag -a $1 -m "$strTagMessage"
		pushTags
	else
		showError "Empty Tag Input Not Allowed"
	fi
	
}

function mergeFeature() {
	strRepoUrl=$(git config remote.origin.url)
	cmd="${GITLAB_EXEC} \"${strGitLabKey}\" \"createMR\" \"${strRepoUrl}\" \"${strBranch}\" \"${strGitDevelop}\" \"Done feature - ${strBranch}\""	
	res=$(eval $cmd)
	if [ $? -eq 0 ]; then
		doConfirm "git checkout ${strGitDevelop} && git branch -d ${strBranch}" "Remove local feature branch?" "Merge Request Created: ${res} from ${strBranch} to ${strGitDevelop}."
	else
		print_error "Merge Request Error" "$res"
	fi
}


function endFeature() {
	local strFeatureBranch=$strBranch
	git flow feature finish -F ${strBranch#"feature/"}
	git checkout develop
	echo "Publishing to remote origin..."
	git push origin develop
	#doConfirm "git push origin :$strFeatureBranch" "Remove remote branch on origin?"
}

function endRelease {
	read -p "Enter Version Tag Message (not the Tag):" strTagMessage
	git flow release finish -m "${strTagMessage}" -Fp	${strBranch#"release/"}
	doConfirm "git checkout ${strGitDevelop}" "Change to DEVELOP?"
}

function doMergeDevelop() {
	git checkout develop
	git pull origin develop
	git checkout $strBranch
	git merge develop
}

function initFlow() {
	git flow init -d
	doFlowConfig
}


function startHotfix() {
	local debug=$IS_DEBUG
	#debug=true

	getLatestVersion
	intVerHotfix=$(echo ${strVerHotfix} | sed 's/^0*//')
	local strNextHotfix=`printf %02d $((intVerHotfix+1))`
	$debug && print_info "Next Hotfix" $strNextHotfix
	local strNewHotfix=$strVerMajor"."$strVerMinor"."$strNextHotfix

	declare -a optionsHotfix
	optionsHotfix[${#optionsHotfix[*]}]=$strHotfixNameAuto;
	#optionsHotfix[${#optionsHotfix[*]}]=$strHotfixNameManual;

	fetchTags true

    clear
    printMenuUp
    printCurrentBranch true true
    print_info "Next hofix (auto)" $strNewHotfix

	select opt in "${optionsHotfix[@]}"; 
	do
		case $opt in
			$strHotfixNameAuto)
				doStartHotfix "$strNewHotfix"
				break
				;;
			$strHotfixNameManual)
				read -p "Hotfix name: " strNewHotfix
				doStartHotfix "$strNewHotfix"
				;;
			*)
				if [ $MENU_UP == $REPLY ]; then
					break
				fi
				;;
		esac
	done
}

function startRelease() {
	local debug=$IS_DEBUG
	#debug=true

	getLatestVersion

	local strNextMajor=$((strVerMajor+1))
	intVerMinor=$(echo ${strVerMinor} | sed 's/^0*//')
	local strNextMinor=`printf %02d $((${intVerMinor}+1))`
	local strNewMinor=$strVerMajor"."$strNextMinor".00"
	local strNewMajor=$strNextMajor".00.00"

	declare -a optionsRelease
	optionsRelease[${#optionsRelease[*]}]=$strReleaseMinorNameAuto;
	optionsRelease[${#optionsRelease[*]}]=$strReleaseMajorNameAuto;
	#optionsRelease[${#optionsRelease[*]}]=$strReleaseNameManual;

	fetchTags true

    clear
    printMenuUp
    printCurrentBranch true true

    print_info "Next minor (auto)" $strNewMinor
    print_info "Next major (auto)" $strNewMajor

	select opt in "${optionsRelease[@]}"; 
	do
		case $opt in
			$strReleaseMinorNameAuto)
				doStartRelease "$strNewMinor"
				break
				;;
			$strReleaseMajorNameAuto)
				doStartRelease "$strNewMajor"
				break
				;;
			$strReleaseNameManual)
				read -p "Enter new version (without prefix): release/" strNewVersion
				doStartRelease "$strNewVersion"
				;;
			*)
				if [ $MENU_UP == $REPLY ]; then
					break
				fi
				;;
		esac
	done
}
