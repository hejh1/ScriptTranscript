#!/bin/sh

dir=$0
work_dir=${dir%'script.sh'*}
cd $work_dir
work_dir=$(pwd)
echo $work_dir
#modelPath=$work_dir"/Resources/ggml-base.bin"
modelPath=$work_dir"/Resources/ggml-large-v3-q5_0.bin"
audioPath=$work_dir"/Resources/audioFiles/"
outputPath=$work_dir"/Resources/audioTranscript/"
language='en'
accent='false'
gpu='true'

pathList=("asian" "asian2" "indian" "indian2" "english" "english2")

while [ $# -ge 1 ] ; do
        case "$1" in
                --language=*) language=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
                --accent=*) accent=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
                --gpu=*) gpu=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
                --l=*) language=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
                --a=*) accent=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
                --g=*) gpu=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
                *) echo "unknown parameter $1." ; exit 1 ; break;;
        esac
done

cd ./copilot
git checkout main
#git pull
cd ../
cp ./copilot/InterviewCopilot/ViewModels/LocalTranscriptViewModel.swift ./ScriptTranscript/

xcodebuild -scheme ScriptTranscript -configuration Debug -derivedDataPath ./Build
for path in "${pathList[@]}"; do
    echo "Path: $path"
    audioPath=$work_dir"/Resources/"$language"/"$path"/Files/"
    #audioPath=$work_dir"/Resources/"$language"/"$path"/f2/"
    transcriptPath=$work_dir"/Resources/"$language"/"$path"/Transcript-large-v3-q5_0/"
    echo "$transcriptPath \n"
    audioFiles=$(ls $audioPath | grep '.wav')
    for file in $audioFiles
    do
      echo $file
      txt=${file%.*}'.txt'
      echo $txt
      ./Build/Build/Products/Debug/ScriptTranscript $modelPath $audioPath$file $transcriptPath$txt auto $gpu
    done
done

