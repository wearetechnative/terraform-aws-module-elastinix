#!/usr/bin/env bash
# Version: 202507311

curdir=$(basename ${PWD})
projectdir=$(dirname ${PWD})
projectname=$(basename ${projectdir})
localdatadir="${projectdir}/local_data"
keyfile="${localdatadir}/${projectname}-key"


function check_prerequisites(){
	echo "check_prereq"
	if [[ ! ${curdir} == "scripts" ]]; then
		echo "!! Please run this scripts from location <project_dir>/scripts"
		exit 1
	fi

	if [[ ! -d ${localdatadir} ]]; 
	then
		echo "-- Local data folder (${localdatadir}) does not exist. Creating it"
		mkdir ${localdatadir} 
	fi
	echo -e "Current AWS_PROFILE: \e[1m\e[31m${AWS_PROFILE}.\e[0m"
	echo "!! Check before you continue !!"
	gum confirm || exit
}


function check_key(){
	echo "check_key"
	parameter_name="/key_pair/${projectname}-key"
	aws_output=$(aws ssm get-parameter --name "$parameter_name" 2>&1)
	if [[ "$aws_output" != *"ParameterNotFound"* ]]; then
		key_name=$(basename $(jq -r '.Parameter.Name' <<< "$aws_output"))
		echo -e "Key found in AWS Parameter Store: \e[1m\e[32m${key_name}\e[0m"
		return 0
	else
		return 1
	fi
}


function set_download_location(){
	echo "set download_location"
	download_location=$(gum input --placeholder "Enter target location:" --value "${HOME}/.ssh/" --header "Enter directory to save key:" )
	if [[ ! -d ${download_location} ]]; then mkdir -p "$download_location"; chmod 0700 ${download_location};fi
	permissions=$(stat -c "%a" "$download_location")
	if [ "$permissions" -ne 700 ]; then
		echo "De directory $directory_path heeft NIET de rechten 0700. Huidige rechten: $permissions"
	fi
}

function download_key(){
  echo "If you want to use the ssh-key, you have to save it on your local machine. For example in ~/.ssh"
	gum confirm "Do you want to save the key on your local machine?" && download_choice="yes"
	if [[ "$download_choice" == "yes" ]]; then
		set_download_location
		aws ssm get-parameter --name "$parameter_name" --with-decryption --query 'Parameter.Value' --output text > "$download_location/${projectname}-key"
		chmod 600  $download_location/${projectname}-key
		echo "SSH Private key saved to $download_location/${projectname}-key"
	else
		echo "Download skipped."
	fi
}



function generate_key(){
	if [[ ! -f ${keyfile} ]];
	then
		echo -e "Generating key $(basename ${keyfile})"
		ssh-keygen -t ed25519 -f ${keyfile} -N "" -C "" >/dev/null
		upload_key
		download_key

	else 
		echo "!!! SSH-key already exists in this project"
    upload_key
    download_key
	fi
}

function upload_key(){
	echo "upload_key"
	if gum confirm "Uploading keys to AWS Parameter Store?"; then
		echo "Uploading to AWS Parameter Store"
		aws ssm put-parameter \
			--name "/key_pair/${projectname}-key" \
			--value "file://${keyfile}" \
			--type "SecureString" \
			--overwrite > /dev/null

  if [[ $? -ne 0 ]]; then echo "!! Error uploading key. Exiting"; fi

		aws ssm put-parameter \
			--name "/key_pair/${projectname}-key.pub" \
			--value "file://${keyfile}.pub" \
			--type "String" \
			--overwrite > /dev/null

  if [[ $? -ne 0 ]]; then echo "!! Error uploading key. Exiting"; fi


	else
		echo "Not uploading"

	fi

}


##
echo start
check_prerequisites
if check_key ; then  download_key; else generate_key; fi
