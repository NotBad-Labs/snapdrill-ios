
import re
import sys

FILE_PATH = "NotBad.xcodeproj/project.pbxproj"

# IDS for new package
PKG_ID = "AG_PKG_FEATURES"
PROD_ID = "AG_PROD_FEATURES"
BUILD_ID = "AG_BF_FEATURES"

# Obsolete keys to look for (based on the previous view_file output we saw)
# We will match them by their comment names or path patterns because IDs might vary if I didn't read all lines
# But we saw IDs like B2PKG_FEAT_CAPTURE. 
# Better strategy: Find lines containing the distinct names and remove them from specific lists.

OBSOLETE_NAMES = [
    "NotBadFeatureCapture",
    "NotBadFeatureDashboard",
    "NotBadFeatureLibrary",
    "NotBadFeatureReview",
    "NotBadFeatureSettings",
    "NotBadEngine",
    "NotBadService"
    # NotBadUtils and NotBadSupport were not seen in the top-level references, so maybe they were transitive.
]

def update_pbxproj():
    with open(FILE_PATH, "r") as f:
        content = f.read()

    # 1. Add Objects
    
    # XCLocalSwiftPackageReference
    pkg_def = f'\t\t{PKG_ID} /* NotBadFeatures */ = {{isa = XCLocalSwiftPackageReference; relativePath = Packages/NotBadFeatures; }};\n'
    content = re.sub(r'(\/\* Begin XCLocalSwiftPackageReference section \*/\n)', r'\1' + pkg_def, content)

    # XCSwiftPackageProductDependency
    prod_def = f'\t\t{PROD_ID} /* NotBadFeatures */ = {{isa = XCSwiftPackageProductDependency; package = {PKG_ID} /* NotBadFeatures */; productName = NotBadFeatures; }};\n'
    content = re.sub(r'(\/\* Begin XCSwiftPackageProductDependency section \*/\n)', r'\1' + prod_def, content)

    # PBXBuildFile
    bf_def = f'\t\t{BUILD_ID} /* NotBadFeatures in Frameworks */ = {{isa = PBXBuildFile; productRef = {PROD_ID} /* NotBadFeatures */; }};\n'
    content = re.sub(r'(\/\* Begin PBXBuildFile section \*/\n)', r'\1' + bf_def, content)

    # 2. Update Arrays (Remove old, Add new)
    
    lines = content.splitlines()
    new_lines = []
    
    # State tracking
    in_native_target = False
    in_project = False
    in_frameworks_phase = False
    
    # Using simple line iteration to handle the nested arrays
    iterator = iter(lines)
    for line in iterator:
        
        # Check for start of relevant sections
        if "isa = PBXNativeTarget;" in line and "NotBad" in line: # Main target
            # Ideally we find the start of the section 
            pass 
        
        # Strategy: regex replacement on the whole file might be safer for removal?
        # Let's try line filtering.
        
        should_remove = False
        for name in OBSOLETE_NAMES:
            if name in line and ("XCLocalSwiftPackageReference" in line or "XCSwiftPackageProductDependency" in line or "PBXBuildFile" in line):
                 # This removes the definitions in the Objects section
                 name_check = f"/* {name} "
                 if name_check in line or f" {name} */" in line:
                     should_remove = True
                     break
        
        if should_remove:
            continue
            
        # Updating Reference Lists
        
        # PBXFrameworksBuildPhase -> files
        if "files = (" in line and "frameworks" not in line.lower(): # Basic heuristic
             # We are inside a files array.
             # Check if we are in the right build phase. 
             # The file has comments /* Frameworks */.
             pass
        
        # Let's use a simpler regex approach for the lists.
        # Find the specific sections blocks by ID if possible, but IDs are unknown for some.
        # But we know the Structure.
        
        new_lines.append(line)
        
    # Re-assemble for Regex processing
    content = "\n".join(new_lines)
    
    # 3. Clean up Lists
    # Remove lines from 'files', 'packageReferences', 'packageProductDependencies' containing the obsolete names
    # and Insert the new ID.
    
    # Function to inject into specific list
    def inject_into_list(block_header_regex, list_name, new_entry_line):
        # Find the block
        # Look for: isa = ...; ... list_name = ( ... );
        # This is hard with regex due to newlines.
        pass

    # Alternative: Just replace the known dead lines if they survived?
    # No, we skipped definitions. Now we skip references.
    
    filtered_lines = []
    for line in content.splitlines():
        # Removal logic for list items
        if any(name in line for name in OBSOLETE_NAMES):
            # Only remove if it looks like a list item or reference
            if ";" in line or "," in line:
                continue
        filtered_lines.append(line)
    
    content = "\n".join(filtered_lines)

    # 4. Insert New References
    
    # Find PBXProject packageReferences (Only one PBXProject usually)
    # The view_file showed: rootObject = ...
    # packageReferences = ( ... )
    
    if "packageReferences = (" in content:
        # Regex substitute the end of list
        content = content.replace("packageReferences = (", f"packageReferences = (\n\t\t\t\t{PKG_ID} /* NotBadFeatures */,", 1)
        
    # Find PBXNativeTarget "NotBad" packageProductDependencies
    # We look for: isa = PBXNativeTarget; ... name = NotBad; ... packageProductDependencies = (
    # This matches the target definition.
    # Note: Regex needs to match across lines.
    
    match_target = re.search(r'(isa = PBXNativeTarget;.*?name = NotBad;.*?packageProductDependencies = \()', content, re.DOTALL)
    if match_target:
        span = match_target.span(1)
        # Insert after the opening parenthesis
        content = content[:span[1]] + f"\n\t\t\t\t{PROD_ID} /* NotBadFeatures */," + content[span[1]:]

    # Find PBXFrameworksBuildPhase
    # Look for the one that already had items (we removed them but the empty lines or section remains)
    # Identify by "isa = PBXFrameworksBuildPhase" and file list containing typical items?
    # Or just look for the first non-empty one?
    # The file showed: B27BD95C... /* Frameworks */ = { ... files = ( ... ) }
    
    # We can try to insert into ANY Frameworks build phase files list that looks like the main one.
    # The main one usually comes first or has specific comment.
    # Regex: isa = PBXFrameworksBuildPhase;.*?files = \(
    
    match_frameworks = re.search(r'(isa = PBXFrameworksBuildPhase;.*?files = \()', content, re.DOTALL)
    if match_frameworks:
        span = match_frameworks.span(1)
        content = content[:span[1]] + f"\n\t\t\t\t{BUILD_ID} /* NotBadFeatures in Frameworks */," + content[span[1]:]

    with open(FILE_PATH, "w") as f:
        f.write(content)

if __name__ == "__main__":
    update_pbxproj()
