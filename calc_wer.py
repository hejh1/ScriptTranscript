import jiwer
import os
import sys
from prettytable import PrettyTable
import html

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


table = PrettyTable(['File', 'Language', 'Accent', 'URL','wer', 'mer', 'wil', 'wip', 'cer', 'OpenAI wer', 'OpenAI mer', 'OpenAI wil', 'OpenAI wip', 'OpenAI cer'])

for accent_file in accent_files:
    script_path = accent_path + accent_file + "/Transcript/"
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
            mer = jiwer.mer(transformed_reference, transformed_hypothesis)
            wil = jiwer.wil(transformed_reference, transformed_hypothesis)
            wip = jiwer.wip(transformed_reference, transformed_hypothesis)
            cer = jiwer.cer(transformed_reference, transformed_hypothesis)

            OpenAIwer = jiwer.wer(transformed_openAI_reference, transformed_hypothesis)
            OpenAImer = jiwer.mer(transformed_openAI_reference, transformed_hypothesis)
            OpenAIwil = jiwer.wil(transformed_openAI_reference, transformed_hypothesis)
            OpenAIwip = jiwer.wip(transformed_openAI_reference, transformed_hypothesis)
            OpenAIcer = jiwer.cer(transformed_openAI_reference, transformed_hypothesis)
            
            parts = txt_file.split("-")
            accent = parts[0]
            parts = txt_file.split("-")
            vid= "-".join(parts[1:]).split(".")[0]
            table.add_row([
                txt_file,
                language,
                accent,
                '<a href="https://www.youtube.com/watch?v='+ vid + '">link</a>',
                f"{wer:.2%}",
                f"{mer:.2%}",
                f"{wil:.2%}",
                f"{wip:.2%}",
                f"{cer:.2%}",
                f"{OpenAIwer:.2%}",
                f"{OpenAImer:.2%}",
                f"{OpenAIwil:.2%}",
                f"{OpenAIwip:.2%}",
                f"{OpenAIcer:.2%}"
            ])
            print(f"{txt_file} Word Error Rate: {wer:.2%}")
        else:
            print(f"{txt_file} is not in the audioSubtitle.")
            continue

text = table.get_html_string(format=True)
text = html.unescape(text)
with open('audio_jiwer.html', 'w') as f:
    f.write('<p>'+text+'</p>')
