//
//  vadLib.swift
//  Synco
//
//  Created by jk h on 2024/9/13.
//

import Foundation
import libfvad
import rnnoise

class VadAudio {
    private var vad = VoiceActivityDetector()
    
    init() {
        do {
            try vad.setMode(mode: VadOperatingMode.quality)
            try vad.setSampleRate(sampleRate: WhisperParams.WHISPER_SAMPLE_RATE)
        } catch {
            print("VadAudio init error: \(error)\n")
        }
    }
    
    func processVad(buf: [Float]) -> VadVoiceActivity {
        return VadVoiceActivity.activeVoice
//        var bufInt: [Int16] = []
//        let int16Max: Int16 = 32767
//        let samplesPerMs = WhisperParams.WHISPER_SAMPLE_RATE/100
//        if buf.count < samplesPerMs {
//            print("processVad buf too short, length: \(buf.count)\n")
//            return VadVoiceActivity.nonActiveVoice
//        }
//        for i in 0..<samplesPerMs {// per ms audio data
//            bufInt.append(Int16(buf[i] * Float(int16Max)))
//        }
//        do {
//            let activity: VadVoiceActivity = try bufInt.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) in
//                let p = pointer.assumingMemoryBound(to: Int16.self)
//                return try self.vad.process(frame: p.baseAddress!, length: p.count)
//            }
//            return activity
//        } catch {
//            print("VadAudio processVad error: \(error)\n")
//            return VadVoiceActivity.nonActiveVoice
//        }
    }
}

class RnnoiseAudio {
    private var model: OpaquePointer
    let FRAME_SIZE = 480
    
    init() {
        self.model = rnnoise_create(nil)
    }
    
    func processFrame(audioData: [Float]) -> [Float]{
        var start = 0
        var end = FRAME_SIZE
        var outData = [Float]()
        while end < audioData.count
        {
            var tempData: [Float] = Array(audioData[start...end-1])
            tempData.withUnsafeMutableBufferPointer { bufferPointer in
                rnnoise_process_frame(model, bufferPointer.baseAddress, bufferPointer.baseAddress)
            }
            start += FRAME_SIZE
            end += FRAME_SIZE
            outData += tempData
        }
        if start < audioData.count {
            outData += Array(audioData[start...])
        }
        return outData
    }
    
    func destroy() {
        rnnoise_destroy(model)
    }
}

enum VadAudioError: Error {
    case notInitialized
    case bufferTooShort(length: Int)
    case processingFailed(error: Error)
}
