import sys


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 discount.py <price> <discount_rate>")
        sys.exit(1)

    price = float(sys.argv[1])
    discount_rate = float(sys.argv[2])
    discounted_price = price * (1 - discount_rate / 100)

    print(int(discounted_price))


if __name__ == "__main__":
    main()
