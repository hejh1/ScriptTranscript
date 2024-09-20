//
//  TranscriptionTimeTracker.swift
//  Synco
//
//  Created by Congxing Cai on 9/11/24.
//

import Foundation

class TranscriptionTimeTracker: ObservableObject {
    @Published var startTime: Date? = nil

    /// Starts the transcription session by recording the current time.
    func startTranscription(startTime: Date? = nil) {
        self.startTime = startTime ?? Date()
    }

    /// Calculates the elapsed time in seconds since transcription started.
    func elapsedTimeSinceStart() -> Int64 {
        guard let startTime = startTime else {
            return 0
        }
        return Int64(Date().timeIntervalSince(startTime))
    }

    /// Stops the transcription session.
    func stopTranscription() {
        startTime = nil
    }
}
