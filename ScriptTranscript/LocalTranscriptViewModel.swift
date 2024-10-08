//
//  LocalTranscriptViewModel.swift
//  Synco
//
//  Created by Congxing Cai on 9/11/24.
//

import Foundation
import libfvad

/// Manages the transcription of local audio (e.g., microphone input) and handles buffering,
/// transcription, and maintaining a list of local transcripts.
class LocalTranscriptViewModel: ObservableObject {

    /// Holds the list of transcripts generated from local (microphone) audio.
    @Published var localTranscripts: [TranscriptItem] = []

    /// Reference to the WhisperTranscriptionManager which handles transcription.
    private var whisperTranscriptionManager: WhisperTranscriptionManager

    /// Real-time audio processor to capture audio input from the microphone.
    private var microphoneProcessor: MicrophoneInputProcessor

    private var vad: VadAudio = VadAudio()

    /// Buffer to accumulate audio data before transcription.
    private var audioBuffer: [Float] = []

    /// Buffer to store the audio for the current sentence.
    private var currentSentenceAudioBuffer: [Float] = []

    /// Tracks the  time of the transcription session.
    private let transcriptionTimeTracker: TranscriptionTimeTracker

    private var isTranscribing = false

    // Parameters for buffer handling and chunk processing
    private let frameMs: Int = 100     // Frame size in milliseconds (100 ms)
    private let lengthMs: Int = 30000 // Maximum length of audio in milliseconds (30 seconds)
    private let silenceThresholdMs: Int = 800 // Silence threshold to detect sentence breaks (800 ms)

    private let sampleRate: Int = WhisperParams.WHISPER_SAMPLE_RATE // Whisper's expected sample rate (16kHz)

    /// Number of audio samples in a frame.
    private var frameSamples: Int { return (frameMs * sampleRate) / 1000 }

    /// Maximum number of samples to be processed.
    private var lengthSamples: Int { return (lengthMs * sampleRate) / 1000 }

    /// Minimum number of samples to be processed.
    private var minimumAudioBufferLength: Int { return (1000 * sampleRate) / 1000 } // 1 second of audio

    /// Tracks the duration of silence.
    private var silenceDurationMs: Int = 0

    /// Tracks the time since the last transcription.
    private var timeSinceLastTranscriptionMs: Int = 0

    /// Interval at which transcription is performed.
    private let transcriptionIntervalMs: Int = 3000 // Transcribe every 3 second

    /// Tracks whether the last transcript item is finalized.
    private var lastTranscriptFinalized: Bool = true

    /// Flag to indicate if a transcription is in progress.
    private var isTranscriptionInProgress = false

    /// Flag to indicates if sentence finalization is in progress.
    private var isFinalizingSentence = false

    /// Initializes the local transcript view model with a WhisperTranscriptionManager instance.
    init(whisperTranscriptionManager: WhisperTranscriptionManager, transcriptionTimeTracker: TranscriptionTimeTracker, microphoneInputProcessor: MicrophoneInputProcessor) {
        self.whisperTranscriptionManager = whisperTranscriptionManager
        self.microphoneProcessor = microphoneInputProcessor
        self.transcriptionTimeTracker = transcriptionTimeTracker
    }

    /// Starts the transcription process for the local audio input.
    /// This continuously captures audio, processes chunks, and performs transcription.
    func startTranscription() {
        guard !isTranscribing else { return } // Avoid starting transcription multiple times
        isTranscribing = true
        Task.detached(priority: .background) { [weak self] in
            #if DEBUG
            Thread.current.name = "MicrophoneTranscriptionLoop"
            #endif
            guard let strongSelf = self else { return }
            do {
                // Start real-time audio processing from the microphone
                try strongSelf.microphoneProcessor.startRealTimeProcessing()
                
                // Continuously capture and process audio data
                while strongSelf.isTranscribing {
                    let newAudioData = strongSelf.microphoneProcessor.getAndResetAudioData()
                    strongSelf.audioBuffer.append(contentsOf: newAudioData)

                    // Frame-based Processing:
                    // - Introduced frameMs and frameSamples to process audio in smaller chunks.
                    // - This allows for more responsive VAD checks and transcription updates.
                    while strongSelf.audioBuffer.count >= strongSelf.frameSamples {
                        let frame = Array(strongSelf.audioBuffer.prefix(strongSelf.frameSamples))
                        strongSelf.audioBuffer.removeFirst(strongSelf.frameSamples)
                        
                        // Check VAD on the frame - tracking silence duration
                        if strongSelf.isSpeaking(frame) {
                            strongSelf.currentSentenceAudioBuffer.append(contentsOf: frame)
                            strongSelf.silenceDurationMs = 0
                        } else {
                            strongSelf.silenceDurationMs += strongSelf.frameMs
                            print("LocalTranscriptViewModel: silence duration - \(strongSelf.silenceDurationMs) ms")
                            // Do not append silence frames
                        }
                        
                        // Check for sentence break - bulge-in or too long.
                        if strongSelf.silenceDurationMs >= strongSelf.silenceThresholdMs || strongSelf.currentSentenceAudioBuffer.count >= strongSelf.lengthSamples {
                            // Sentence break detected
                            await strongSelf.finalizeCurrentSentence()
                        }
                        
                        // Update time since last transcription
                        strongSelf.timeSinceLastTranscriptionMs += strongSelf.frameMs

                        // Transcription frequency:
                        // - Transcription occurs every transcriptionIntervalMs (1 second) as defined by timeSinceLastTranscriptionMs.
                        // - The processCurrentSentence function updates the last TranscriptItem with new transcriptions.
                        // - If a sentence-ending punctuation is detected, it finalizes the current sentence.
                        if strongSelf.timeSinceLastTranscriptionMs >= strongSelf.transcriptionIntervalMs {
                            // Transcribe current sentence audio buffer
                            if !strongSelf.isTranscriptionInProgress && !strongSelf.currentSentenceAudioBuffer.isEmpty {
                                strongSelf.timeSinceLastTranscriptionMs = 0
                                await strongSelf.processCurrentSentence()
                            }
                        }
                    }

                    // Sleep for 100 milliseconds before checking again
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            } catch {
                print("LocalTranscriptViewModel: error starting transcription: \(error.localizedDescription)")
            }
        }
    }

    /// Stops the transcription process and terminates the audio processing.
    func stopTranscription() {
        isTranscribing = false
        microphoneProcessor.stopRecord()
        print("LocalTranscriptViewModel: stopped.")
        printTranscripts()
    }

    /// Processes the current sentence audio buffer by transcribing it and updating the last TranscriptItem.
    /// Transcription occurs every transcriptionIntervalMs (1 second) as defined by timeSinceLastTranscriptionMs.
    private func processCurrentSentence() async {
        guard !isTranscriptionInProgress else { return }
        isTranscriptionInProgress = true

        // Ensure we have accumulated enough audio before transcribing
        if currentSentenceAudioBuffer.count < minimumAudioBufferLength {
            isTranscriptionInProgress = false
            return
        }

        let combinedAudio = currentSentenceAudioBuffer
        if combinedAudio.isEmpty {
            isTranscriptionInProgress = false
            return
        }

        print("LocalTranscriptViewModel: starting transcription in processCurrentSentence")
        let transcripts = await self.whisperTranscriptionManager.transcribeAudio(combinedAudio)
        print("LocalTranscriptViewModel: finished transcription in processCurrentSentence")

        DispatchQueue.main.async {
            #if DEBUG
            Thread.current.name = "MicrophoneProcessCurrentSentence"
            #endif
            var sentence = ""
            for transcript in transcripts {
                sentence.append(transcript.text ?? "")
            }
            if self.isSentenceBreak(sentence: sentence) {
                self.currentSentenceAudioBuffer.removeAll()
                print("LocalTranscriptViewModel: cleared buffer in processCurrentSentence")
            } else {
                if !self.lastTranscriptFinalized, let lastIndex = self.localTranscripts.indices.last {
                    print("LocalTranscriptViewModel: updating transcript at last index \(lastIndex)")
                    self.localTranscripts[lastIndex].text = sentence
                } else {
                    // No last item or last item is finalized, create a new one
                    print("LocalTranscriptViewModel: drafting new transcript")
                    let item = TranscriptItem(role: "Interviewee", text: sentence, start: self.transcriptionTimeTracker.elapsedTimeSinceStart())
                    self.localTranscripts.append(item)
                    self.lastTranscriptFinalized = false
                }
            }
        }

        isTranscriptionInProgress = false
    }

    /// Finalizes the current sentence by transcribing it and starting a new TranscriptItem.
    private func finalizeCurrentSentence() async {
        print("LocalTranscriptViewModel: try to finalize current sentence audio.")
        guard !isFinalizingSentence else { return }
        isFinalizingSentence = true
        print("LocalTranscriptViewModel: ready to finalize current sentence audio.")
        let combinedAudio = currentSentenceAudioBuffer
        if combinedAudio.isEmpty {
            isFinalizingSentence = false
            silenceDurationMs = 0
            timeSinceLastTranscriptionMs = 0
            return
        }
        print("LocalTranscriptViewModel: starting transcription in finalizeCurrentSentence")
        let transcripts = await self.whisperTranscriptionManager.transcribeAudio(combinedAudio)
        print("LocalTranscriptViewModel: finished transcription in finalizeCurrentSentence")

        // Update the last TranscriptItem and mark it as finalized
        DispatchQueue.main.async {
            #if DEBUG
            Thread.current.name = "MicrophoneFinalizeSentence"
            #endif
            var sentence = ""
            for transcript in transcripts {
                sentence.append(transcript.text ?? "")
            }
            if self.isSentenceBreak(sentence: sentence) {
                print("LocalTranscriptViewModel: empty transcription in finalizeCurrentSentence")
            } else {
                if let lastIndex = self.localTranscripts.indices.last {
                    print("LocalTranscriptViewModel: finalizing transcript to index \(lastIndex)")
                    self.localTranscripts[lastIndex].text = sentence
                    //                    Task {
                    //                        // Post-process and assign the result back to the array
                    //                        if let updatedItem = await self.postProcessSentence(transcript.text, for: self.localTranscripts[lastIndex]) {
                    //                            DispatchQueue.main.async {
                    //                                self.localTranscripts[lastIndex] = updatedItem
                    //                            }
                    //                        }
                    //                    }
                }
            }
            // Clear the current sentence buffer and reset counters
            self.lastTranscriptFinalized = true
            self.currentSentenceAudioBuffer.removeAll()
            self.silenceDurationMs = 0
            self.timeSinceLastTranscriptionMs = 0
        }
        isFinalizingSentence = false
    }

    /// Sends the finalized sentence to another LLM for post-processing.
    /// Returns the updated TranscriptItem.
    private func postProcessSentence(_ text: String?, for item: TranscriptItem) async -> TranscriptItem? {
        // Placeholder for sending the text to another LLM for post-processing
        // Implement the interface to call the LLM and get the post-processed text
        // For example:
        // let postProcessedText = await anotherLLM.process(text)
        // var updatedItem = item
        // updatedItem.text = postProcessedText
        // return updatedItem
        var updatedItem = item
        return updatedItem
    }

    private func printTranscripts() {
        print("LocalTranscriptViewModel: total \(localTranscripts.count) transcript items")
        for transcript in localTranscripts {
            print("\t - LocalTranscriptViewModel: \(String(describing: transcript.text))")
        }
    }

    private func isSentenceBreak(sentence: String) -> Bool {
        let t = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty {
            return true
        } else if t.hasPrefix("[") && t.hasSuffix("]") {
            return true
        } else if t.hasPrefix("(") && t.hasSuffix(")") {
            return true
        } else {
            return false
        }
    }
    /// Detects whether there is speech in the current audio buffer using Voice Activity Detection (VAD).
    private func isSpeaking(_ audioBuffer: [Float]) -> Bool {
        guard !audioBuffer.isEmpty else { return false }

        // Basic VAD formula
        let rms = calculateRMS(audioBuffer)
        let rmsThreshold: Float = 0.02 // Adjust threshold based on noise levels
        return rms > rmsThreshold

//        do {
//            let activity = try vad.processVad(buf: audioBuffer)
//            print("LocalTranscriptViewModel VAD detected activity: \(activity)")
//            return activity == VadVoiceActivity.activeVoice
//        } catch VadAudioError.notInitialized {
//            print("LocalTranscriptViewModel VAD is not initialized.")
//            return true
//        } catch VadAudioError.bufferTooShort(let length) {
//            print("LocalTranscriptViewModel VAD buffer too short for length: \(length)")
//            return false
//        } catch {
//            print("LocalTranscriptViewModel VAD unexpected error: \(error)")
//            return true
//        }
    }

    /// Calculates the Root Mean Square (RMS) of the audio buffer, used for speech detection.
    private func calculateRMS(_ audioBuffer: [Float]) -> Float {
        let squareSum = audioBuffer.reduce(0) { sum, sample in sum + (sample * sample) }
        let meanSquare = squareSum / Float(audioBuffer.count)
        return sqrt(meanSquare)
    }
}
