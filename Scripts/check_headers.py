#!/usr/bin/env python3
import os
import re
import sys

def check_header(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Define the expected header pattern
    # 1. Start with //
    # 2. Key fields: Filename, Created by, Copyright
    # 3. Last part: Chinese description (unicode range \u4e00-\u9fa5)
    
    # Simple check:
    # Look for the structure. 
    # We expect the last line of the header block to contain Chinese characters.
    
    lines = content.split('\n')
    if len(lines) < 7:
        return False, "Header too short"
        
    if not lines[0].startswith('//'):
        return False, "Does not start with //"
        
    # Find the end of the header block (first empty line or import)
    header_end_index = 0
    for i, line in enumerate(lines):
        if i > 0 and (line.strip() == '' or line.startswith('import ')):
            header_end_index = i
            break
            
    header_lines = lines[:header_end_index]
    
    # Check for basic required fields
    header_text = '\n'.join(header_lines)
    if "Created by" not in header_text:
        return False, "Missing 'Created by'"
    if "Copyright" not in header_text:
        return False, "Missing 'Copyright'"
        
    # Check for Chinese description
    # We look for at least one line in the header that contains Chinese characters
    has_chinese = False
    chinese_pattern = re.compile(r'[\u4e00-\u9fa5]')
    for line in header_lines:
        if chinese_pattern.search(line):
            has_chinese = True
            break
            
    if not has_chinese:
        return False, "Missing Chinese description"
        
    return True, "OK"

def main():
    root_dir = os.getcwd()
    failed_files = []
    
    for root, dirs, files in os.walk(root_dir):
        # Skip hidden directories and build artifacts
        if '/.' in root or '/DerivedData' in root or '/build' in root:
            continue
            
        for file in files:
            if file.endswith(".swift"):
                file_path = os.path.join(root, file)
                success, reason = check_header(file_path)
                if not success:
                    failed_files.append((file_path, reason))
                    print(f"[FAIL] {file_path}: {reason}")
    
    if failed_files:
        print(f"\nFound {len(failed_files)} files with invalid headers.")
        sys.exit(1)
    else:
        print("\nAll files have valid headers.")
        sys.exit(0)

if __name__ == "__main__":
    main()
