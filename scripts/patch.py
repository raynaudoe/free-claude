#!/usr/bin/env python3
import sys
import re

def patch_file(file_path):
    # --- Step 1: Apply the sub-agent depth counter patch (text-based) ---
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Check if sub-agent patch is already applied
    sub_agent_already_patched = 'globalThis.__TASK_DEPTH__' in content
    
    # Define the patterns for the sub-agent fix (handle both minified and non-minified)
    # Pattern 1: Check for W.name === k7
    pattern_sub_agent_check = re.compile(r"if\s*\(\s*W\.name\s*===\s*k7\s*\)\s*return\s*!1\s*;?")
    # Also try minified version
    pattern_sub_agent_check_min = re.compile(r"if\(W\.name===k7\)return!1;?")
    
    # Pattern 2: The logic for pushing to G
    # Note: The function name might be CC or VC depending on the build
    pattern_sub_agent_logic = re.compile(r"let\s*\{\s*toolName\s*:\s*J\s*\}\s*=\s*[A-Z]{2}\s*\(\s*W\s*\)\s*;\s*if\s*\(\s*J\s*===\s*k7\s*\)\s*\{\s*G\.push\s*\(\s*W\s*\)\s*;\s*continue\s*\}")
    # Also try minified version
    pattern_sub_agent_logic_min = re.compile(r"let\{toolName:J\}=[A-Z]{2}\(W\);if\(J===k7\)\{G\.push\(W\);continue\}")

    # Define the replacements with the depth counter logic
    replacement_check = "if (W.name === k7 && (globalThis.__TASK_DEPTH__ || 0) >= 2) return !1;"
    replacement_logic = """
    let { toolName: J } = VC(W);
    if (J === k7) {
        if (!globalThis.hasOwnProperty('__TASK_DEPTH__')) {
            globalThis.__TASK_DEPTH__ = 0;
        }
        const original_run = W.run;
        W.run = async (...args) => {
            try {
                globalThis.__TASK_DEPTH__++;
                return await original_run(...args);
            } finally {
                globalThis.__TASK_DEPTH__--;
            }
        };
        G.push(W);
    } else {
        G.push(W);
    }
    continue;
    """

    sub_agent_patched = False
    sub_agent_details = []
    
    if sub_agent_already_patched:
        print("✓ Sub-agent patch: Already applied")
        sub_agent_patched = "already applied"
    else:
        # Check pattern availability
        check_found = re.search(pattern_sub_agent_check, content) or re.search(pattern_sub_agent_check_min, content)
        logic_found = re.search(pattern_sub_agent_logic, content) or re.search(pattern_sub_agent_logic_min, content)
        
        print("Sub-agent patch patterns:")
        print(f"  • Task check pattern (W.name===k7): {'✓ FOUND' if check_found else '✗ NOT FOUND'}")
        print(f"  • Task logic pattern (toolName/push): {'✓ FOUND' if logic_found else '✗ NOT FOUND'}")
        
        # Try non-minified patterns first
        if re.search(pattern_sub_agent_check, content) and re.search(pattern_sub_agent_logic, content):
            content = re.sub(pattern_sub_agent_check, replacement_check, content)
            content = re.sub(pattern_sub_agent_logic, replacement_logic, content)
            sub_agent_patched = True
            print("  → Applied: Non-minified patterns")
        # Try minified patterns
        elif re.search(pattern_sub_agent_check_min, content) and re.search(pattern_sub_agent_logic_min, content):
            # For minified version, we need minified replacements
            replacement_check_min = "if(W.name===k7&&(globalThis.__TASK_DEPTH__||0)>=2)return!1;"
            replacement_logic_min = "let{toolName:J}=CC(W);if(J===k7){if(!globalThis.hasOwnProperty('__TASK_DEPTH__')){globalThis.__TASK_DEPTH__=0;}const original_run=W.run;W.run=async(...args)=>{try{globalThis.__TASK_DEPTH__++;return await original_run(...args);}finally{globalThis.__TASK_DEPTH__--;}};G.push(W);}else{G.push(W);}continue;"
            content = re.sub(pattern_sub_agent_check_min, replacement_check_min, content)
            content = re.sub(pattern_sub_agent_logic_min, replacement_logic_min, content)
            sub_agent_patched = True
            print("  → Applied: Minified patterns")
        else:
            print("  → Failed: Patterns not found or incomplete")

    # Write the text-based changes back to file
    with open(file_path, 'w', encoding='utf-8', errors='ignore') as f:
        f.write(content)

    # --- Step 2: Apply the welcome message patch (binary-based) ---
    with open(file_path, 'rb') as f:
        content_bytes = bytearray(f.read())

    # Check if welcome message patch is already applied
    custom_message = b',PQ.createElement(T,null," - I had strings, but now I\'m free")'
    welcome_already_patched = custom_message in content_bytes
    
    # Find the end of the welcome message structure and add our message after it
    # Looking for the pattern: ," Welcome to ",PQ.createElement(T,{bold:!0},"Claude Code"),"!"
    original_pattern = b'," Welcome to ",PQ.createElement(T,{bold:!0},"Claude Code"),"!"'
    
    welcome_patched = False
    if welcome_already_patched:
        print("✓ Welcome message patch: Already applied")
        welcome_patched = "already applied"
    else:
        offset = content_bytes.find(original_pattern)
        print("Welcome message patch:")
        print(f"  • Pattern 'Claude Code': {'✓ FOUND' if offset != -1 else '✗ NOT FOUND'}")
        
        if offset != -1:
            # Insert our custom message right after the original pattern
            insert_position = offset + len(original_pattern)
            content_bytes[insert_position:insert_position] = custom_message
            welcome_patched = True
            print("  → Applied: Welcome message added")
        else:
            print("  → Failed: Pattern not found")

    # Write the binary changes back to file
    with open(file_path, 'wb') as f:
        f.write(content_bytes)

    # Final summary
    print("\n===== PATCH SUMMARY =====")
    if sub_agent_patched == "already applied" and welcome_patched == "already applied":
        print("✓ All patches already applied")
    elif sub_agent_patched and welcome_patched:
        print("✓ All patches successfully applied")
    else:
        if sub_agent_patched == "already applied" or sub_agent_patched:
            print(f"✓ Sub-agent recursion: {'Already applied' if sub_agent_patched == 'already applied' else 'SUCCESS'}")
        else:
            print("✗ Sub-agent recursion: FAILED")
        
        if welcome_patched == "already applied" or welcome_patched:
            print(f"✓ Welcome message: {'Already applied' if welcome_patched == 'already applied' else 'SUCCESS'}")
        else:
            print("✗ Welcome message: FAILED")
    
    # Return exit code based on success
    if (sub_agent_patched or sub_agent_patched == "already applied") and \
       (welcome_patched or welcome_patched == "already applied"):
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 patch.py <file_path>")
        sys.exit(1)
    
    patch_file(sys.argv[1])
