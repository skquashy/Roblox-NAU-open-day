#!/usr/bin/env python3
"""Проверка локализации: одинаковые ключи в uk/en и все ключи, используемые в коде, существуют.
Запуск: python3 scripts/check_locale.py"""
import re, sys, pathlib

root = pathlib.Path(__file__).resolve().parent.parent
def load(name):
    text = (root / "src/shared/Locale" / f"{name}.luau").read_text(encoding="utf-8")
    return dict(re.findall(r'\["([^"]+)"\]\s*=\s*"((?:[^"\\]|\\.)*)"', text))

uk, en = load("uk"), load("en")
ok = True
for k in sorted(set(uk) ^ set(en)):
    print("ключ есть только в одном языке:", k); ok = False
def placeholders(s): return sorted(re.findall(r"\{\d+\}", s))
for k in uk:
    if k in en and placeholders(uk[k]) != placeholders(en[k]):
        print("разные параметры:", k); ok = False

# ключі, використані в коді
used = set()
for path in (root / "src").rglob("*.luau"):
    if "Locale" in path.parts: continue
    code = path.read_text(encoding="utf-8")
    for m in re.finditer(r'["\']@?((?:ui|arch|fac|toast|quest|badge|item|npc|mg|finale|building|shop|monument|tram)\.[A-Za-z0-9_.]+)["\']', code):
        used.add(m.group(1))
for k in sorted(used):
    if k not in uk and not k.endswith((".", "_")):
        print("ключ используется, но не определён:", k); ok = False

# динамічні ключі: id факультетів беремо з Data/Faculties.luau
faculties = re.findall(r'id = "(\w+)"', (root / "src/shared/Data/Faculties.luau").read_text(encoding="utf-8"))
if len(faculties) != 9:
    print("в Data/Faculties.luau ожидается 9 факультетов, найдено", len(faculties)); ok = False
dyn = []
for f in faculties:
    for pre in ("fac.%s.name", "fac.%s.abbr", "quest.play_%s", "badge.faculty_%s.name"):
        dyn.append(pre % f)
for kind in ["grocery", "coffee", "pharmacy", "books", "pizza", "flowers"]:
    dyn.append("shop." + kind)
for brand in ['silpo', 'atb', 'novus', 'aroma', 'lvivcroissants', 'podorozhnyk', 'apteka911', 'yeknyharnia', 'starylev', 'veterano', 'celentano', 'flowers', 'roshen', 'novaposhta']:
    dyn.append("shop.brand." + brand)
for i in (1, 2, 3):
    dyn.append("mg.fknt.safe%d" % i)
    dyn.append("mg.fknt.bad%d" % i)
for key in ("btn.patch", "btn.block", "btn.restart", "threat.virus", "threat.attack", "threat.crash"):
    dyn.append("mg.fknt." + key)
for k in dyn:
    if k not in uk: print("не хватает динамического ключа:", k); ok = False

print("OK" if ok else "ЕСТЬ ПРОБЛЕМЫ", f"({len(uk)} ключей uk, {len(en)} en)")
sys.exit(0 if ok else 1)
