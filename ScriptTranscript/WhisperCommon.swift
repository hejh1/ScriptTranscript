//
//  WhisperCommon.swift
//  InterviewCopilot
//
//  Created by jk h on 2024/8/26.
//

import Foundation


func vad_simple(pcmf32: inout [Float], sample_rate: Int, last_ms: Int, vad_thold: Float, freq_thold: Float) -> Bool {
    let n_samples      = pcmf32.count;
    let n_samples_last = (sample_rate * last_ms) / 1000;

    if (n_samples_last >= n_samples) {
        // not enough samples - assume no speech
        return false;
    }

    if freq_thold > 0.0 {
        high_pass_filter(data: &pcmf32, cutoff: freq_thold, sample_rate: Float(sample_rate));
    }

    var energy_all: Float  = 0.0;
    var energy_last: Float = 0.0;

    for i in 0..<n_samples {
        energy_all += fabsf(pcmf32[i]);

        if (i >= n_samples - n_samples_last) {
            energy_last += fabsf(pcmf32[i]);
        }
    }

    energy_all  /= Float(n_samples);
    energy_last /= Float(n_samples_last);

    if (energy_last > vad_thold*energy_all) {
        return false;
    }

    return true;
}

func high_pass_filter(data: inout [Float], cutoff: Float, sample_rate: Float) {
    let rc: Float = 1.0 / (2.0 * Float.pi * cutoff);
    let dt: Float = 1.0 / sample_rate;
    let alpha: Float = dt / (rc + dt);

    var y: Float = data[0];

    for i in 1..<data.count {
        y = alpha * (y + data[i] - data[i - 1]);
        data[i] = y;
    }
}

func noiseReduction(sample: Float) -> Float {
        let threshold: Float = 0.01
        return abs(sample) < threshold ? 0 : sample
}
