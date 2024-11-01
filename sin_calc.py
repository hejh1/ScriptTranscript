import jiwer
import os
import sys

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

language = "en"
if len(sys.argv) > 1:
    language = sys.argv[1]

accent_path = "Resources/" + language + "/"
accent_path_files = os.listdir(accent_path)
accent_files = [entry for entry in accent_path_files if not entry.startswith('.')]
print(accent_files)

acc_type = ""
if len(sys.argv) > 2:
    acc_type = sys.argv[2]
    if acc_type == "asian":
        accent_files = ["asian", "asian2"]
    elif acc_type == "english":
        accent_files = ["english", "english2"]
    elif acc_type == "indian":
        accent_files = ["indian", "indian2"]
   

for accent_file in accent_files:
    script_path = accent_path + accent_file + "/Transcript-large-v3/"
    subtitle_path = accent_path + accent_file + "/Subtitle/"
    openAI_path = accent_path + accent_file + "/OpenAI/"
    script_files = [file for file in os.listdir(script_path) if file.endswith('.txt') and os.path.isfile(os.path.join(script_path, file))]
    script_files.sort() 
    
    subtitle_files = [file for file in os.listdir(subtitle_path) if file.endswith('.txt') and os.path.isfile(os.path.join(subtitle_path, file))]
    subtitle_files.sort() 
    
    for txt_file in script_files:
        if txt_file in subtitle_files:
            reference_file=script_path+txt_file
            with open(reference_file, 'r', encoding='utf-8') as file:
                reference = file.read()
            openAI_reference_file=openAI_path+txt_file
            with open(openAI_reference_file, 'r', encoding='utf-8') as file:
                openAI_reference = file.read()
            hypothesis_file=subtitle_path+txt_file
            with open(hypothesis_file, 'r', encoding='utf-8') as file:
                hypothesis = file.read()
            transformed_reference = transform(reference)
            transformed_openAI_reference = transform(openAI_reference)
            transformed_hypothesis = transform(hypothesis)
            wer = jiwer.wer(transformed_reference, transformed_hypothesis)
            print(f"{txt_file} Word Error Rate: {wer:.2%}")
        else:
            print(f"{txt_file} is not in the audioSubtitle.")
            continue

