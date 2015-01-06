#!/usr/bin/env php
<?php
require_once realpath ( __DIR__ . '/gitlab/vendor/autoload.php' );
if (count($argv) < 2 || $argv[1]=='-h' ) {
	echo "Usage: gf-gitlab.php <token> <command>".PHP_EOL;
	exit(1);
} else {
	$strToken = $argv[1];
	$strCommand = $argv[2];
	$strDomain = getenv('GF_GITLAB_DOMAIN');
	$strProtocol = getenv('GF_GITLAB_PROTOCOL');

	$objGitLab = new \Gitlab\Client ( $strProtocol.'://'.$strDomain.'/api/v3/' );
	$objGitLab->authenticate ( $strToken, \Gitlab\Client::AUTH_URL_TOKEN );

	switch ($strCommand) {
		case "createMR":
			if (count($argv) < 7) {
				echo "Command Usage: createMR <repoURL> <srcBranch> <trgtBranch> <title>".PHP_EOL;
				exit(1);
			}
			$strRepoUrl=$argv[3];
			$strSrcBranch=$argv[4];
			$strTargetBranch=$argv[5];
			$strMergeTitle=$argv[6];

			$intPrjId=0;
			if (preg_match('%.*'.strtr($strDomain, '.', '\.').'[:/]{1}(.*)\.git%im', $strRepoUrl, $regs)) {
				$strPrjId = $regs[1];
			} else {
				$strPrjId = "";
			}
			if ($strPrjId) {
				//Found Namespace/Project
				$arrOpenMrs=$objGitLab->api('mr')->opened($strPrjId);
				if (!empty($arrOpenMrs)) {
					foreach ($arrOpenMrs as $arrMr) {
						if ($arrMr['source_branch'] == $strSrcBranch && $arrMr['target_branch'] == $strTargetBranch) {
							//Merge request already exists
							echo "Merge request from \"$strSrcBranch\" to \"$strTargetBranch\" already exists";
							exit(1);
							break;
						}
					}
				}
				$arrNewMr=$arrOpenMrs=$objGitLab->api('mr')->create($strPrjId, $strSrcBranch, $strTargetBranch, $strMergeTitle);
				echo $arrNewMr['iid'];
				exit(0);
			} else {
				echo "Project not found in GitLab";
				exit(1);
			}
		default:
			echo "Unrecognized command";
			exit(1);
	}
}
exit(0);
