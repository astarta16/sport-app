"""Generates lib/l10n/app_{ka,en,ru}.arb from tool/strings*.py (tuples: ka, en, ru)."""
import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from strings import S as _S1
from strings_v12 import S as _S2
from strings_admin import S as _S3
from strings_v13 import S as _S4

S = {**_S1}
for extra in (_S2, _S3, _S4):
    dup = set(S) & set(extra)
    if dup:
        raise SystemExit(f'duplicate keys: {sorted(dup)}')
    S.update(extra)

root = os.path.join(os.path.dirname(__file__), '..', 'lib', 'l10n')

INT_NAMES = {'count', 'seconds', 'current', 'total', 'min', 'max', 'day', 'sent', 'skipped', 'minutes', 'percent', 'n', 'present', 'absent', 'excused', 'unmarked', 'yes', 'no', 'maybe', 'year', 'age', 'pageStart', 'pageEnd'}

def placeholders(text):
    names = {}
    plural = set(re.findall(r'\{(\w+),\s*plural', text))
    for n in re.findall(r'\{([A-Za-z_][A-Za-z0-9_]*)[,}]', text):
        names[n] = {'type': 'int'} if n in plural or n in INT_NAMES else {'type': 'String'}
    return names

missing_ru = [k for k, v in S.items() if len(v) < 3 or not v[2]]
for idx, locale in ((0, 'ka'), (1, 'en'), (2, 'ru')):
    out = {'@@locale': locale}
    for key, pair in S.items():
        # Missing Russian falls back to English and is reported (and fails
        # test/l10n/l10n_completeness_test.dart).
        text = pair[idx] if idx < len(pair) and pair[idx] else pair[1]
        out[key] = text
        ka, en = placeholders(pair[0]), placeholders(pair[1])
        ph = {k: v for k, v in ka.items() if k in en}
        if ph and idx == 0:
            out['@' + key] = {'placeholders': ph}
    with open(os.path.join(root, f'app_{locale}.arb'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
        f.write('\n')
with open(os.path.join(os.path.dirname(__file__), 'l10n_missing_ru.json'), 'w', encoding='utf-8') as f:
    json.dump(sorted(missing_ru), f, ensure_ascii=False, indent=0)
print(f'{len(S)} keys written; missing ru: {len(missing_ru)}')
