#!/usr/bin/env python3

import argparse
import math
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

try:
    import matplotlib.pyplot as plt
except ModuleNotFoundError:
    plt = None


RESULT_LINE_RE = re.compile(r"^(?:PASS|FAIL):\s+(.+?)\s+IPC=([^\s]+)")
AVG_LINE_RE = re.compile(r"^Average IPC over \d+ tests:\s+([^\s]+)")


def parse_ipc(value):
    if value == "N/A":
        return math.nan
    return float(value)


def benchmark_name(test_path):
    path = Path(test_path)
    if len(path.parts) >= 2:
        return path.parts[-2]
    return path.stem


def parse_results_file(results_file):
    ipc_by_benchmark = {}
    average_ipc = math.nan

    with results_file.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()

            result_match = RESULT_LINE_RE.match(line)
            if result_match:
                bench = benchmark_name(result_match.group(1))
                ipc_by_benchmark[bench] = parse_ipc(result_match.group(2))
                continue

            avg_match = AVG_LINE_RE.match(line)
            if avg_match:
                average_ipc = parse_ipc(avg_match.group(1))

    if not ipc_by_benchmark:
        raise ValueError(f"{results_file} did not contain any benchmark IPC lines")

    ipc_by_benchmark["Average"] = average_ipc
    return ipc_by_benchmark


def ordered_benchmarks(all_results):
    seen = []
    for result in all_results:
        for bench in result:
            if bench != "Average" and bench not in seen:
                seen.append(bench)
    return seen + ["Average"]


def gnuplot_quote(value):
    return "'" + str(value).replace("\\", "\\\\").replace("'", "\\'") + "'"


def write_gnuplot_data(data_file, benchmarks, labels, all_results):
    with data_file.open("w", encoding="utf-8") as f:
        f.write("Benchmark\t" + "\t".join(labels) + "\n")
        for bench in benchmarks:
            values = []
            for result in all_results:
                value = result.get(bench, math.nan)
                values.append("NaN" if math.isnan(value) else f"{value:.6f}")
            f.write(bench + "\t" + "\t".join(values) + "\n")


def plot_with_matplotlib(benchmarks, labels, all_results, output_file):
    x_positions = list(range(len(benchmarks)))
    group_width = 0.82
    bar_width = group_width / len(all_results)
    start_offset = -group_width / 2 + bar_width / 2

    fig_width = max(12, len(benchmarks) * 0.8)
    fig, ax = plt.subplots(figsize=(fig_width, 6.5))

    for result_index, (label, result) in enumerate(zip(labels, all_results)):
        offsets = [
            x + start_offset + result_index * bar_width
            for x in x_positions
        ]
        values = [result.get(bench, math.nan) for bench in benchmarks]
        ax.bar(offsets, values, width=bar_width, label=label)

    ax.set_title("IPC by Benchmark")
    ax.set_xlabel("Benchmark")
    ax.set_ylabel("IPC")
    ax.set_xticks(x_positions)
    ax.set_xticklabels(benchmarks, rotation=35, ha="right")
    ax.grid(axis="y", linestyle="--", alpha=0.35)
    ax.legend()

    ymax = max(
        value
        for result in all_results
        for value in result.values()
        if not math.isnan(value)
    )
    ax.set_ylim(0, ymax * 1.15)

    fig.tight_layout()
    fig.savefig(output_file, dpi=180)
    plt.close(fig)


def plot_with_gnuplot(benchmarks, labels, all_results, output_file):
    gnuplot = shutil.which("gnuplot")
    if gnuplot is None:
        raise RuntimeError(
            "matplotlib is not installed and gnuplot was not found in PATH"
        )

    with tempfile.TemporaryDirectory() as tmpdir:
        data_file = Path(tmpdir) / "ipc_data.tsv"
        script_file = Path(tmpdir) / "plot_ipc.gnuplot"
        write_gnuplot_data(data_file, benchmarks, labels, all_results)

        script_file.write_text(
            "\n".join(
                [
                    "set terminal pngcairo size 1800,900 enhanced font 'Arial,12'",
                    f"set output {gnuplot_quote(output_file)}",
                    "set title 'IPC by Benchmark'",
                    "set xlabel 'Benchmark'",
                    "set ylabel 'IPC'",
                    "set style data histograms",
                    "set style histogram clustered gap 1",
                    "set style fill solid border -1",
                    "set boxwidth 0.85",
                    "set grid ytics",
                    "set key outside right top",
                    "set xtics rotate by -35",
                    "set yrange [0:*]",
                    (
                        "plot for [COL=2:"
                        f"{len(labels) + 1}] {gnuplot_quote(data_file)} "
                        "using COL:xtic(1) title columnheader"
                    ),
                    "",
                ]
            ),
            encoding="utf-8",
        )

        subprocess.run([gnuplot, str(script_file)], check=True)


def plot_ipc_results(results_files, output_file, labels):
    all_results = [parse_results_file(path) for path in results_files]
    benchmarks = ordered_benchmarks(all_results)

    output_file.parent.mkdir(parents=True, exist_ok=True)
    if plt is not None:
        plot_with_matplotlib(benchmarks, labels, all_results, output_file)
    else:
        plot_with_gnuplot(benchmarks, labels, all_results, output_file)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate a grouped IPC bar graph from performance result files."
    )
    parser.add_argument(
        "results_files",
        nargs="+",
        type=Path,
        help="Performance result files, for example sim_results/baseline.txt.",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("ipc_bar_graph.png"),
        help="Output image path. Defaults to ipc_bar_graph.png.",
    )
    parser.add_argument(
        "--labels",
        nargs="+",
        help="Optional legend labels. Must match the number of result files.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if args.labels is not None and len(args.labels) != len(args.results_files):
        raise SystemExit("--labels must have the same number of entries as results_files")

    labels = args.labels
    if labels is None:
        labels = [path.stem for path in args.results_files]

    plot_ipc_results(args.results_files, args.output, labels)
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
