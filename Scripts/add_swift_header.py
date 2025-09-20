import os
import re
from datetime import datetime

def get_swift_files(directories):
    """Find all Swift files in the given directories."""
    swift_files = []
    for directory in directories:
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(".swift"):
                    swift_files.append(os.path.join(root, file))
    return swift_files

def create_header(file_path, author="Yiming Liao"):
    """Create the file header content with the correct date format and period."""
    file_name = os.path.basename(file_path)
    # Match the format M/d/yy without leading zeros for month/day
    date = datetime.now().strftime("%-m/%-d/%y")
    header = (
        f"//\n"
        f"//  {file_name}\n"
        f"//  NotBad\n"
        f"//\n"
        f"//  Created by {author} on {date}.\n"
        f"//"
    )
    return header

def strip_all_leading_comments(content):
    """Remove all comment blocks from the beginning of the file."""
    # This pattern will find any sequence of comment lines (//) and blank lines
    # at the very start of the file content.
    pattern = re.compile(r"^((\s*//.*\n|\s*\n)*)", re.MULTILINE)
    
    # Find where the header/comment block ends
    match = pattern.search(content)
    if match:
        # The actual code starts after the matched block
        start_of_code = match.end()
        return content[start_of_code:]
    
    # If no leading comments are found, return the content as is
    return content

def main():
    """Main function to replace headers and ensure a single trailing newline."""
    workspace_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    source_dirs = [
        os.path.join(workspace_root, "NotBad"),
        os.path.join(workspace_root, "NotBadTests"),
        os.path.join(workspace_root, "NotBadUITests")
    ]
    
    swift_files = get_swift_files(source_dirs)
    files_fixed = 0

    print(f"Checking {len(swift_files)} Swift files for header and newline issues...")

    for file_path in swift_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()

            # 1. Create the correct new header.
            new_header = create_header(file_path)

            # 2. Strip ALL leading comment blocks from the original content.
            content_without_header = strip_all_leading_comments(original_content)

            # 3. Combine the new header with the code.
            new_content = new_header + "\n\n" + content_without_header.lstrip()

            # 4. Ensure the file ends with exactly one trailing newline.
            new_content = new_content.rstrip() + "\n"

            # 5. Write the changes back only if the content has changed.
            if new_content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"✅ Fixed header/newline for {os.path.basename(file_path)}")
                files_fixed += 1
                
        except Exception as e:
            print(f"❌ Error processing {file_path}: {e}")

    if files_fixed == 0:
        print("\n✅ No files needed fixing. All headers and newlines appear to be correct.")
    else:
        print(f"\nHeader and newline correction process complete. Fixed {files_fixed} files.")

if __name__ == "__main__":
    main()


