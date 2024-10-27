#!/bin/sh

dir=$0
language='en'
work_dir=${dir%'ffmpeg_mp3.sh'*}
cd $work_dir
work_dir=$(pwd)
echo $work_dir
audioPath=$work_dir"/Resources/audioFiles/"

pathList=("asian" "asian2" "indian" "indian2" "english" "english2")

for path in "${pathList[@]}"; do
    echo "Path: $path"
    audioPath=$work_dir"/Resources/"$language"/"$path"/Files/"
    echo "$transcriptPath \n"
    audioFiles=$(ls $audioPath | grep '.mp4')
    for file in $audioFiles
    do
      echo $file
      mp3=${file%.*}'.mp3'
      echo $mp3
      ffmpeg -i $audioPath$file -vn -ac 1 -ar 16000 -y $audioPath$mp3
    done
done

