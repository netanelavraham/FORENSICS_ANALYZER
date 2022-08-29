#!/bin/bash

#This volatility's version which supported in this script
vol_ver="volatility_2.6_lin64_standalone"




#This function makeing sure all necessary tool for script is installed. if no- user can install it trough the script
function INSTALL(){

tools=("wget" "unzip" "bulk-extractor" "foremost" "binwalk" "pv")
for tool in ${tools[@]}; do
	apt list --installed 2>/dev/null | cut -d / -f1 | grep -q ^$tool$ 
	if [ $? -eq 1 ]; then
		echo -e "\e[1;33m[!] it looks like \e[1;34m$tool\e[1;33m is missing on your pc, do you want to install it? [Y/n]\e[1;0m"
		read installchoise
			if [ "$installchoise" != "n" ]; then
				sudo apt-get install $tool 1>/dev/null 2>/dev/null
				if [ $? -eq 0 ]; then
					echo -e "\e[1;34m[✓] $tool\e[1;32m have been successfully installed on your pc\e[1;0m"
					echo ""
				elif [ $? -ne 0 ]; then
					echo -e "\e[1;31[x] Can't install \e[1;33m$tool\e[1;33m! It may be internet connection error.\e[1;0m"
				fi
			else
				echo -e "\e[1;33mOK :(\e[1;0m"
				continue
			fi
	else
		continue
	fi
done
clear
}

#This function validating user's input 
function VALID_INPUT(){
#If terget file type is memory file - validating volatility path or install it if user want 
if [ $foldername == 'mem' ]; then
	#User asked to enter voltility's binary file path in order to use it in script
	echo -e "\e[1;37m[!] Note! This script will only work with volatility 2.6 standalone!\e[1;0m"
	echo -e "\e[1;93m[?] Please enter full path of volatility file or type 'install' to install it:\e[1;0m"
	read vol_path
	if [ "$vol_path" == 'install' ]; then
                        wget http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip 1>/dev/null 2>/dev/null
                        wgetexitcode=$?
			if [[ $wgetexitcode -ne 0 ]]; then
				echo -e "\e[1;31m[x] General Fail with downloading the volatility zip file! Do you want to continue without volatility? \e[1;0m[yes to cuntinue, anything else to exit]:"
				read volafailchoise
				if [ "$volafailchoise" == "yes" ]; then
				echo -e "\e[1;33m[!] Continue without volatility\e[1;0m"
				else
					exit
				fi
			fi
			unzip $vol_ver.zip
			rm $vol_ver.zip
              		vol_path=./$vol_ver/$vol_ver
			clear
	else
		while !( test -e $vol_path ) || [ -z $vol_path ] || [ $vol_path == 'install' ]; do 
			echo -e "\e[1;37m[!] Note! This script will only work with volatility3 v1.0.0 python rewrite!\e[1;0m"
			echo -e "\e[1;93m[?] Please enter full path of volatility file or type 'install' to install it:\e[1;0m"
			read vol_path
			if [ "$vol_path" == 'install' ]; then
                        wget http://downloads.volatilityfoundation.org/releases/2.6/volatility_2.6_lin64_standalone.zip 1>/dev/null 2>/dev/null
                        wgetexitcode=$?
                        if [[ $wgetexitcode -ne 0 ]]; then
                                echo -e "\e[1;31m[x] General Fail with downloading the volatility zip file! Do you want to continue without volatility? \e[1;0m ['yes' to continue, anything else to exit]"
                                read volafailchoise
                                if [ "$volafailchoise" == "yes" ]; then
                                echo -e "\e[1;33mContinue without volatility\e[1;0m"
                                else
                                        exit
                                fi
                        fi
                        unzip $vol_ver.zip
                        rm $vol_ver.zip
                        vol_path=./$vol_ver/$vol_ver
                        clear
			break
			fi
		done
	echo ""
	fi
volfullpath=$(readlink -f $vol_path)
fi


#If the directory name (mem/hdd) is already existed, user asked to delete it to prevent overwrite 
if test -e "$foldername"; then
	echo -e "\e[1;33m[!] Directory\e[1;0m \e[33m'$foldername' \e[1;33mis already existed! Do you want to delete it? [enter 'yes' to delete | anything else to exit]: \e[1;0m" 
	read del_choise
	if [ "$del_choise" == "yes" ]; then
		rm -rf "$foldername"
		echo -e "\e[1;33m[-] Folder\e[1;0m \e[33m'$foldername'\e[1;0m \e[1;33mdeleted!\e[1;0m"
		sleep 1
		clear
	elif [ "$del_choise" != "yes" ]; then
		exit
	fi
fi
}

#This function incloude common commands for both HDD and MEMORY files
#It made to save coding lines and make changes become more easier and comfort
function COMMONCOMMANDS(){
mkdir $foldername
cd $foldername

echo -e "\e[1;32m[+] Folder\e[1;0m \e[32m'$foldername'\e[1;0m \e[1;32mcreated!\e[1;0m"

echo -e "\e[1;32m[!] Processing the file\e[1;0m \e[32m$filename\e[1;0m"

echo -e "\e[1;34m	[!] Searching for readable\e[1;0m \e[34mSTRINGS\e[1;0m \e[1;34min target file \e[1;0m"
	strings $filename > strings_output
echo -e "\e[1;34m	[!]\e[1;0m \e[34mBINWALK\e[1;0m \e[1;34mon target file \e[1;0m"
	binwalk $filename -q -f ./binwalk_output
echo -e "\e[1;34m	[!]\e[1;0m \e[34mFOREMOST\e[1;0m \e[1;34mon target file \e[1;0m"
	foremost -Q $filename -o ./foremost_output 1,2>/dev/null
echo -e "\e[1;34m	[!]\e[1;0m \e[34mBULK_EXTRACTOR\e[1;0m \e[1;34mon target file \e[1;0m"
	bulk_extractor $filename -o bulk_output 1,2>/dev/null

}


#This function will be used in case user choised target file as memory dump
function MEM(){
COMMONCOMMANDS #Executing the function 'COMMONCOMMAND' which incloude relevent commands for both functions [MEM\HDD]
volcommands=("imageinfo" "pslist" "sockets" "connscan") #Here, user can change values to change the plugins will be used in volatility command
if [ "$volafailchoise" == "yes" ]; then
	echo -e "\e[1;33m   [-] Skipping Volatility (user choised) \e[1;0m"
else
	echo -e "\e[1;34m	[!]\e[1;0m \e[34mVolatility\e[1;0m \e[1;34mon target file \e[1;0m"
	for command in ${volcommands[@]}; do
		echo -e "\e[1m		    --$command\e[1;0m"
		echo "				$command:				" >> ./volatility_output
		echo "__________________________________________________________________" >> ./volatility_output
		echo "" >> ./volatility_output
		$volfullpath $command -f $filename >> ./volatility_output 2>/dev/null
		echo "" >> ./volatility_output
		echo "" >> ./volatility_output
		echo "__________________________________________________________________" >> ./volatility_output
		#if exitcode is error, user notified
		volexitcode=$?
		[ $volexitcode -ne 0 ] && echo -e "\e[1;31m[x] Volatility Fail! \e[1;93mIt may because you didn't entered full path of volatility or you have no internet\e[1;0m"
	done
fi
}





#This function will be used in case user choised target file as HDD dump
function HDD(){
COMMONCOMMANDS
}



#This function will be used at finishing of the functions MEM/HDD to display general analysis
function LOG(){
clear
for second in {5..1..-1}
do
	echo -e "\e[1;32m[✓] Action done! showing results in $second seconds \e[1;0m"
	sleep 1
	clear
done
echo -e "\e[1;35m $filename analysis: \e[1;0m"
echo "___________________________________________________"
echo ""
echo -e "\e[1;36m./$foldername/strings_output: \e[1;0m"
	echo -e "\e[32m$(cat strings_output | wc -l) \e[1;0m readable strings found"
	printf "\n \n"
echo -e "\e[1;36m./$foldername/binwalk_output: \e[1;0m"
	echo -e "\e[32m$(($(cat binwalk_output | wc -l)-2)) files \e[1;0m found with binwalk"
	printf "\n \n"
echo -e "\e[1;36m./$foldername/foremost_output: \e[1;0m"
	echo "$(cat foremost_output/audit.txt | grep 'FILES EXTRACTED' -A 5000)" 
	printf "\n \n"
echo -e "\e[1;36m./$foldername/bulk_output: \e[1;0m"
	echo -e "\e[32mFiles can be found in the folder\e[1;0m"
	printf "\n \n"
if [ "$foldername" == "mem" ]; then
	if [ -z $volexitcode ] || [ $volexitcode -ne 0 ]; then
		echo -e "\e[1;36m./$foldername/volatility_output: \e[1;0m"
		echo -e "\e[33mNo output from Volatility (SKIPPED) \e[1;0m"
	elif  [[ $volexitcode -eq 0 ]]; then
		echo -e "\e[1;36m./$foldername/volatility_output: \e[1;0m"
		cat volatility_output
	fi
fi
printf "__________________________________________________________________ \n \n"
apt list --installed 2>/dev/null | cut -d / -f1 | grep -q ^pv$
if [ $? -eq 0 ]; then
	echo -e "\e[1;32m[!] You can find all files in\e[1;0m \e[32m$(pwd)\e[1;0m" | pv -qL 15
else
	echo -e "\e[1;32m[!] You can find all files in\e[1;0m \e[32m$(pwd)\e[1;0m"
fi
printf "__________________________________________________________________ \n \n"


echo -e "\e[1;32mDo you want to open directory with FileExplorer? ['yes' to open | anything else to finish]: \e[1;0m"
read openchoise
if [ "$openchoise" == "yes" ]; then
	xdg-open ../$foldername
	if [ $? -ne 0 ]; then
		echo -e "\e[1;31mError! Can't open $(pwd) in GUI. 'xdg-open' may not installed\e[1;0m"
	fi
fi
printf "_____________________________________________________________________\n"

}



#If user did not enter target filetype / path, he will be asked to enter it
if [ -z $2 ]; then
	echo -e "\e[1;31m[!] You must specify file's type and filename!\e[1;0m"
	exit 
fi

filename=$(readlink -f $2)

#If user enter invalid file's path, he will be notified and quitting the script
if !( test -f "$filename" ); then
	echo -e "\e[1;31m[!] The file not existed!\e[1;0m"
	exit
fi


if [ "$1" == mem ]; then
	foldername='mem' #defining output foldername
	VALID_INPUT  #executing the function 'VALID_INPUT' to make sure user enter valid input (filname, option etc.)
	vol_path=$(readlink -f $vol_path)
	INSTALL #executing the function 'Install' which checks (and install) required tools for script
	MEM  #executing the function 'MEM' which incloude all relevent commands to perform on target file
	LOG  #executing the function 'LOG' which will display general analysis to the user
elif [ "$1" == hdd ]; then
	foldername='hdd'  #defining output foldername
	VALID_INPUT #executing the function 'VALID_INPUT' to make sure user enter valid input (filname, option etc.)
	INSTALL #executing the function 'VALID_INPUT' to make sure user enter valid input (filname, option etc.)
	HDD  #executing the function 'MEM' which incloude all relevent commands to perform on target file
	LOG  #executing the function 'LOG' which will display general analysis to the user
else 
	echo -e "\e[1;31m[x] Please try again with valid option [mem/hdd]\e[1;0m"; exit
fi
