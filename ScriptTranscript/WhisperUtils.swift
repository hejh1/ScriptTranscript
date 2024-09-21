//
//  WhisperUtils.swift
//  InterviewCopilot
//
//  Created by jk h on 2024/8/4.
//

import Foundation
import SwiftUI
import AVFoundation

actor Recorder {
    private var recorder: AVAudioRecorder?
    
    enum RecorderError: Error {
        case couldNotStartRecording
    }
    
    func startRecording(toOutputFile url: URL, delegate: AVAudioRecorderDelegate?) throws {
        let recordSettings: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: Double(WhisperParams.WHISPER_SAMPLE_RATE),
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let recorder = try AVAudioRecorder(url: url, settings: recordSettings)
        recorder.delegate = delegate
        if recorder.record() == false {
            print("Could not start recording")
            throw RecorderError.couldNotStartRecording
        }
        self.recorder = recorder
    }
    
    func stopRecording() {
        recorder?.stop()
        recorder = nil
    }
}

func decodeWaveFile(_ url: URL) throws -> [Float] {
    let data = try Data(contentsOf: url)
    let floats = stride(from: 44, to: data.count, by: 2).map {
        return data[$0..<$0 + 2].withUnsafeBytes {
            let short = Int16(littleEndian: $0.load(as: Int16.self))
            return max(-1.0, min(Float(short) / 32767.0, 1.0))
        }
    }
    return floats
}


func decodeWaveFile2(_ url: URL) throws -> [Float] {
    let data = try Data(contentsOf: url)
    let floats = stride(from: 44, to: data.count, by: 4).map {
        return data[$0..<$0 + 4].withUnsafeBytes {
            let float = $0.load(as: Float32.self)
            return max(-1.0, min(float, 1.0))
        }
    }
    return floats
}

struct WhisperParams {
    static let WHISPER_SAMPLE_RATE = 16000
    static let vad_thold: Float = 0.6
    static let freq_thold: Float = 100.0
    static let rms_threshold_mic: Float = 0.03
    static let rms_threshold_system: Float = 0.00
}

func decodePCMBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
    guard let floatChannelData = buffer.floatChannelData else {
        print("Invalid PCM Buffer")
        return []
    }
    
    let channelCount = Int(buffer.format.channelCount)
    let frameLength = Int(buffer.frameLength)
    
    var floats = [Float]()
    
    for frame in 0..<frameLength {
        for channel in 0..<channelCount {
            let floatData = floatChannelData[channel]
            let index = frame * channelCount + channel
            let floatSample = floatData[index]
            floats.append(max(-1.0, min(floatSample, 1.0)))
        }
    }
    
    return floats
}

func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
    guard let channelData = buffer.floatChannelData else { return 0 }
    let channelDataPointer = channelData.pointee
    let frameLength = Int(buffer.frameLength)
    var val: Float = 0.0
    for i in 0..<frameLength {
        val += channelDataPointer[i]*channelDataPointer[i]
    }
    let rms = sqrt(val/Float(frameLength))
    
    return rms
}

func modelPath() -> URL? {
//    let currentDirectoryPath = FileManager.default.currentDirectoryPath
//    let relativeFilePath = "Resources/ggml-base.bin"
//    let fullPath = currentDirectoryPath + "/" + relativeFilePath
//    let fileURL = URL(fileURLWithPath: fullPath)
    let fileURL = URL(fileURLWithPath: WhisperModelPath)
    return fileURL
}

func filePathURL(filePath: String) -> URL? {
    let fileURL = URL(fileURLWithPath: filePath)
    return fileURL
}
