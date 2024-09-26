import jiwer
import os

# 定义一个去掉换行符的自定义转换
class RemoveNewLines:
    def __call__(self, s):
        return s.replace("\n", " ").replace("\r", " ")

transform = jiwer.Compose([
    # jiwer.ToLowerCase(),
    # jiwer.RemovePunctuation(),
    # jiwer.Strip(),
    # jiwer.RemoveMultipleSpaces()
    RemoveNewLines(),
    jiwer.ToLowerCase(),
    jiwer.RemovePunctuation(),
    jiwer.Strip(),
    jiwer.RemoveMultipleSpaces(),
    jiwer.RemoveEmptyStrings()
    # jiwer.RemoveWhiteSpace(replace_by_space=False)
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
        with open(reference_file, 'r', encoding='utf-8') as file:
            reference = file.read()
        hypothesis_file=subtitle_path+txt_file
        with open(hypothesis_file, 'r', encoding='utf-8') as file:
            hypothesis = file.read()
        transformed_reference = transform(reference)
        transformed_hypothesis = transform(hypothesis)
        wer = jiwer.wer(transformed_reference, transformed_hypothesis)
        print(f"{txt_file} Word Error Rate: {wer:.2%}")
    else:
        print(f"{txt_file} is not in the audioSubtitle.")
        continue




