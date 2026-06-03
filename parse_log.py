import sys

def parse_log(filename):
    with open(filename, 'r', encoding='utf-16le') as f:
        lines = f.readlines()
    
    failures = []
    current_test = ""
    for i, line in enumerate(lines):
        if " [EXPECTED] " in line or " [ACTUAL] " in line or "FAILED:" in line:
            failures.append(lines[max(0, i-5):i+5])
            
    for fail in failures:
        print("--- FAILURE ---")
        print("".join(fail))

if __name__ == "__main__":
    parse_log('test_results.log')
