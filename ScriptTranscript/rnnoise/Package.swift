// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "rnnoise",
	products: [
		.library(
			name: "librnnoise",
			targets: ["rnnoise"]
		),
		.library(
			name: "librnn_vad",
			type: .static,
			targets: ["rnn_vad"]
		),
	],
	targets: [
		.target(
			name: "rnn_vad",
			path: "src",
			sources: [
				"rnn_vad_weights.cc",
			],
			publicHeadersPath: "include_rnn_vad",
			cSettings: [
				.headerSearchPath("include_rnn_vad/rnn_vad"),
			]
		),
		.target(
			name: "rnnoise",
			dependencies: [
				"rnn_vad"
			],
			path: "src",
			sources: [
				"celt_lpc.c",
				"denoise.c",
				"kiss_fft.c",
				"pitch.c",
				"rnn.c",
				"rnn_data.c",
				"rnn_reader.c",
			],
			publicHeadersPath: "include",
			cSettings: [
				.headerSearchPath("."),
				.headerSearchPath("../config"),
				.define("HAVE_CONFIG_H")
			]
		),
	],
	cLanguageStandard: .gnu11,
	cxxLanguageStandard: .gnucxx20
)
