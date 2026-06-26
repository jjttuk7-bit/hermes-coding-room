import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 profit_calc.py <revenue> <cost>")
        sys.exit(1)

    revenue = int(sys.argv[1])
    cost = int(sys.argv[2])

    print(revenue - cost)


if __name__ == "__main__":
    main()
