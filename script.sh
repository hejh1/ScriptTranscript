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

xcodebuild -scheme ScriptTranscript -configuration Debug -derivedDataPath ./Build
audioFiles=$(ls ./Resources/audio/ | grep '.wav')
for file in $audioFiles
do
  echo $file
  txt=${file%.*}'.txt'
  echo $txt
  ./Build/Build/Products/Debug/ScriptTranscript $modelPath $audioPath$file $outputPath$txt
done

