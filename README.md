# ScriptTranscript

copilot LocalTranscriptViewModel testing script

### Prepare
git submodule update --init --recursive

### Default args
+ Model path: `./Resources/ggml-base.bin`
+ Audio file path: `./Resources/output2.wav`
+ Output file path: `./Resources/res.txt`
Copy model and audio file in `./Resources`. Rename auido file to `output2.wav`

### Run command
```
// default args
./script.sh

// set args
./script.sh --audio=$FULL_PATH_AUDIO
./script.sh --a=$FULL_PATH_AUDIO
./script.sh --audio=$FULL_PATH_AUDIO --output=$FULL_PATH_OUTPUT
./script.sh --a=$FULL_PATH_AUDIO --o=$FULL_PATH_OUTPUT
```
