#!/usr/bin/env python3
"""Грубая статическая проверка Luau-файлов (в этой среде нет Luau/Selene).
Проверяет: баланс блоков (function/do/then/end), скобок, имена ремоутов и пути require.
Это НЕ замена Selene/Studio: это страховка от очевидных опечаток.
Запуск: python3 scripts/check_static.py"""
import re, sys, pathlib

root = pathlib.Path(__file__).resolve().parent.parent
src = root / "src"
errors = []

def strip(code: str) -> str:
    out, i, n = [], 0, len(code)
    while i < n:
        c = code[i]
        if code.startswith("--[[", i) or code.startswith("--[=[", i):
            m = re.match(r"--\[(=*)\[", code[i:])
            close = "]" + m.group(1) + "]"
            j = code.find(close, i)
            i = n if j < 0 else j + len(close)
        elif code.startswith("--", i):
            j = code.find("\n", i)
            i = n if j < 0 else j
        elif c in "\"'`":
            q = c; i += 1
            while i < n and code[i] != q:
                if code[i] == "\\": i += 1
                i += 1
            i += 1; out.append('""')
        elif code.startswith("[[", i):
            j = code.find("]]", i); i = n if j < 0 else j + 2; out.append('""')
        else:
            out.append(c); i += 1
    return "".join(out)

files = sorted(src.rglob("*.luau"))
for f in files:
    code = strip(f.read_text(encoding="utf-8"))
    tok = re.findall(r"[A-Za-z_][A-Za-z_0-9]*", code)
    count = lambda w: tok.count(w)
    opens = count("function") + count("do") + count("then") - count("elseif")
    ends = count("end")
    if opens != ends:
        errors.append(f"{f.relative_to(root)}: блоки не сходятся (открыто {opens}, end {ends})")
    if count("repeat") != count("until"):
        errors.append(f"{f.relative_to(root)}: repeat/until не сходятся")
    for a, b in ("()", "{}", "[]"):
        if code.count(a) != code.count(b):
            errors.append(f"{f.relative_to(root)}: не сходятся скобки {a}{b} ({code.count(a)} vs {code.count(b)})")
    if re.search(r"(=|\(|,|return)\s*if\s", code):
        errors.append(f"{f.relative_to(root)}: if-выражение (проверка баланса блоков ненадёжна)")

# Ремоуты
remotes = (src / "shared/Remotes.luau").read_text(encoding="utf-8")
to_server = set(re.findall(r"^\t(\w+) = \{ rate", remotes, re.M))
to_client = set(re.findall(r'^\t"(\w+)",', remotes, re.M))
for f in files:
    text = f.read_text(encoding="utf-8")
    for name in re.findall(r'NetServer\.on\(\s*"(\w+)"', text):
        if name not in to_server: errors.append(f"{f.name}: NetServer.on неизвестный ремоут {name}")
    for name in re.findall(r'NetServer\.fire\([^,]+,\s*"(\w+)"', text):
        if name not in to_client: errors.append(f"{f.name}: NetServer.fire неизвестный ремоут {name}")
    for name in re.findall(r'NetClient\.on\(\s*"(\w+)"', text):
        if name not in to_client: errors.append(f"{f.name}: NetClient.on неизвестный ремоут {name}")
    for name in re.findall(r'NetClient\.fire\(\s*"(\w+)"', text):
        if name not in to_server: errors.append(f"{f.name}: NetClient.fire неизвестный ремоут {name}")

# Клиентские ремоуты: у каждого есть слушатель на клиенте
client_text = "".join(p.read_text(encoding="utf-8") for p in (src / "client").rglob("*.luau"))
for name in sorted(to_client):
    if not re.search(r'NetClient\.on\(\s*"' + name + '"', client_text):
        errors.append(f"ремоут {name} никто не слушает на клиенте")
server_text = "".join(p.read_text(encoding="utf-8") for p in (src / "server").rglob("*.luau"))
for name in sorted(to_server):
    if not re.search(r'NetServer\.on\(\s*"' + name + '"', server_text):
        errors.append(f"ремоут {name} никто не слушает на сервере")

# Модули, на которые есть require(script.Parent.X) / Systems
for f in files:
    text = f.read_text(encoding="utf-8")
    for m in re.finditer(r"require\(script\.Parent\.(\w+)\)", text):
        base_dir = f.parent.parent if f.name == "init.luau" else f.parent
        if not (base_dir / (m.group(1) + ".luau")).exists() and not (base_dir / m.group(1)).exists():
            errors.append(f"{f.relative_to(root)}: require(script.Parent.{m.group(1)}) не найден")
    for m in re.finditer(r"require\((?:Server|Lib)\.Lib\.(\w+)\)|require\(Lib\.(\w+)\)", text):
        name = m.group(1) or m.group(2)
        base = src / ("server" if "server" in f.parts else "client") / "Lib" / (name + ".luau")
        if not base.exists(): errors.append(f"{f.relative_to(root)}: Lib.{name} не найден")

print("\n".join(errors) if errors else f"OK: {len(files)} файлов, проблем не найдено")
sys.exit(1 if errors else 0)
