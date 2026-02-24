import os
import re

def update_headers(directory):
    count = 0
    # Match patterns like: //  Created by Yiming Liao on 2025/12/31.
    created_pattern = re.compile(r'(//\s*Created by\s+).*?(\s+on\s+.*)')
    # Match patterns like: //  Copyright © 2025 NotBad. All rights reserved.
    copyright_pattern = re.compile(r'(//\s*Copyright\s+.*?\s+).*?(\s+All rights reserved.*)')
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.swift'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace logic
                # For "Created by", we replace the middle part with "NotBad Labs"
                new_content = created_pattern.sub(r'\1NotBad Labs\2', content)
                
                # For Copyright, we standardize to "Copyright © 2026 NotBad Labs L.L.C. All rights reserved."
                # It might not have a copyright line yet. Let's handle lines that already exist.
                # Actually, Xcode defaults usually put copyright on line 7. If it's missing we won't add it for now, just replace existing.
                new_content = re.sub(r'//\s*Copyright\s+©.*', r'//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.', new_content)
                
                if new_content != content:
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    count += 1
    
    print(f"Updated {count} files.")

update_headers('.')
