import sys

if len(sys.argv) < 2:
    print("사용법: python3 workspace/greet.py 이름")
    sys.exit(1)

name = sys.argv[1]
print(f"Hello, {name}!")
