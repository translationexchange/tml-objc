#!/bin/zsh

apiRoot="https://api.translationexchange.com/"
apiRootPath="${apiRoot}v1/"
accessToken=""
browseMode=0
typeset -a apiPaths
typeset -A apiParams

typeset -a paths
tmpDir="/tmp/tml-api-tests"

if [ -f ~/.tmlconfig ]; then
	source ~/.tmlconfig
fi

fetch() {
	local url
	url=$1
	local cookiesFile
	cookiesFile=~/.curlcookies
	if [ ! -f $cookiesFile ]; then
		touch $cookiesFile
	fi
	curl -L -m 15 -b $cookiesFile -c $cookiesFile -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_1) AppleWebKit/601.2.7 (KHTML, like Gecko) Version/9.0.1 Safari/601.2.7" "${url}" 2>/dev/null
}

prepTempDir() {
	if [ -d ${tmpDir} ]; then
		rm -rf ${tmpDir}
	fi
	mkdir ${tmpDir}
}

extractPathsFromFile() {
	local fname
	fname=$1
	
	cat "${fname}" | gsed -r "s/([,\}\{])/\1\n/g" | grep "${apiRootPath}" | gsed -r "s/^.*${apiRootPath:gs/\//\\\/}([^\?\"]+).*$/\1/" | uniq
}

fnameForPath() {
	local p
	local f
	p=$1
	f="${tmpDir}/${p:gs/\//_}"
	f=$(echo "${f}" | gsed -r "s/[0-9]+/_/g")
	echo "${f}.json"
}

processPaths() {
	local p
	local url
	
	for p in $@; do
		if [[ $p == "/" ]]; then
			url="${apiRoot}"
		else
			url="${apiRootPath}${p}"
		fi
		
		url="${url}?access_token=${accessToken}"
		for k in ${(k)apiParams}; do
			url="${url}&${k}=${apiParams[$k]}"
		done
		
		fname=$(fnameForPath "${p}")
		if [[ $browseMode -eq 0 ]]; then
			echo "${url}"
			fetch "${url}" | python -m json.tool
		else
			echo "${p}"
			fetch "${url}" | python -m json.tool > ${fname}
			if [ -f ${fname} ]; then
				extractPathsFromFile "${fname}" | while read aPath; do
					nextfname=$(fnameForPath "${aPath}")
					if [ -f ${nextfname} ]; then
						continue
					else
						processPaths "${aPath}"
					fi
				done
			fi
		fi
	done
}

main() {
	prepTempDir
	pushd $tempDir
	if [[ $browseMode -eq 0 ]]; then
		processPaths ${apiPaths[@]}
	else
		processPaths "/"
	fi
	popd
}

while getopts hbk:p: opt; do
	case $opt in
		h)  echo "Usage: `basename $0` [OPTIONS] [API_PATH..]"
			echo "   Performs a call to each API_PATH specified, or browses entire API if -b is given."
			echo "   OPTIONS:"
			echo "     -k=ACCESS_TOKEN Use specified access token. You can also shove 'accessToken='<ACCESS_TOKEN>' into ~/.tmlconfig"
			echo "     -b Browse API. All API paths given on command line will be ignored."
			echo "     -p REQUEST_PARAM=REQUEST_VALUE  Add additional request parameters"
			echo
				return 1
				;;
		b) browseMode=1 ;;
		k) accessToken=$OPTARG ;;
		p) typeset -a kv
		   kv=(${(s:=:)OPTARG:gs/-p /})
		   apiParams[${kv[1]}]=${kv[2]}
		   ;;
	esac
done

for ((i=1;i<$OPTIND;i++)); do
	shift
done

apiPaths=($@)

main
