#!/usr/bin/env python

import os
import re
import sys


def process_file(path, models_dir):
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    pattern = re.compile(r'local\s+(\w+)\s*=\s*class\(["\'].*?["\']')

    rel_path = os.path.relpath(path, models_dir)
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


def main(models_dir):
    for root, _, files in os.walk(models_dir):
        for fname in files:
            if fname.endswith(".lua"):
                process_file(os.path.join(root, fname), models_dir)


if __name__ == "__main__":
    if len(sys.argv) == 0:
        print("Provide a path to the models directory. Normally 'source/common/models'")

    models_dir = sys.argv[1]
    main(models_dir)
