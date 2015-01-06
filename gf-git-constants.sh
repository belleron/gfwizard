#!/usr/bin/env bash

# Constants for use in GIT FLOW wizard
# Author: Alex Sherman <alex@belleron.com>
#
# Menu related
readonly MENU_EXIT=0
readonly MENU_UP=0
readonly MENU_REMOTE=99

readonly CONFIG_FILE="$( dirname "${BASH_SOURCE[0]}" )""/.gfconfig"
readonly GITLAB_EXEC="$( dirname "${BASH_SOURCE[0]}" )""/gf-gitlab.php"

#Regex for valid tags
readonly strTagRegex="^feature\|hotfix\|release\|v[0-9]\{1,2\}\.[0-9]\+\.[0-9]\+$"

# Menu Items Constants Definitions
readonly strOptTest="test"

readonly strOptFlowInstall="How-To Install GitFlow"
readonly strOptChangeBranch="Change working branch"
readonly strOptChangeRemoteBranch="*** Remote ***"
readonly strOptInit="Init"
readonly strOptInitFlow="GitFlow Init"
readonly strOptPullBranch="Pull branch"
readonly strOptPushBranch="Push branch"
readonly strOptPull="Pull"
readonly strOptPush="Push"
readonly strOptCommit="Commit"
readonly strOptListTags="List Tags"
readonly strOptMergeFromDevelop="Merge from develop"
readonly strOptFlowConfig="Configure GitFlow"
readonly strOptPhpLintCheck="Run PHP Lint Syntax Check"
readonly strOptCleanTags="Clean version tags"
readonly strOptDoConfig="Settings"
readonly strOptDoWizUpdate="Run wizard update"
readonly strDoHardReset="Do hard reset"



readonly strOptFeatureStart="Start Feature"
readonly strOptFeaturePublish="Publish Feature"
readonly strOptFeaturePull="Pull Feature"
readonly strOptFeatureFinish="Finish (Merge) Feature"
readonly strOptFeatureTag="Tag Feature"
readonly strOptFeatureMerge="Done. Create Merge Request"

readonly strOptReleaseStart="Start Release"
readonly strOptReleasePublish="Publish Release"
readonly strOptReleasePull="Pull Release"
readonly strOptReleaseFinish="Finish Release"
readonly strOptReleaseTag="Tag Release"

readonly strOptHotfixStart="Start Hotfix"
readonly strOptHotfixPublish="Publish Hotfix"
readonly strOptHotfixPull="Pull Hotfix"
readonly strOptHotfixFinish="Finish Hotfix"


readonly strGitFeature="feature"
readonly strGitRelease="release"
readonly strGitDevelop="develop"
readonly strGitMaster="master"
readonly strGitHotfix="hotfix"


readonly strTagOpBuild="Build"
readonly strTagOpDone="Done"
readonly strTagOpApproved="Approved"

readonly strTagSuffixDone=".done"
readonly strTagSuffixApproved=".approved"

readonly strFlowVersionPrefix="v"

readonly strHotfixNameAuto="Auto Hotfix Name"
readonly strHotfixNameManual="Custom Hotfix Name"

readonly strReleaseMinorNameAuto="Auto Minor Release"
readonly strReleaseMajorNameAuto="Auto Major Release"
readonly strReleaseNameManual="Custom Release"


