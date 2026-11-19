#!/usr/bin/env python3
"""Google日本語入力のローマ字テーブルに `jj` → Esc の即確定ルールを設定する。

`jj` を ESC 文字 (U+001B) に変換し、DirectInput 属性で未確定を経ずに確定させる。
ターミナル上の Neovim は ESC を受け取って Normal モードへ戻る。

  python3 jj-esc.py            # ルールを追加（設定は自動でバックアップ）
  python3 jj-esc.py --remove   # jj を標準の「っ」+ j に戻す
  python3 jj-esc.py --status   # 現在の jj ルールを表示

設定画面でローマ字テーブルを編集・保存すると DirectInput 属性が消えるので、
その後はこのスクリプトを再実行すること。
"""
import argparse
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

CONFIG = Path.home() / "Library/Application Support/Google/JapaneseInput/config1.db"
DEFAULT_TABLE = Path(__file__).resolve().parent / "romanji-hiragana.tsv"
CONVERTER = "com.google.inputmethod.Japanese.Converter"
CUSTOM_ROMAN_TABLE = 43  # mozc.config.Config.custom_roman_table

JJ_ESC = "jj\t\x1b\t\tDirectInput"
JJ_DEFAULT = "jj\tっ\tj"


# --- minimal protobuf (wire format) helpers --------------------------------
def _varint(value):
    out = bytearray()
    while value > 127:
        out.append((value & 127) | 128)
        value >>= 7
    out.append(value)
    return bytes(out)


def _read_varint(data, pos):
    value = shift = 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 127) << shift
        if byte < 128:
            return value, pos
        shift += 7


def _skip_group(data, pos, field):
    while True:
        tag, pos = _read_varint(data, pos)
        if tag & 7 == 4 and tag >> 3 == field:
            return pos
        pos = _skip_value(data, pos, tag)


def _skip_value(data, pos, tag):
    wire = tag & 7
    if wire == 0:
        return _read_varint(data, pos)[1]
    if wire == 1:
        return pos + 8
    if wire == 2:
        length, pos = _read_varint(data, pos)
        return pos + length
    if wire == 3:
        return _skip_group(data, pos, tag >> 3)
    if wire == 5:
        return pos + 4
    raise ValueError(f"unsupported wire type {wire}")


def _fields(data):
    """Yield (field_number, raw_bytes, payload_or_None) for top-level fields."""
    pos = 0
    while pos < len(data):
        start = pos
        tag, pos = _read_varint(data, pos)
        payload = None
        if tag & 7 == 2:
            length, body = _read_varint(data, pos)
            payload = data[body:body + length]
        pos = _skip_value(data, pos, tag)
        yield tag >> 3, data[start:pos], payload


def get_table(config):
    for field, _, payload in _fields(config):
        if field == CUSTOM_ROMAN_TABLE:
            return payload.decode("utf-8")
    return None


def set_table(config, table):
    rest = b"".join(raw for field, raw, _ in _fields(config) if field != CUSTOM_ROMAN_TABLE)
    body = table.encode("utf-8")
    return rest + _varint((CUSTOM_ROMAN_TABLE << 3) | 2) + _varint(len(body)) + body


# --- main ------------------------------------------------------------------
def with_jj_rule(table, rule):
    lines = [line for line in table.splitlines() if line and not line.startswith("jj\t")]
    lines.append(rule)
    return "\n".join(lines) + "\n"


def jj_rule(table):
    for line in (table or DEFAULT_TABLE.read_text("utf-8")).splitlines():
        if line.startswith("jj\t"):
            return line.encode("unicode_escape").decode("ascii")
    return None


def restart_converter():
    # launchd が次の入力時に再起動し、新しい config1.db を読み込む。
    subprocess.run(["launchctl", "kickstart", "-k", f"gui/{os.getuid()}/{CONVERTER}"],
                   check=False, capture_output=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--remove", action="store_true", help="jj を標準ルールに戻す")
    group.add_argument("--status", action="store_true", help="現在の jj ルールを表示")
    args = parser.parse_args()

    if sys.platform != "darwin":
        sys.exit("macOS only")
    if not CONFIG.exists():
        sys.exit(f"Google日本語入力の設定が見つかりません: {CONFIG}")

    config = CONFIG.read_bytes()
    table = get_table(config)

    if args.status:
        print("custom table:", "yes" if table else "no (default)")
        print("jj rule:", jj_rule(table))
        return

    base = table or DEFAULT_TABLE.read_text("utf-8")
    new_table = with_jj_rule(base, JJ_DEFAULT if args.remove else JJ_ESC)
    if new_table == table:
        print("変更なし:", jj_rule(table))
        return

    backup = CONFIG.with_name(f"{CONFIG.name}.bak-{time.strftime('%Y%m%d-%H%M%S')}")
    shutil.copy2(CONFIG, backup)
    tmp = CONFIG.with_name(CONFIG.name + ".tmp")
    tmp.write_bytes(set_table(config, new_table))
    tmp.replace(CONFIG)
    restart_converter()
    print("backup:", backup)
    print("jj rule:", jj_rule(new_table))


if __name__ == "__main__":
    main()
