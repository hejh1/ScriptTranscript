# ScriptTranscript

copilot LocalTranscriptViewModel testing script

### Prepare
git submodule update --init --recursive

### Default args
+ Model path: `./Resources/ggml-base.bin`
+ Audio file path: `./Resources/audioFiles/`
+ Subtitle file path: ./Resources/audioSubtitle/`  

Copy model and audio file in `./Resources`. Copy auido files in `./Resources/audioFiles/`

### Run command
```
// output transcript file
./script.sh

// wer rate
python3 calc_wer.py
