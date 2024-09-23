#!/bin/sh

dir=$0
work_dir=${dir%'script.sh'*}
cd $work_dir
work_dir=$(pwd)
echo $work_dir
modelPath=$work_dir"/Resources/ggml-base.bin"
audioPath=$work_dir"/Resources/audioFiles/"
outputPath=$work_dir"/Resources/audioTranscript/"

cd ./copilot
git checkout main
git pull
cd ../
cp ./copilot/InterviewCopilot/ViewModels/LocalTranscriptViewModel.swift ./ScriptTranscript/


#while [ $# -ge 1 ] ; do
#        case "$1" in
#                --audio=*) audioPath=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
#                --output=*) outputPath=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
#                --a=*) audioPath=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
#                --o=*) outputPath=$(echo $1 | awk -F '=' '{print $2}'); shift 1;;
#                *) echo "unknown parameter $1." ; exit 1 ; break;;
#        esac
#done

xcodebuild -scheme ScriptTranscript -configuration Debug -derivedDataPath ./Build
audioFiles=$(ls ./Resources/audio/ | grep '.wav')
for file in $audioFiles
do
  echo $file
  txt=${file%.*}'.txt'
  echo $txt
  ./Build/Build/Products/Debug/ScriptTranscript $modelPath $audioPath$file $outputPath$txt
done

#xcodebuild -scheme ScriptTranscript -configuration Debug -derivedDataPath ./Build

#./Build/Build/Products/Debug/ScriptTranscript $modelPath $audioPath $outputPath

