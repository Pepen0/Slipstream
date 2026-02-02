import argparse
from pathlib import Path
import pandas as pd

def main():
    ap = argparse.ArgumentParser(description="Console viewer for out.parquet")
    ap.add_argument("parquet", type=Path, help="Path to .parquet file")
    ap.add_argument("--limit", "-n", type=int, default=50, help="Rows to print")
    ap.add_argument("--columns", "-c", nargs="*", help="Subset of columns to display")
    ap.add_argument("--to-csv", type=Path, help="Optional CSV export path")
    args = ap.parse_args()

    df = pd.read_parquet(args.parquet)

    if "t_ns" in df.columns:
        t0 = df["t_ns"].min()
        df = df.assign(t_s=(df["t_ns"] - t0) / 1e9)

    cols = args.columns if args.columns else df.columns.tolist()
    cols = [c for c in cols if c in df.columns]

    print("Columns:", list(df.columns))
    print()
    print(df[cols].head(args.limit).to_string(index=False))
    print()
    print(df.describe(include="all").transpose())

    if args.to_csv:
        df.to_csv(args.to_csv, index=False)
        print(f"Wrote {args.to_csv}")

if __name__ == "__main__":
    main()
