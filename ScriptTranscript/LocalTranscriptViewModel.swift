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
//    private var microphoneProcessor: MicrophoneInputProcessor
    var microphoneProcessor: MicrophoneInputProcessor

    private var vad: VadAudio = VadAudio()

    /// Buffer to accumulate audio data before transcription.
    private var audioBuffer: [Float] = []
    
    /// Buffer to store the last portion of audio for context when processing the next chunk.
    private var oldAudioBuffer: [Float] = []
    
    /// Tracks the  time of the transcription session.
    private let transcriptionTimeTracker: TranscriptionTimeTracker

    private var isTranscribing = false
    
    // Parameters for buffer handling and chunk processing
    private let stepMs: Int = 5000   // Step size in milliseconds (5 seconds)
    private let lengthMs: Int = 20000 // Maximum length of audio in milliseconds (20 seconds)
    private let keepMs: Int = 200     // Amount of previous audio to keep in milliseconds (200 ms)
    
    private let sampleRate: Int = WhisperParams.WHISPER_SAMPLE_RATE // Whisper's expected sample rate (16kHz)
    
    /// Number of audio samples in a step chunk.
    private var stepSamples: Int { return (stepMs * sampleRate) / 1000 }
    
    /// Maximum number of samples to be processed.
    private var lengthSamples: Int { return (lengthMs * sampleRate) / 1000 }
    
    /// Number of audio samples to keep for context between chunks.
    private var keepSamples: Int { return (keepMs * sampleRate) / 1000 }

    /// Initializes the local transcript view model with a WhisperTranscriptionManager instance.
    init(whisperTranscriptionManager: WhisperTranscriptionManager, transcriptionTimeTracker: TranscriptionTimeTracker) {
        self.whisperTranscriptionManager = whisperTranscriptionManager
        self.microphoneProcessor = MicrophoneInputProcessor()
        self.transcriptionTimeTracker = transcriptionTimeTracker
    }

    /// Starts the transcription process for the local audio input.
    /// This continuously captures audio, processes chunks, and performs transcription.
    func startTranscription() {
        guard !isTranscribing else { return } // Avoid starting transcription multiple times
        isTranscribing = true
        Task {
            do {
                // Start real-time audio processing from the microphone
                try microphoneProcessor.startRealTimeProcessing()
                
                // Continuously capture and process audio data
                while isTranscribing {
                    let newAudioData = microphoneProcessor.getAndResetAudioData()
                    audioBuffer.append(contentsOf: newAudioData)

                    print("Microphone audio buffer length \(audioBuffer.count)")

                    // Process if enough audio samples have been accumulated
                    if audioBuffer.count >= stepSamples && isSpeaking(audioBuffer) {
                        await processAudioChunk()
                        keepOldAudioForContext()
                        audioBuffer.removeAll()
                    }

                    // Sleep for 100 milliseconds before checking again
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            } catch {
                print("Error starting transcription: \(error.localizedDescription)")
            }
        }
    }

    /// Stops the transcription process and terminates the audio processing.
    func stopTranscription() {
        isTranscribing = false
        microphoneProcessor.stopRecord()
        print("Transcription stopped.")
    }

    /// Processes a chunk of audio data by combining current and old audio for context,
    /// then transcribes the audio using WhisperTranscriptionManager.
    private func processAudioChunk() async {
        // Combine old audio with the new buffer for context
        var combinedAudio = oldAudioBuffer + audioBuffer
        
        // Truncate if the combined audio exceeds the maximum length
        if combinedAudio.count > lengthSamples {
            combinedAudio = Array(combinedAudio.suffix(lengthSamples))
        }
        print("Process microphone captured audio: \(combinedAudio.count)")
        // Transcribe the audio using WhisperTranscriptionManager
        let finalTranscripts = await whisperTranscriptionManager.transcribeAudio(combinedAudio)

        // Update the list of local transcripts
        DispatchQueue.main.async {
            for transcript in finalTranscripts {
                let item = TranscriptItem(role: "Interviewee", text: transcript.text, start: self.transcriptionTimeTracker.elapsedTimeSinceStart())
                if !self.localTranscripts.contains(where: { $0.text == transcript.text }) {
                    self.localTranscripts.append(item)
                }
            }
        }
    }

    /// Stores a portion of the current audio buffer for use as context in the next transcription chunk.
    private func keepOldAudioForContext() {
        oldAudioBuffer = Array(audioBuffer.suffix(keepSamples))
    }

    /// Detects whether there is speech in the current audio buffer using Voice Activity Detection (VAD).
    private func isSpeaking(_ audioBuffer: [Float]) -> Bool {
        guard !audioBuffer.isEmpty else { return false }
        let activity = vad.processVad(buf: audioBuffer)
        print("Microphone detected activity: \(activity)")
        return activity == VadVoiceActivity.activeVoice

//        // Basic VAD formula
//        let rms = calculateRMS(audioBuffer)
//        let rmsThreshold: Float = 0.02 // Adjust threshold based on noise levels
//        return rms > rmsThreshold
    }

    /// Calculates the Root Mean Square (RMS) of the audio buffer, used for speech detection.
    private func calculateRMS(_ audioBuffer: [Float]) -> Float {
        let squareSum = audioBuffer.reduce(0) { sum, sample in sum + (sample * sample) }
        let meanSquare = squareSum / Float(audioBuffer.count)
        return sqrt(meanSquare)
    }
}
