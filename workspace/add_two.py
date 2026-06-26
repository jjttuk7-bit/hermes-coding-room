import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 workspace/add_two.py <int1> <int2>")
        sys.exit(1)

    first = int(sys.argv[1])
    second = int(sys.argv[2])
    print(first + second)


if __name__ == "__main__":
    main()
