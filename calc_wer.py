import jiwer
import os
import sys
from HTMLTable import HTMLTable

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

table = HTMLTable(caption='audio transcript jiwer table')
table.append_header_rows((
    ('File',    'Language',    'Accent',    'wer',    'mer',    'wil',    'wip',    'cer'),
))
for accent_file in accent_files:
    script_path = accent_path + accent_file + "/Transcript/"
    subtitle_path = accent_path + accent_file + "/Subtitle/"
    script_files = [file for file in os.listdir(script_path) if file.endswith('.txt') and os.path.isfile(os.path.join(script_path, file))]
    script_files.sort() 
    
    subtitle_files = [file for file in os.listdir(subtitle_path) if file.endswith('.txt') and os.path.isfile(os.path.join(subtitle_path, file))]
    subtitle_files.sort() 
    
    for txt_file in script_files:
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
            mer = jiwer.mer(transformed_reference, transformed_hypothesis)
            wil = jiwer.wil(transformed_reference, transformed_hypothesis)
            wip = jiwer.wip(transformed_reference, transformed_hypothesis)
            cer = jiwer.cer(transformed_reference, transformed_hypothesis)
            
            parts = txt_file.split("-")
            accent = parts[0]
            table.append_header_rows((
                (txt_file,    language,    accent,    f"{wer:.2%}",    f"{mer:.2%}",    f"{wil:.2%}",    f"{wip:.2%}",    f"{cer:.2%}"),
            ))
            print(f"{txt_file} Word Error Rate: {wer:.2%}")
        else:
            print(f"{txt_file} is not in the audioSubtitle.")
            continue

table.caption.set_style({
    'font-size': '15px',
})

table.set_style({
    'border-collapse': 'collapse',
    'word-break': 'keep-all',
    'white-space': 'nowrap',
    'font-size': '14px',
})

table.set_cell_style({
    'border-color': '#000',
    'border-width': '1px',
    'border-style': 'solid',
    'padding': '5px',
})

table.set_header_row_style({
    'color': '#fff',
    'background-color': '#48a6fb',
    'font-size': '18px',
})

html = table.to_html()

with open('audio_jiwer.html', 'w', encoding='utf-8') as f:
    f.write(html)
