import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine
import time


# ==== settings ====
BASE = Path(__file__).resolve().parent.parent
DIRTY = BASE / "data" / "dirty"
SCHEMA = "raw"

load_dotenv(BASE / ".env")
DB_URL = os.getenv("DB_URL")


# cleaning naming of datasets
# example: olist_customers_dataset -> customers
def table_name(file: Path) -> str:
    return file.stem.removeprefix("olist_").removesuffix("_dataset")


# loads one csv into the raw schema as text and returns number of rows
def load_file(file: Path, engine) -> int:
    df = pd.read_csv(file, dtype=str)
    df.to_sql(
        table_name(file),
        engine,
        schema=SCHEMA,
        if_exists="replace",
        index=False,
        chunksize=10_1000,
    )
    return len(df)


def main():
    if not DB_URL:
        raise SystemExit("Missing DB_URL in .env")
    
    files = sorted(DIRTY.glob("*csv"))
    if not files:
        raise SystemExit(f"No CSV files in {DIRTY}. Run break_data.py first")

    engine = create_engine(DB_URL)

    for file in files:
        start = time.time()
        rows = load_file(file, engine)
        print(f"{table_name(file):<35} {rows:>10} rows ({time.time() - start:.1f}s)")

    print("Raw data loaded")

if __name__ == "__main__":
    main()