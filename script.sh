#!/bin/sh

dir=$0
work_dir=${dir%'script.sh'*}
cd $work_dir
work_dir=$(pwd)
echo $work_dir
modelPath=$work_dir"/Resources/ggml-base.bin"
audioPath=$work_dir"/Resources/audioFiles/"
outputPath=$work_dir"/Resources/audioTranscript/"
language='auto'
accent='false'
gpu='true'

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

if [ $accent == 'true' ]
then
  audioPath=$work_dir"/Resources/accentAudioFiles/"
  outputPath=$work_dir"/Resources/accentAudioTranscript/"
fi

cd ./copilot
git checkout main
git pull
cd ../
cp ./copilot/InterviewCopilot/ViewModels/LocalTranscriptViewModel.swift ./ScriptTranscript/

xcodebuild -scheme ScriptTranscript -configuration Debug -derivedDataPath ./Build
audioFiles=$(ls $audioPath | grep '.wav')
for file in $audioFiles
do
  echo $file
  txt=${file%.*}'.txt'
  echo $txt
  ./Build/Build/Products/Debug/ScriptTranscript $modelPath $audioPath$file $outputPath$txt $language $gpu
done

