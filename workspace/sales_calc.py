import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 workspace/sales_calc.py <price> <quantity>")
        sys.exit(1)

    price = float(sys.argv[1])
    quantity = int(sys.argv[2])
    total = price * quantity

    if total.is_integer():
        print(int(total))
    else:
        print(total)


if __name__ == "__main__":
    main()
