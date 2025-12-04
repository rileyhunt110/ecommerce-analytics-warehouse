import random
from datetime import date
from faker import Faker
import psycopg2

fake = Faker()

# -----------------------------
# DB connection config
# -----------------------------
DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "ecommerce_warehouse",
    "user": "postgres",
    "password": "Chowieman",
}


# -----------------------------
# Helper: get a DB connection
# -----------------------------
def get_connection():
    return psycopg2.connect(**DB_CONFIG)


# -----------------------------
# Seed dim_customer
# -----------------------------
def seed_customers(cur, n_customers=500):
    segments = ["Retail", "VIP", "Wholesale", "Employee"]

    for i in range(n_customers):
        first_name = fake.first_name()
        last_name = fake.last_name()
        customer_key = f"CUST-{i+1:05d}"

        email = f"{first_name.lower()}.{last_name.lower()}@{fake.free_email_domain()}"
        phone = fake.phone_number()
        created_date = fake.date_between(start_date="-4y", end_date="today")
        country = fake.country()
        # For simplicity, reuse city/region even if not perfect
        city = fake.city()
        region = fake.state_abbr() if hasattr(fake, "state_abbr") else ""
        postal_code = fake.postcode()
        segment = random.choice(segments)

        cur.execute(
            """
            INSERT INTO dim_customer (
                customer_key, first_name, last_name, email, phone,
                created_date, country, region, city, postal_code, segment
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                customer_key,
                first_name,
                last_name,
                email,
                phone,
                created_date,
                country,
                region,
                city,
                postal_code,
                segment,
            ),
        )


# -----------------------------
# Seed dim_product
# -----------------------------
def seed_products(cur, n_products=200):
    categories = {
        "Electronics": ["Phones", "Laptops", "Headphones", "Accessories"],
        "Home": ["Furniture", "Kitchen", "Decor"],
        "Fashion": ["Men", "Women", "Shoes", "Accessories"],
        "Sports": ["Outdoor", "Gym", "Team Sports"],
        "Toys": ["Board Games", "Educational", "Collectibles"],
    }

    brands = [
        "Acme",
        "Globex",
        "Initech",
        "Umbrella",
        "Stark",
        "Wayne Enterprises",
        "Wonka",
    ]

    product_counter = 1

    for category, subcats in categories.items():
        for subcat in subcats:
            for _ in range(n_products // (len(categories) * len(subcats)) + 1):
                sku = f"SKU-{product_counter:05d}"
                brand = random.choice(brands)
                product_name = f"{brand} {subcat} {product_counter}"
                list_price = round(random.uniform(10, 500), 2)
                # cost between 40–80% of list price
                cost = round(list_price * random.uniform(0.4, 0.8), 2)
                is_active = random.random() > 0.05  # ~5% inactive

                cur.execute(
                    """
                    INSERT INTO dim_product (
                        product_sku, product_name, brand, category,
                        subcategory, list_price, cost, is_active
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        sku,
                        product_name,
                        brand,
                        category,
                        subcat,
                        list_price,
                        cost,
                        is_active,
                    ),
                )

                product_counter += 1


# -----------------------------
# Helpers: lookup IDs from dims
# -----------------------------
def get_all_ids(cur, table, id_column):
    cur.execute(f"SELECT {id_column} FROM {table}")
    return [row[0] for row in cur.fetchall()]


def get_date_id_for_order(cur, order_date: date):
    cur.execute(
        """
        SELECT date_id
        FROM dim_date
        WHERE date_actual = %s
        """,
        (order_date,),
    )
    row = cur.fetchone()
    if not row:
        raise ValueError(f"No date_id found in dim_date for {order_date}")
    return row[0]


# -----------------------------
# Seed fact_order and fact_order_item
# -----------------------------
def seed_orders_and_items(cur, n_orders=3000, max_items_per_order=5):
    # Get dimension IDs we will sample from
    cur.execute("SELECT customer_id FROM dim_customer")
    customer_ids = [row[0] for row in cur.fetchall()]

    cur.execute(
        """
        SELECT product_id, list_price
        FROM dim_product
        WHERE is_active = TRUE
        """
    )
    products = [(pid, float(price)) for pid, price in cur.fetchall()]

    cur.execute("SELECT channel_id FROM dim_channel")
    channel_ids = [row[0] for row in cur.fetchall()]

    if not (customer_ids and products and channel_ids):
        raise RuntimeError("Need customers, products, and channels before seeding orders.")

    for i in range(n_orders):
        customer_id = random.choice(customer_ids)

        # random order date in dim_date range
        cur.execute(
            """
            SELECT date_actual
            FROM dim_date
            ORDER BY random()
            LIMIT 1
            """
        )
        order_date = cur.fetchone()[0]
        order_date_id = get_date_id_for_order(cur, order_date)

        channel_id = random.choice(channel_ids)

        order_number = f"ORD-{i+1:07d}"

        # order-level fields we will compute from items
        order_status = random.choices(
            ["Completed", "Completed", "Completed", "Cancelled", "Refunded"],
            weights=[80, 10, 5, 3, 2],
        )[0]

        # Insert fact_order first with placeholder money fields
        cur.execute(
            """
            INSERT INTO fact_order (
                order_number, customer_id, order_date_id, channel_id,
                order_status, order_subtotal, order_tax, order_shipping,
                order_discount, order_total
            )
            VALUES (%s, %s, %s, %s, %s, 0, 0, 0, 0, 0)
            RETURNING order_id
            """,
            (order_number, customer_id, order_date_id, channel_id, order_status),
        )
        order_id = cur.fetchone()[0]

        # Now create line items
        n_items = random.randint(1, max_items_per_order)
        line_subtotal_sum = 0
        line_discount_sum = 0

        for _ in range(n_items):
            product_id, list_price = random.choice(products)
            quantity = random.randint(1, 4)

            # actual unit price, with some randomness around list_price
            unit_price = round(list_price * random.uniform(0.7, 1.1), 2)

            # occasional discount
            if random.random() < 0.3:
                unit_discount = round(unit_price * random.uniform(0.05, 0.30), 2)
            else:
                unit_discount = 0.0

            line_subtotal = round(unit_price * quantity, 2)
            line_discount_total = round(unit_discount * quantity, 2)
            line_total = round(line_subtotal - line_discount_total, 2)

            line_subtotal_sum += line_subtotal
            line_discount_sum += line_discount_total

            cur.execute(
                """
                INSERT INTO fact_order_item (
                    order_id, product_id, quantity,
                    unit_price, unit_discount,
                    line_subtotal, line_discount_total, line_total
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    order_id,
                    product_id,
                    quantity,
                    unit_price,
                    unit_discount,
                    line_subtotal,
                    line_discount_total,
                    line_total,
                ),
            )

        # Simple order-level financials
        order_subtotal = round(line_subtotal_sum, 2)
        order_discount = round(line_discount_sum, 2)
        taxable_amount = max(order_subtotal - order_discount, 0)
        order_tax = round(taxable_amount * 0.08, 2)  # 8% tax
        order_shipping = round(random.choice([0, 0, 4.99, 9.99]), 2)
        order_total = round(taxable_amount + order_tax + order_shipping, 2)

        # Update the order record with computed amounts
        cur.execute(
            """
            UPDATE fact_order
            SET order_subtotal = %s,
                order_tax = %s,
                order_shipping = %s,
                order_discount = %s,
                order_total = %s
            WHERE order_id = %s
            """,
            (
                order_subtotal,
                order_tax,
                order_shipping,
                order_discount,
                order_total,
                order_id,
            ),
        )


def main():
    conn = get_connection()
    try:
        with conn:
            with conn.cursor() as cur:
                print("Seeding dim_customer...")
                seed_customers(cur, n_customers=500)

                print("Seeding dim_product...")
                seed_products(cur, n_products=200)

                print("Seeding fact_order and fact_order_item...")
                seed_orders_and_items(cur, n_orders=3000, max_items_per_order=5)

        print("Data generation complete.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
