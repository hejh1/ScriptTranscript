# ScriptTranscript

copilot LocalTranscriptViewModel testing script

### Prepare
git submodule update --init --recursive

### Default args
+ Model path: `./Resources/ggml-base.bin`
+ Audio file path: `./Resources/audioFiles/`
+ Subtitle file path: `./Resources/audioSubtitle/`  

Copy model and audio file in `./Resources`. Copy auido files in `./Resources/audioFiles/`

### Run command
```
// output transcript file
// --a and --accent transcript accent audio files
// --l abd --language set language, default is 'auto'
./script.sh
./script.sh --a=true --l=en

// install requirment
pip3 install jiwer
pip3 install html-table

// wer rate
python3 calc_wer.py
python3 calc_wer.py accent
