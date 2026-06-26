import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 workspace/divide.py <number1> <number2>")
        sys.exit(1)

    first = float(sys.argv[1])
    second = float(sys.argv[2])
    print(first / second)


if __name__ == "__main__":
    main()
