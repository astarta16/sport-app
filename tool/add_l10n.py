#!/usr/bin/env python3
"""Merges strings from a JSON file into lib/l10n/app_{en,ka,ru}.arb.

JSON shape: {"key": {"en": "...", "ka": "...", "ru": "...", "ph": {"name": "int"}}}
Existing keys are replaced, so the file can be re-run safely.
"""
import json, re, sys
from collections import OrderedDict

src = json.load(open(sys.argv[1]), object_pairs_hook=OrderedDict)
for lang in ('en', 'ka', 'ru'):
    path = f'lib/l10n/app_{lang}.arb'
    arb = json.load(open(path), object_pairs_hook=OrderedDict)
    for key, v in src.items():
        arb[key] = v[lang]
        if lang == 'ka':
            names = re.findall(r'\{(\w+)\}', v['en'])
            if names:
                ph = v.get('ph', {})
                arb['@' + key] = {'placeholders': {n: {'type': ph.get(n, 'String')} for n in names}}
    json.dump(arb, open(path, 'w'), ensure_ascii=False, indent=2)
    open(path, 'a').write('\n')
print(f'merged {len(src)} keys')
