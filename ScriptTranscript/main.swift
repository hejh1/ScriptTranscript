//
//  main.swift
//  ScriptTranscript
//
//  Created by jk h on 2024/9/19.
//

import Foundation

//var LocalPath = ""
var AudioFilePath = "/Users/jkh/go/src/script_synco/ScriptTranscript/Resources/output2.wav"
var OutputFilePath = "/Users/jkh/go/src/script_synco/ScriptTranscript/Resources/res.txt"
var WhisperModelPath = "/Users/jkh/go/src/script_synco/ScriptTranscript/Resources/ggml-base.bin"

func setArgs() {
    let arguments = CommandLine.arguments
    
    switch arguments.count {
    case 1:
        print("no args")
    case 2:
        WhisperModelPath = arguments[1]
    case 3:
        WhisperModelPath = arguments[1]
        AudioFilePath = arguments[2]
    case 4:
        WhisperModelPath = arguments[1]
        AudioFilePath = arguments[2]
        OutputFilePath = arguments[3]
    default:
        print("args count not match, count:\(arguments.count)\n")
    }
    print("AudioFilePath: \(AudioFilePath)\n")
    print("OutputFilePath: \(OutputFilePath)\n")
}

func mainRun() throws {
    do {
        var whisperTranscriptionManager: WhisperTranscriptionManager? = nil
        try whisperTranscriptionManager = WhisperTranscriptionManager()
        let transcriptionTimeTracker = TranscriptionTimeTracker()
        let audioProcessor = MicrophoneInputProcessor()
        
        let model = LocalTranscriptViewModel(
            whisperTranscriptionManager: whisperTranscriptionManager!,
            transcriptionTimeTracker: transcriptionTimeTracker,
            microphoneInputProcessor: audioProcessor
        )
        
        let AudioFileURL = URL(fileURLWithPath: AudioFilePath)
        audioProcessor.loadAudioFile(audioPath: AudioFileURL.path())
        
        print("*****length: \(audioProcessor.dataFloats.count)\n")
        
        model.startTranscription()
        
        CFRunLoopRun()
        model.stopTranscription()
        sleep(2)
        print("***********transcript count: \(model.localTranscripts.count)\n")
        
//        let currentPath = FileManager.default.currentDirectoryPath
//        let fileURL = URL(fileURLWithPath: currentPath).appendingPathComponent("res.txt")
        let fileURL = URL(fileURLWithPath: OutputFilePath)
        
        var textVal = ""
        for transcript in model.localTranscripts {
            if let text = transcript.text {
                textVal = textVal+text+"\n"
            }
        }
        do {
            // Write the string to a file
            try textVal.write(to: fileURL, atomically: true, encoding: .utf8)
            print("String successfully written to \(fileURL.path)")
        } catch {
            print("An error occurred while writing to the file: \(error.localizedDescription)")
        }
        
    }
}

print("Script start!\n")
setArgs()
try mainRun()
print("end\n")

