import os
import re
import shutil

def rename_content(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        new_content = content.replace('SnapDrill', 'SnapDrill')
        new_content = new_content.replace('snapdrill', 'snapdrill')
        new_content = new_content.replace('SNAPDRILL', 'SNAPDRILL')
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
    except Exception as e:
        print(f"Skipping content of {file_path}: {e}")

def rename_path(old_path):
    dirname, basename = os.path.split(old_path)
    new_basename = basename.replace('SnapDrill', 'SnapDrill').replace('snapdrill', 'snapdrill')
    if new_basename != basename:
        new_path = os.path.join(dirname, new_basename)
        os.rename(old_path, new_path)
        return new_path
    return old_path

def process_directory(root_dir):
    # First rename contents
    for root, dirs, files in os.walk(root_dir):
        if '.git' in root or '.build' in root or 'build' in root.split(os.sep):
            continue
        for file in files:
            if file == '.DS_Store' or file.endswith('.png') or file.endswith('.jpg'):
                continue
            file_path = os.path.join(root, file)
            rename_content(file_path)

    # Then rename files and directories bottom-up
    for root, dirs, files in os.walk(root_dir, topdown=False):
        if '.git' in root or '.build' in root or 'build' in root.split(os.sep):
            continue
        for file in files:
            file_path = os.path.join(root, file)
            rename_path(file_path)
        for d in dirs:
            dir_path = os.path.join(root, d)
            rename_path(dir_path)

if __name__ == '__main__':
    process_directory('.')
    print("Renaming complete.")
