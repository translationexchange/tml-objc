#!/bin/zsh

apiRoot="https://staging-api.translationexchange.com/"
apiRootPath="${apiRoot}v1/"
accessToken=""

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
	echo $f
}

processPaths() {
	local p
	local url
	
	for p in $@; do
		if [[ $p == "/" ]]; then
			url="${apiRoot}?access_token=${accessToken}"
		else
			url="${apiRootPath}${p}?access_token=${accessToken}"
		fi
		
		fname=$(fnameForPath "${p}")
		echo "${p} > ${url}"
		fetch "${url}" > ${fname}
		
		if [ -f ${fname} ]; then
			extractPathsFromFile "${fname}" | while read aPath; do
				nextfname=$(fnameForPath "${aPath}")
				echo ">>> NEXT: ${aPath} > ${nextfname}"
				if [ -f ${nextfname} ]; then
					continue
				else
					processPaths "${aPath}"
				fi
			done
		fi
	done
}

browseAPI() {
	prepTempDir
	processPaths "/"
}

main() {
	prepTempDir
	pushd $tempDir
	browseAPI
	popd
}

main
