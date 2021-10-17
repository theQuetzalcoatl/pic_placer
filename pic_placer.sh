#!/usr/bin/env bash

string_date_to_numerical()
{
	case "$1" in
		"jan")
			return 1;;
		"febr")
			return 2;;
		"mar"|"márc")
			return 3;;
		"apr"|"ápr")
			return 4;;
		"may"|"máj")
			return 5;;
		"june"|"jún")
			return 6;;
		"july"|"júl")
			return 7;;
		"aug")
			return 8;;
		"sept"|"szept")
			return 9;;
		"oct"|"okt")
			return 10;;
		"nov")
			return 11;;
		"dec")
			return 12;;
		*)
			return 13;;
	esac
}

# input argument checking
starting_dir=""
if [ $# -eq 1 ]; then
	starting_dir=$(realpath --quiet $1); # to expand if received a dot
elif [ $# -eq 0 ]; then
	starting_dir=$HOME;
else
	echo -e "Wrong number of arguments supplied.\nUsage: <script_name> <starting folder>(optional)"
	exit 1
fi

# check if given path exists and is a directory
if [ -d "$starting_dir" ]; then
	: # do nothing
else
	echo "\"$starting_dir\" is not a directory."; exit 1;
fi

# deleting all the folders which this script may have created before. All the folders under Pictures which are similar to <year>-<month>
IFS=$'\n'; # changing the internal field seprator from '<space>\t\n' to only '\n' to catch the outputs from now on as lines
for folder in $(ls "$HOME/Pictures"); do
	if [ -d "$HOME/Pictures/$folder" ]; then # 
		if grep -q -P "\d{4}-\d\d?" <<< "$folder"; then mv "$HOME/Pictures/$folder" ~/.local/share/Trash/files/; fi 
	fi
done

# getting all the images
picture_path=();

for path in $(locate *.jpg *.png *.jpeg *.tiff *.bmp | grep -P ".*$starting_dir.*"); do
	if grep -q -P ".*\/\..*" <<< "$path" || grep -q -P "$HOME/Pictures" <<< "$path"; then # ignoring dot files and directories. also the Pictures folder
		continue;
	else
		picture_path=("${picture_path[@]}" "$path")
	fi
done

current_year=$(date +"%Y")

# getting the oldest *modified* image regarding the year
latest_year=$current_year
for picture in ${picture_path[@]}; do
	picture_year=$(ls -l $picture | grep -P -o "  2\d\d\d " | cut -d " " -f 3)
	if [ -z $picture_year ]; then :; # in case we did not find any year, which happens if the modification was carried out this year
	elif [ $picture_year -lt $latest_year ]; then latest_year=$picture_year; fi
done

eval mkdir --parents /home/$USER/Pictures/{$latest_year..$current_year}-{1..12} # eval is needed because brace expension would not work on variables

# placing the pictures into the relevant folders by their dates
for picture in ${picture_path[@]}; do
	picture_year=$(ls -l $picture | grep -P -o "  2\d\d\d " | cut -d " " -f 3)
	if [ -z $picture_year ]; then picture_year=$current_year; fi # if picture is a couple of month old, ls wont show the year, so it is fixed here
	string_date_to_numerical $(ls -l $picture | grep -P -o " (jan|febr|márc|mar|apr|ápr|may|máj|june|jún|july|júl|aug|sept|szept|oct|okt|nov|dec) " | cut -d " " -f 2)
	picture_month=$?
	if [ 13 -eq $? ]; then echo "Non valid month of \"$picture\" was found/calculated."; continue; fi
  cp $picture $HOME/Pictures/$picture_year-$picture_month &
done

