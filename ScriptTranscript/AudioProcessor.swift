//
//  AudioProcessor.swift
//  ScriptTranscript
//
//  Created by jk h on 2024/9/19.
//

import Foundation
import AVFoundation

/// Handles real-time audio input from the microphone, including audio processing and format conversion.
class MicrophoneInputProcessor {
    let audioEngine = AVAudioEngine()
    var formatConverter: AVAudioConverter!
    var dataFloats = [Float]()
    var canStop = false
    var sampleRate: Int = WhisperParams.WHISPER_SAMPLE_RATE
    let realTimeBufferQueue = DispatchQueue(label: "com.realTimeBuffer")
    let vaDurationMaxCount: Int = 25 // 2.5 seconds, max num of voice activity duration
    var vaDurationCount: Int = 0 // voice activity duration
    var dataCount: Int = 0
    
    /// Starts processing real-time audio input from the microphone, including format conversion and buffering.
    /// This method sets up an audio tap on the input node and starts the audio engine.
    func startRealTimeProcessing() throws {
        do {
            print("Audio processing start.")
        }
//        do {
//            let inputNode = self.audioEngine.inputNode
//            let format = inputNode.inputFormat(forBus: 0)
//
//            // Audio sample rate must be 16000
//            let outputFormat = AVAudioFormat(
//                commonFormat: .pcmFormatFloat32,
//                sampleRate: Double(self.sampleRate),
//                channels: 1,
//                interleaved: true
//            )!
//            
//            self.formatConverter = AVAudioConverter(from: format, to: outputFormat)!
//
//            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
//                guard let strongSelf = self else { return }
//
//                let duration = Double(buffer.frameCapacity) / buffer.format.sampleRate
//                let outputBufferCapacity = AVAudioFrameCount(outputFormat.sampleRate * duration)
//                let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputBufferCapacity)!
//
//                var error: NSError? = nil
//                if let formatConverter = strongSelf.formatConverter {
//                    let status = formatConverter.convert(
//                        to: outputBuffer,
//                        error: &error,
//                        withInputFrom: { inNumPackets, outStatus in
//                            outStatus.pointee = AVAudioConverterInputStatus.haveData
//                            return buffer
//                        }
//                    )
//                    
//                    if status == .error, let conversionError = error {
//                        print("Error converting audio file: \(conversionError)")
//                        return
//                    }
//                    formatConverter.reset()
//                }
//
//                // Process the buffer data into Float format
//                let oneFloat = decodePCMBuffer(outputBuffer)
//                strongSelf.realTimeBufferQueue.async {
//                    strongSelf.dataFloats += oneFloat
//                }
//            }
//
//            // Start audio engine
//            try self.audioEngine.start()
//            print("Real-time audio processing and playback started.")
//        } catch {
//            print("Error starting real-time processing and playback: \(error.localizedDescription)")
//        }
    }

    /// Retrieves and clears the buffered audio data from the real-time processor.
    /// - Returns: The array of audio samples in floating point format.
    func getAndResetAudioData() -> [Float] {
        var tempData: [Float] = []
//        realTimeBufferQueue.sync {
//            tempData = dataFloats
//            dataFloats.removeAll()
//        }
//        return tempData
        let start = dataCount*WhisperParams.WHISPER_SAMPLE_RATE
        if start < dataFloats.count {
            let end = start+WhisperParams.WHISPER_SAMPLE_RATE-1
            if end < dataFloats.count {
                tempData = Array(dataFloats[start...end])
            } else {
                tempData = Array(dataFloats[start...])
            }
            dataCount += 1
        } else {
            CFRunLoopStop(CFRunLoopGetMain())
        }
        return tempData
    }

    /// Stops the audio recording and processing, removing the tap from the input node.
    func stopRecord() {
//        audioEngine.stop()
//        audioEngine.inputNode.removeTap(onBus: 0)
        print("Audio processing stopped.")
    }
    
    func readAudioFile(audioPath: String) -> [AVAudioPCMBuffer] {
        do {
            if let audioFileURL = filePathURL(filePath: audioPath) {
                let audioFile = try AVAudioFile(forReading: audioFileURL)
                let audioFormat = audioFile.processingFormat
                let fileLength = UInt32(audioFile.length)
                var frameCount: UInt32 = 0
                var buffer:[AVAudioPCMBuffer] = []
                
                while frameCount < fileLength {
                    let frameToRead = min(fileLength - frameCount,160000)
                    // Create an audio buffer
                    guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameToRead) else {
                        print("Unable to create audio buffer")
                        return []
                    }
                    // Read the file into the buffer
                    try audioFile.read(into: audioBuffer)
                    buffer.append(audioBuffer)
                    frameCount += frameToRead
                    if frameCount >= fileLength {
                        break
                    }
                }
                print("*******readAudioFile******* buffer count:\(buffer.count)\n")
                // Return the populated buffer
                return buffer
                
            } else {
                return []
            }
        } catch {
            print("Error reading audio file: \(error.localizedDescription)")
            return []
        }
    }
    
    func loadAudioFile(audioPath: String) {
        dataCount = 0
        let bufList = readAudioFile(audioPath: audioPath)
        if bufList.count > 0 {
            for buf in bufList {
                let data = decodePCMBuffer(buf)
                dataFloats += data
            }
        } else {
            print("read audio file failed\n")
        }
        print("*******loadAudioFile******* data count:\(dataFloats.count)\n")
//        if let buf = readAudioFile(audioPath: audioPath) {
//            dataFloats = decodePCMBuffer(buf)
//        } else {
//            print("read audio file failed\n")
//        }
    }
}

