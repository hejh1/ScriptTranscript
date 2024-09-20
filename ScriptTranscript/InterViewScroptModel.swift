//
//  InterViewScroptModel.swift
//  ScriptTranscript
//
//  Created by jk h on 2024/9/19.
//

import Foundation

struct TranscriptItem: Codable, Hashable, Equatable, Identifiable {
    var id = UUID()
    var role: String? // "Interviewer" or "Interviewee"
    var text: String?
    var start: Int64 = 0
}

extension TranscriptItem: CustomStringConvertible {
    func isBlank() -> Bool {
//        return text == " [BLANK_AUDIO]"
        guard let strongText = text else {
            return true
        }
        if strongText.hasPrefix(" [") && strongText.hasSuffix("]"){
            return true
        }
        if strongText.hasPrefix(" (") && strongText.hasSuffix(")"){
            return true
        }
        return false
    }

    var description: String {
        let roleText = role ?? "Unknown"
        let displayText = text ?? "No text"
        return "\n[\(roleText) @ \(start)] \(displayText)"
    }
}
