#!/bin/sh

xcodebuild -scheme ScriptTranscript -configuration Debug -derivedDataPath ./Build

./Build/Build/Products/Debug/ScriptTranscript

