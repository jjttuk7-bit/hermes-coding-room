import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 price_with_tax.py <price> <tax_rate>")
        sys.exit(1)

    price = float(sys.argv[1])
    tax_rate = float(sys.argv[2])
    total = price * (1 + tax_rate / 100)

    if total.is_integer():
        print(int(total))
    else:
        print(total)


if __name__ == "__main__":
    main()
