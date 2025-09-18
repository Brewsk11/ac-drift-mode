#!/usr/bin/env python

import os
import re

MODELS_DIR = "lua_libs/drift-mode/models"


def process_file(path):
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    pattern = re.compile(r'local\s+(\w+)\s*=\s*class\(".*?"')

    rel_path = os.path.relpath(path, MODELS_DIR)
    model_path = os.path.splitext(rel_path)[0]
    model_path = model_path.replace(os.sep, ".")

    new_lines = []

    for line in lines:
        # Skip any existing __model_path assignments so they get overwritten.
        if re.search(r"\.\__model_path\b", line):
            continue

        new_lines.append(line)

        # After a class declaration, insert the updated path assignment.
        match = pattern.search(line)
        if match:
            class_name = match.group(1)
            new_lines.append(f'{class_name}.__model_path = "{model_path}"\n')

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)


def main():
    for root, _, files in os.walk(MODELS_DIR):
        for fname in files:
            if fname.endswith(".lua"):
                process_file(os.path.join(root, fname))


if __name__ == "__main__":
    main()
