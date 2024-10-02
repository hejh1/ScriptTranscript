import Foundation
//import whisper

enum whisperError: Error {
    case couldNotInitializeContext
}

// Meet Whisper C++ constraint: Don't access from more than one thread at a time.
actor WhisperContext {
    private var context: OpaquePointer
    
    init(context: OpaquePointer) {
        self.context = context
    }
    
    deinit {
        whisper_free(context)
    }
    
    func fullTranscribe(samples: [Float]) {
        // Leave 2 processors free (i.e. the high-efficiency cores).
        let maxThreads = max(1, min(8, cpuCount() - 2))
        print("Selecting \(maxThreads) threads")
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)
        "auto".withCString { auto in
            // Adapted from whisper.objc
            params.print_realtime = true
            params.print_progress = false
            params.print_timestamps = true
            params.print_special = false
            params.translate = false
            params.language = auto
            params.n_threads = Int32(maxThreads)
            params.offset_ms = 0
            params.no_context = true
            params.single_segment = false
            
            whisper_reset_timings(context)
//            print("About to run whisper_full")
            samples.withUnsafeBufferPointer { samples in
//                print("\nt1: \(Date().timeIntervalSince1970)\n")
                if (whisper_full(context, params, samples.baseAddress, Int32(samples.count)) != 0) {
                    print("Failed to run the model")
                } 
//                print("\nt2: \(Date().timeIntervalSince1970)\n")
//                else {
//                    whisper_print_timings(context)
//                }
            }
        }
    }
    
    func getTranscription() -> (langID: Int32, text: [String], t: [Int64]) {
        var transcription = [String]()
        var transcripDate = [Int64]()
        for i in 0..<whisper_full_n_segments(context) {
            transcription.append(String.init(cString: whisper_full_get_segment_text(context, i)))
            let t0 = whisper_full_get_segment_t0(context,i)
//            let timeInterval = TimeInterval(t0)
            transcripDate.append(t0)
        }
        let langID = whisper_full_lang_id(context)
        return (langID, transcription,transcripDate)
    }
    
    static func createContext(path: String) throws -> WhisperContext {
        var cparams: whisper_context_params = whisper_context_default_params();
        cparams.use_gpu = WhisperParams.is_use_gpu
        cparams.dtw_aheads_preset = WHISPER_AHEADS_BASE
        let context = whisper_init_from_file_with_params(path, cparams)
        if let context {
            return WhisperContext(context: context)
        } else {
            print("Couldn't load model at \(path)")
            throw whisperError.couldNotInitializeContext
        }
    }
    
    func getLanguateID() -> Int32 {
        whisper_full_lang_id(context)
    }
}

fileprivate func cpuCount() -> Int {
    ProcessInfo.processInfo.processorCount
}
