#!/usr/bin/env python3
import sys
import re

def patch_file(file_path):
    # --- Step 1: Apply the sub-agent depth counter patch (text-based) ---
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Define the patterns for the sub-agent fix
    pattern_sub_agent_check = re.compile(r"if\s*\(\s*W\.name\s*===\s*k7\s*\)\s*return\s*!1\s*;?")
    pattern_sub_agent_logic = re.compile(r"let\s*\{\s*toolName\s*:\s*J\s*\}\s*=\s*VC\s*\(\s*W\s*\)\s*;\s*if\s*\(\s*J\s*===\s*k7\s*\)\s*\{\s*G\.push\(\s*W\s*\)\s*;\s*continue\s*\}")

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
    if re.search(pattern_sub_agent_check, content) and re.search(pattern_sub_agent_logic, content):
        content = re.sub(pattern_sub_agent_check, replacement_check, content)
        content = re.sub(pattern_sub_agent_logic, replacement_logic, content)
        sub_agent_patched = True

    # Write the text-based changes back to file
    with open(file_path, 'w', encoding='utf-8', errors='ignore') as f:
        f.write(content)

    # --- Step 2: Apply the welcome message patch (binary-based) ---
    with open(file_path, 'rb') as f:
        content_bytes = bytearray(f.read())

    # Find the end of the welcome message structure and add our message after it
    # Looking for the pattern: ," Welcome to ",PQ.createElement(T,{bold:!0},"Claude Code"),"!"
    original_pattern = b'," Welcome to ",PQ.createElement(T,{bold:!0},"Claude Code"),"!"'
    
    # Add our custom message right after the original welcome message
    # Use the same pattern as the original but without the star symbol
    custom_message = b',PQ.createElement(T,null," - I had strings, but now I\'m free")'
    
    welcome_patched = False
    offset = content_bytes.find(original_pattern)
    if offset != -1:
        # Insert our custom message right after the original pattern
        insert_position = offset + len(original_pattern)
        content_bytes[insert_position:insert_position] = custom_message
        welcome_patched = True

    # Write the binary changes back to file
    with open(file_path, 'wb') as f:
        f.write(content_bytes)

    print(f"Sub-agent patch applied: {sub_agent_patched}")
    print(f"Welcome message patch applied: {welcome_patched}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 patch.py <file_path>")
        sys.exit(1)
    
    patch_file(sys.argv[1])
