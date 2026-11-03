"""Convert a user-downloaded NIST ASD CSV to a local libscanR reference.

No network requests or atomic data are included. See --help and the README.
The input must use nm, eV, Aki in s^-1, explicit element/ion columns and a
single wavelength medium. Request two spectra (for example Ca I;Ca II) to
obtain element/sp_num columns. Estimated bracketed energies are flagged.
"""
import argparse
import csv
import datetime
import hashlib
import io
import json
import math
from pathlib import Path
import re


def clean(value):
    value = (value or "").strip()
    return value[2:-1] if value.startswith('="') and value.endswith('"') else value


def number(value, field, row, missing=True):
    value = clean(value)
    if not value:
        if missing:
            return None
        raise ValueError(f"Row {row}: missing {field}")
    if "[" in value or "]" in value:
        if not re.fullmatch(r"\[[^\[\]]+\]", value):
            raise ValueError(f"Row {row}: malformed estimated {field}={value!r}")
        value = value[1:-1]
    if not re.fullmatch(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?", value):
        raise ValueError(f"Row {row}: unsupported numeric {field}={value!r}; inspect the source, do not guess")
    result = float(value)
    if not math.isfinite(result):
        raise ValueError(f"Row {row}: nonfinite {field}")
    return result


def convert(content, source):
    reader = csv.reader(io.StringIO(content.decode("utf-8-sig"), newline=""), strict=True)
    header = next(reader, None)
    required = {"element", "sp_num", "Aki(s^-1)", "Ei(eV)", "Ek(eV)", "g_k"}
    if not header or len(header) != len(set(header)) or not required.issubset(header):
        raise ValueError("Expected NIST CSV with element, sp_num, Aki(s^-1), Ei(eV), Ek(eV), g_k; use the README download settings")
    wave = [key for key in header if re.fullmatch(r"(?:ritz|obs)_wl_(?:air|vac)\(nm\)", key)]
    media = {"vacuum" if "_vac(" in key else "air" for key in wave}
    if not wave or len(media) != 1:
        raise ValueError("Use nm and one explicit medium (prefer Vacuum all wavelengths); mixed media need separate files")
    medium = media.pop()
    rows = []
    for line, cells in enumerate(reader, 2):
        if not cells or not any(clean(x) for x in cells):
            continue
        if len(cells) != len(header):
            raise ValueError(f"Row {line}: unexpected column count")
        raw = dict(zip(header, cells))
        element = clean(raw["element"])
        ion = number(raw["sp_num"], "sp_num", line, False)
        if not re.fullmatch(r"[A-Z][a-z]?", element) or ion < 1 or ion != int(ion):
            raise ValueError(f"Row {line}: invalid element/ion identity")
        wavelengths = [(key, number(raw[key], key, line)) for key in wave]
        wavelengths = [(key, value) for key, value in wavelengths if value is not None]
        if not wavelengths:
            raise ValueError(f"Row {line}: neither Ritz nor observed wavelength is available")
        key, wavelength = sorted(wavelengths, key=lambda x: not x[0].startswith("ritz"))[0]
        rate = number(raw["Aki(s^-1)"], "Aki(s^-1)", line)
        lower = number(raw["Ei(eV)"], "Ei(eV)", line)
        upper = number(raw["Ek(eV)"], "Ek(eV)", line)
        weight = number(raw["g_k"], "g_k", line)
        if wavelength <= 0 or any(x is not None and x < 0 for x in (rate, lower, upper)) or (weight is not None and weight <= 0):
            raise ValueError(f"Row {line}: invalid physical values")
        rows.append(dict(element=element, ionization=int(ion), wavelength_nm=wavelength,
            aki=None if rate is None else rate / 1e8, ei_ev=lower, ek_ev=upper,
            persistent="FALSE", wavelength_medium=medium,
            wavelength_kind="ritz" if key.startswith("ritz") else "observed",
            wavelength_vacuum_nm=wavelength if medium == "vacuum" else None,
            A_s=rate, g_upper=weight, energy_upper_ev=upper,
            energy_upper_estimated="TRUE" if "[" in clean(raw["Ek(eV)"]) else "FALSE",
            source=source, source_row=line,
            transition_reference=clean(raw.get("tp_ref")), line_reference=clean(raw.get("line_ref")),
            accuracy_code=clean(raw.get("Acc")), transition_type=clean(raw.get("Type"))))
    if not rows:
        raise ValueError("No transitions in the input")
    output = io.StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=list(rows[0]), lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue().encode("utf-8"), len(rows)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--retrieved-date", required=True, help="Actual download date, YYYY-MM-DD")
    parser.add_argument("--source-url", required=True, help="Actual query URL retained by the downloader")
    parser.add_argument("--source-label", default="NIST Atomic Spectra Database; https://doi.org/10.18434/T4W30F")
    args = parser.parse_args()
    datetime.date.fromisoformat(args.retrieved_date)
    raw = args.input.read_bytes()
    source = f"{args.source_label}; retrieved {args.retrieved_date}"
    output, count = convert(raw, source)
    manifest_path = args.output.with_suffix(args.output.suffix + ".provenance.json")
    if args.output.exists() or args.output.is_symlink() or manifest_path.exists() or manifest_path.is_symlink():
        parser.error("Output or provenance already exists; choose a new path. Existing data are never overwritten.")
    manifest = dict(schema_version=1, input_file=args.input.name,
        input_sha256=hashlib.sha256(raw).hexdigest(), output_sha256=hashlib.sha256(output).hexdigest(),
        source_url=args.source_url, source_label=args.source_label, retrieved_date=args.retrieved_date,
        rows=count, selection="All input rows; Ritz wavelength preferred, otherwise observed; no inferred persistent designation or missing physical values")
    created = False
    manifest_created = False
    try:
        with args.output.open("xb") as stream:
            created = True
            stream.write(output)
        with manifest_path.open("x", encoding="utf-8") as stream:
            manifest_created = True
            json.dump(manifest, stream, indent=2)
            stream.write("\n")
    except Exception:
        if manifest_created:
            manifest_path.unlink()
        if created:
            args.output.unlink()
        raise
    print(f"Imported {count} transitions to {args.output}; provenance: {manifest_path}")


if __name__ == "__main__":
    main()
