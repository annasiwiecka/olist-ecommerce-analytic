import json
import pandas as pd
import shutil
from pathlib import Path

SEED = 42 

BASE = Path(__file__).resolve().parent.parent      

SRC = str(BASE / "data" / "original") + "/"
DST = str(BASE / "data" / "dirty") + "/"

DOCS = BASE / "docs"
DOCS.mkdir(exist_ok=True)

log = {}


# ===== products -> lack in categories (10%) =====
products = pd.read_csv(SRC + "olist_products_dataset.csv", dtype=str)

idx = products.sample(frac=0.1, random_state=SEED).index 
products.loc[idx, "product_category_name"] = None

log["product_category_name_missing"] = len(idx)
products.to_csv(DST + "olist_products_dataset.csv", index=False)


# ===== customers -> inconsistent size of the letters in cities (10%) =====
customers = pd.read_csv(SRC + "olist_customers_dataset.csv", dtype=str)

idx = customers.sample(frac=0.10, random_state=SEED).index
half = idx[: len(idx) // 2]
rest = idx[len(idx) // 2 :]

customers.loc[half, "customer_city"] = customers.loc[half, "customer_city"].str.upper()
customers.loc[rest, "customer_city"] = customers.loc[rest, "customer_city"].str.title()

log["customer_case_changed"] = len(idx)
customers.to_csv(DST + "olist_customers_dataset.csv", index=False)


# ===== orders -> orphans, duplicates, mixed date formats =====
orders = pd.read_csv(SRC + "olist_orders_dataset.csv", dtype=str)

# deleting 200 orders from orders, but order_time stays

dropped = orders.sample(n=200, random_state=SEED)
orders = orders.drop(dropped.index)
log["orders_deleted_orphans"] = dropped["order_id"].tolist()

# duplicates, copying 1% rows

dups = orders.sample(frac=0.01, random_state=SEED)
orders = pd.concat([orders, dups], ignore_index=True)
log["orders_duplicates"] = len(dups)

# mixed date formats: 10% from ISO to DD/MM/YYYY

col = "order_purchase_timestamp"
idx = orders.sample(frac=0.1, random_state=SEED).index
parsed = pd.to_datetime(orders.loc[idx, col], errors="coerce")
orders.loc[idx, col] = parsed.dt.strftime("%d/%m/%Y %H:%M") 
log["orders_date_format_changed"] = len(idx)

orders.to_csv(DST + "olist_orders_dataset.csv", index=False)

# ==== order items -> negative prices ===
items = pd.read_csv(SRC + "olist_order_items_dataset.csv", dtype=str)

idx = items.sample(n=20, random_state=SEED).index
items.loc[idx, "price"] = "-" + items.loc[idx, "price"]

log["order_items_negative_price"] = len(idx)
items.to_csv(DST + "olist_order_items_dataset.csv", index=False)

# ===== untouched files -> copied as they are =====
untouched = [
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_sellers_dataset.csv",
    "olist_geolocation_dataset.csv",
    "product_category_name_translation.csv",
]

for name in untouched:
    shutil.copy(SRC + name, DST + name)

# ==== answer key ====
with open(DOCS / "_answer_key.json", "w") as f:
    json.dump(log, f, indent=2)

print("Damage summary:")
for key, value in log.items():
    print(key, "->", len(value) if isinstance(value, list) else value)