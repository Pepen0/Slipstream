import argparse
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

DEFAULT_COLS = [
    "speed_kmh","rpm","gear","gas","brake","steer",
    "ax_g","ay_g","az_g","lap","pos"
]

def main():
    ap = argparse.ArgumentParser(description="Plot selected columns from a Parquet telemetry file")
    ap.add_argument("parquet", type=Path, help="Path to .parquet file")
    ap.add_argument("--cols", "-c", nargs="*", default=DEFAULT_COLS, help="Columns to plot vs time")
    ap.add_argument("--limit", "-n", type=int, help="Optional row limit for quick plotting")
    args = ap.parse_args()

    df = pd.read_parquet(args.parquet)
    if args.limit:
        df = df.head(args.limit)

    # Build time axis in seconds if t_ns exists
    x = None
    if "t_ns" in df.columns:
        t0 = df["t_ns"].min()
        df = df.assign(t_s=(df["t_ns"] - t0) / 1e9)
        x = "t_s"

    cols = [c for c in args.cols if c in df.columns]
    if not cols:
        print("No requested columns present; available:", list(df.columns))
        return

    for col in cols:
        ax = df.plot(x=x, y=col, legend=False, title=col)
        ax.set_xlabel("t (s)" if x == "t_s" else "index")
        ax.set_ylabel(col)
        plt.show()

if __name__ == "__main__":
    main()
