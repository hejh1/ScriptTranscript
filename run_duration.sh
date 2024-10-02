#!/bin/sh

dir=$0
work_dir=${dir%'script.sh'*}
cd $work_dir
work_dir=$(pwd)
echo $work_dir
modelPath=$work_dir"/Resources/ggml-base.bin"
audioPath=$work_dir"/Resources/audioFiles/"
outputPath=$work_dir"/Resources/audioTranscript/"

 
startTime=`date +%Y%m%d-%H:%M:%S`
startTime_s=`date +%s`

xcodebuild -scheme ScriptTranscript -configuration Debug -derivedDataPath ./Build
audioFiles=$(ls $audioPath | grep '.wav')
file='dialog-000.wav'
txt='dialog-000.txt'
./Build/Build/Products/Debug/ScriptTranscript $modelPath $audioPath$file $outputPath$txt

endTime=`date +%Y%m%d-%H:%M:%S`
endTime_s=`date +%s`
 
sumTime=$[ $endTime_s - $startTime_s ]
echo "$startTime ---> $endTime" "Total:$sumTime seconds"
 
