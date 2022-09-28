#!/bin/bash

title="
\n#################################################################
\n#
\n# Barotrauma file copy helper.
\n#
\n# - About: should aid in the downloading of LocalMod files.
\n#
\n#################################################################
"

main (){
	echo "${title}"

	local modsdirectory='/home/steam/Steam/steamapps/common/Barotrauma Dedicated Server/LocalMods'
	local modsdirectory='/home/steam/Steam/steamapps/common/Barotrauma Dedicated Server/Daedalic Entertainment GmbH/Barotrauma/Multiplayer'
	local currentdirectory="$(pwd)"

	echo "Directories:"
	echo "- Source:      ${modsdirectory}"
	echo "- Destination: ${currentdirectory}"

	readarray -t moddirectories < <(find "$modsdirectory" -maxdepth 1 | xargs -i basename {} | sort)

	echo
	echo
	echo
	for index in "${!moddirectories[@]}"; do
		echo "${index}) ${moddirectories[$index]}"
	done
	echo "q) Quit"
	echo
	read -p "Make your selection: " selection

	echo
	local moddirectory="${moddirectories[$selection]}"
	inputhandler "${selection}" "${moddirectory}"

	echo 
	local destination="$currentdirectory/$moddirectory.zip"
	echo "You will need this path to get the copy out of GCP: ${destination}"
}


inputhandler() {
	local selection="$1"
	local moddirectoru="$2"

	if [[ "$selection" == 'q' ]]; then
		echo "Fine, be like that. 🧐"
		exit 0

	elif [[ ! -z "${moddirectory}" ]]; then
		echo "Cool, '${moddirectory}' works."
		zipfile "${moddirectory}"
		# copyfile "${moddirectory}"
		# modperms "${moddirectory}"

	else
		echo "Invalid option. 🙅"
		exit 1

	fi

	echo
	echo "Done"
}


zipfile() {
	local moddirectory="$1"
	local source="$modsdirectory/$moddirectory"
	local destination="$currentdirectory/$moddirectory.zip"
	echo
	echo "Zipping:"
	echo "- Source: $destination"
	echo "- Destination: $source"
	echo
	zip -r "$destination" "$source"
}

copyfile() {
	local moddirectory="$1"
	local source="$modsdirectory/$moddirectory"
	local destination="$currentdirectory/$moddirectory"
	echo
	echo "Copying:"
	echo "- Source: ${source}"
	echo "- Desitnation: ${destination}"	
	cp "${source}" "${destination}"
}


modperms() {
	local moddirectory="$1"
	local destination="$currentdirectory/$moddirectory.zip"
	echo
	echo "Changing zip file owner to ${USER}:${USER}'"
	chmod ${USER}:${USER} "${destination}"
}


main
