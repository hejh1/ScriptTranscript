import jiwer
import os

transform = jiwer.Compose([
    jiwer.ToLowerCase(),
    jiwer.RemovePunctuation(),
    jiwer.Strip(),
    jiwer.RemoveMultipleSpaces()
])

script_path = 'Resources/audioTranscript/'
subtitle_path = 'Resources/audioSubtitle/'

script_files = [file for file in os.listdir(script_path) if file.endswith('.txt') and os.path.isfile(os.path.join(script_path, file))]
script_files.sort() 

subtitle_files = [file for file in os.listdir(subtitle_path) if file.endswith('.txt') and os.path.isfile(os.path.join(subtitle_path, file))]
subtitle_files.sort() 

for txt_file in subtitle_files:
    if txt_file in subtitle_files:
        reference_file=script_path+txt_file
        f1=open(reference_file, encoding='utf-8')
        reference=""
        for line in f1:
            reference = reference + line.strip()

        hypothesis_file=subtitle_path+txt_file
        f2=open(hypothesis_file, encoding='utf-8')
        hypothesis=""
        for line in f2:
            hypothesis = hypothesis + line.strip()

        transformed_reference = transform(reference)
        transformed_hypothesis = transform(hypothesis)

        wer = jiwer.wer(transformed_reference, transformed_hypothesis)
        print(f"{txt_file} Word Error Rate: {wer:.2%}")
    else:
        print(f"{txt_file} is not in the audioSubtitle.")
        continue




