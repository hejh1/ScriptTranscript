//
//  WhisperTranscriptionManager.swift
//  Synco
//
//  Make WhisperTranscriptionManager act purely as a “transcription engine.”
//
//  It does not need to know whether it’s transcribing for local or remote audio.
//  It simply takes audio data, transcribes it, and returns the results.
//
//  Created by Congxing Cai on 9/11/24.
//

/*
### Transcription Buffering & Finalization Strategy

#### Previous Incremental Approach:
The old approach implemented in Swift relied on continuous buffering of audio samples, where intermediate unconfirmed transcripts were generated as soon as enough audio data was available.
This allowed for "live" transcription display, but the final transcript was only generated after further buffering confirmed that the speaker had stopped talking.

**Pros:**
- Immediate feedback with unconfirmed transcripts shown in real-time.
- Flexible buffer size for finalization based on voice activity.

**Cons:**
- Required maintaining two buffers (confirmed and unconfirmed) for handling transcription, leading to complexity.
- Handling buffer overflow or speech overlap could cause finalization errors or transcript duplication.
- Voice Activity Detection (VAD) was less effective at ensuring transcription finalization when speakers overlapped or paused briefly.

#### Current VAD Approach:
The new approach is inspired by the whisper.cpp implementation. This strategy focuses on collecting larger chunks of audio data before finalizing transcripts, ensuring higher transcription accuracy.
Instead of generating immediate unconfirmed transcripts, we only finalize transcripts once a meaningful chunk of audio has been processed, making use of **Voice Activity Detection (VAD)** to decide when to stop.

**Pros:**
- More reliable and accurate transcription, as larger audio contexts are used for finalization.
- Better handling of overlapping speech and pauses due to larger buffer sizes and stricter VAD thresholds.
- Reduces the chance of duplicated or fragmented transcripts by avoiding premature finalization.
- Simplified handling of the audio buffer: we collect data, run transcription, and finalize.

**Cons:**
- Less immediate feedback compared to the old Swift approach (transcripts are only shown after finalization).
- Might require tuning of VAD thresholds and buffer sizes for specific scenarios.

#### Why We Chose the Later Approach (However, we may change later.:
- **Higher transcription quality**: By waiting for more audio context, Whisper’s model can better capture the nuances of speech and generate more coherent transcripts.
- **Improved handling of overlapping speech**: The old approach struggled with overlapping speakers, while the CPP model better finalizes based on more complete audio chunks.
- **Simplified implementation**: The new approach avoids maintaining multiple buffers for unconfirmed and confirmed transcripts, reducing the complexity of managing audio state.

The WhisperCPP-inspired model also helps us better integrate with the Whisper transcription model, ensuring that transcriptions are finalized after enough audio has been captured and VAD determines the speaker has stopped.
*/

import Foundation

/// Manages the Whisper transcription process, including loading the model and handling transcription of audio data.
/// In Swift, we can leverage the actor model to ensure that WhisperTranscriptionManager is accessed serially.
/// An actor in Swift is a reference type that automatically ensures data isolation, meaning that only one task can interact with the actor’s state at any given time.
/// This will make WhisperTranscriptionManager thread-safe without the need for manual locks.
/// Both LocalTranscriptViewModel and RemoteTranscriptViewModel can access it in parallel.
actor WhisperTranscriptionManager {
    private var whisperContext: WhisperContext?

    private enum LoadError: Error {
        case couldNotLocateModel
    }

    /// Initializes the transcription manager and loads the Whisper model.
    init() throws {
        if let modelUrl = modelPath() {
            whisperContext = try WhisperContext.createContext(path: modelUrl.path())
        } else {
            print("Failed to init whisper.")
            throw LoadError.couldNotLocateModel
        }
    }

    /// Transcribes the given audio data (in floating point format) and returns the resulting transcript items.
    /// - Parameter audioFloat: An array of audio samples (floats) to transcribe.
    /// - Returns: An array of `TranscriptItem` containing the transcribed text.
    func transcribeAudio(_ audioFloat: [Float]) async -> [TranscriptItem] {
        guard let whisperContext else { return [] }

        await whisperContext.fullTranscribe(samples: audioFloat)
        let transcriptions = await whisperContext.getTranscription()
        print("Transcribed \(audioFloat.count) bytes to \(transcriptions.text)")
        if transcriptions.langID == 0 || transcriptions.langID == 1 {
            return transcriptions.text.map { TranscriptItem(role: nil, text: $0, start: 0) }
        } else {
            return []
        }
    }
}
