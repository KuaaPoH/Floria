import os
import re

pattern = re.compile(r'https://images\.unsplash\.com/photo-[a-zA-Z0-9\-]+(\?([^\"\x27]*))?')

mapping = {}
seed_counter = 1

def replacer(match):
    global seed_counter
    url = match.group(0)
    if url not in mapping:
        mapping[url] = f'https://picsum.photos/seed/plant{seed_counter}/400/400'
        seed_counter += 1
    return mapping[url]

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            new_content = pattern.sub(replacer, content)
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Updated {path}')
