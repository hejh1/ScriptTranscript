//
//  main.swift
//  ScriptTranscript
//
//  Created by jk h on 2024/9/19.
//

import Foundation

let LocalPath = "/Users/jkh/go/src/script_synco/run"
let WhisperModelName = "ggml-base.bin"
let AudioFileName = "output2.wav"
let OutputFileName = "res.txt"

func mainRun() throws {
    do {
        var whisperTranscriptionManager: WhisperTranscriptionManager? = nil
        try whisperTranscriptionManager = WhisperTranscriptionManager()
        let transcriptionTimeTracker = TranscriptionTimeTracker()
        
        let model = LocalTranscriptViewModel(
            whisperTranscriptionManager: whisperTranscriptionManager!,
            transcriptionTimeTracker: transcriptionTimeTracker
        )
        
        let AudioFileURL = URL(fileURLWithPath: LocalPath).appendingPathComponent(AudioFileName)
        model.microphoneProcessor.loadAudioFile(audioPath: AudioFileURL.path())
        
        print("*****length: \(model.microphoneProcessor.dataFloats.count)\n")
        
        model.startTranscription()
        
        CFRunLoopRun()
        model.stopTranscription()
        sleep(2)
        print("***********transcript count: \(model.localTranscripts.count)\n")
        
//        let currentPath = FileManager.default.currentDirectoryPath
//        let fileURL = URL(fileURLWithPath: currentPath).appendingPathComponent("res.txt")
        let fileURL = URL(fileURLWithPath: LocalPath).appendingPathComponent(OutputFileName)
        
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
try mainRun()
print("end\n")

