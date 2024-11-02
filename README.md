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
pip3 install PrettyTable

// wer rate
python3 calc_wer.py
python3 calc_wer.py accent

### DiffViewer http server install and run
```
// Install http-server
npm install -g http-server

// Run http server
http-server
```
+ Open `localhost:8080/jiwer.html` in browser
+ Press `diffview` button and refresh to web `localhost:8080/index.html`
+ Press `Dispaly diff` button on web `localhost:8080/index.html`

### Update jiwer.html
```
python3 calc.py
```
