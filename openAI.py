from openai import OpenAI
import os
import sys
from pydub import AudioSegment

language = "en"
if len(sys.argv) > 1:
    language = sys.argv[1]

accent_path = "Resources/" + language + "/"
accent_path_files = os.listdir(accent_path)
accent_files = [entry for entry in accent_path_files if not entry.startswith('.')]
print(accent_files)

accent_files = ["english2"]
client = OpenAI()

for accent_file in accent_files:
    audio_path = accent_path + accent_file + "/Files/"
    audio_files = [file for file in os.listdir(audio_path) if file.endswith('.mp3')]
    for f in audio_files:
        file = audio_path + f
        print(f)
        data= open(file, "rb")
        transcription = client.audio.transcriptions.create(
          model="whisper-1", 
          file=data
        )
        txt = f.replace(".mp3", ".txt")
        filename = accent_path + accent_file + "/OpenAI/" + txt
        with open(filename, 'w', encoding='utf-8') as file:
            # Write a single line
            file.write(transcription.text)

        print(transcription.text)
