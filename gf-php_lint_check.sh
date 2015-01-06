#!/usr/bin/env bash
script_folder=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $script_folder"/sp-git-functions.sh"

boolResultOk=true

arrDefaultExtensions="php inc module"

verbose=false
dry_run=false
error=false

while :
do
    case $1 in
        -h | --help | -\?)
            # This is not an error, User asked help. Don't do "exit 1"
            usage false
            ;;
        --ext=*)
            ext=${1#*=}
            shift
            ;;
        -v | --verbose)
            verbose=true
            shift
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        --) # End of all options
            shift
            break
            ;;
        -*)
            echo "WARN: Unknown option (ignored): $1" >&2
            shift
            ;;
        *)  # no more options. Stop while loop
            break
            ;;
    esac
done

[ -z "$ext" ] && arrExtensions=$arrDefaultExtensions || arrExtensions=$ext;
$verbose && var_dump arrExtensions;

boolIsFirst=true;
strFindNames="";

for strExt in $arrExtensions
do
	if $boolIsFirst; then
		boolIsFirst=false
	else
		strFindNames=$strFindNames" -o" 
	fi
	strFindNames=$strFindNames" -name '*."$strExt"'"
done

cmd="find ."$strFindNames

arrFiles=$(eval $cmd)

declare -a arrErrors

for strFile in $arrFiles
do
	$verbose && print_info "PHP Lint (syntax) check" $strFile
	php -l $strFile 2>/dev/null > /dev/null
	RETVAL=$?
	if [ $RETVAL -ne 0 ]; then
		boolResultOk=false
		print_error "Check failed in" $strFile
	fi
done
$boolResultOk && exit 0 || exit 128;