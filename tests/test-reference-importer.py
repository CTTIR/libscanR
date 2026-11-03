"""Independent fictional CSV fixtures; no atomic reference data are bundled."""
import csv
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("import_nist", ROOT / "inst/scripts/import_nist.py")
IMPORTER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(IMPORTER)


def fixture():
    text = io.StringIO(newline="")
    writer = csv.writer(text)
    writer.writerow(["element", "sp_num", "obs_wl_vac(nm)", "ritz_wl_vac(nm)",
                     "Aki(s^-1)", "Ei(eV)", "Ek(eV)", "g_k", "tp_ref"])
    writer.writerow(["X", '="1"', '="500"', '="500.25"', '="200000000"',
                     '="0"', '="[3]"', '="4"', "fictional-rate-source"])
    writer.writerow(["Y", "2", "600", "", "", "1", "5", "", ""])
    return text.getvalue().encode()


class ImporterTests(unittest.TestCase):
    def test_units_missing_fields_medium_and_provenance(self):
        converted, count = IMPORTER.convert(fixture(), "Fictional parser fixture")
        rows = list(csv.DictReader(io.StringIO(converted.decode())))
        self.assertEqual(count, 2)
        self.assertEqual(float(rows[0]["aki"]), 2)
        self.assertEqual(float(rows[0]["wavelength_nm"]), 500.25)
        self.assertEqual(rows[0]["energy_upper_estimated"], "TRUE")
        self.assertEqual(rows[0]["source"], "Fictional parser fixture")
        self.assertEqual(rows[0]["transition_reference"], "fictional-rate-source")
        self.assertEqual(rows[1]["A_s"], "")
        self.assertEqual(rows[1]["g_upper"], "")
        self.assertEqual(rows[1]["persistent"], "FALSE")
        self.assertEqual(float(rows[1]["wavelength_vacuum_nm"]), 600)

    def test_air_never_invents_a_vacuum_wavelength(self):
        data, _ = IMPORTER.convert(fixture().replace(b"_vac(nm)", b"_air(nm)"), "Fictional")
        rows = list(csv.DictReader(io.StringIO(data.decode())))
        self.assertEqual(rows[0]["wavelength_medium"], "air")
        self.assertEqual(rows[0]["wavelength_vacuum_nm"], "")

    def test_truncated_quoted_reference_is_rejected(self):
        data = fixture().splitlines()[0] + b'\nX,1,500,500,100000000,0,3,4,"unterminated\n'
        with self.assertRaises(csv.Error):
            IMPORTER.convert(data, "Fictional")

    def test_unsupported_units_shapes_and_numbers_are_not_guessed(self):
        cases = [fixture().replace(b"(nm)", b"(A)"),
                 fixture().replace(b"500.25", b"500+x"),
                 fixture().replace(b"[3]", b"[3"),
                 fixture().replace(b"[3]", b"[3]]"),
                 fixture().replace(b"_vac(nm),ritz_wl_vac", b"_air(nm),ritz_wl_vac"),
                 fixture().replace(b"Ek(eV)", b"Ek(cm-1)"),
                 fixture().replace(b"g_k,tp_ref", b"g_k,g_k"),
                 fixture().replace(b"600,,,1", b"600,,,1,extra")]
        for case in cases:
            with self.subTest(case=case[:100]), self.assertRaises(ValueError):
                IMPORTER.convert(case, "Fictional")

    def test_cli_writes_hash_receipt_and_preserves_existing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            source, target = path / "input.csv", path / "output.csv"
            source.write_bytes(fixture())
            command = [sys.executable, str(ROOT / "inst/scripts/import_nist.py"), str(source), str(target),
                       "--retrieved-date", "2026-01-01", "--source-url", "https://example.invalid/fixture",
                       "--source-label", "Fictional software fixture; not NIST"]
            subprocess.run(command, check=True, capture_output=True)
            original = target.read_bytes()
            manifest = json.loads(target.with_suffix(".csv.provenance.json").read_text())
            self.assertEqual(manifest["rows"], 2)
            self.assertEqual(manifest["source_url"], "https://example.invalid/fixture")
            import hashlib
            self.assertEqual(manifest["output_sha256"], hashlib.sha256(original).hexdigest())
            source.write_bytes(b"invalid")
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(target.read_bytes(), original)
            source.write_bytes(fixture())
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(target.read_bytes(), original)

    def test_failed_receipt_write_removes_only_new_outputs_and_allows_retry(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            source, target = path / "input.csv", path / "output.csv"
            source.write_bytes(fixture())
            args = ["import_nist.py", str(source), str(target), "--retrieved-date", "2026-01-01",
                    "--source-url", "https://example.invalid/fixture", "--source-label", "Fictional"]
            with mock.patch.object(sys, "argv", args):
                with mock.patch.object(IMPORTER.json, "dump", side_effect=OSError("receipt disk failure")):
                    with self.assertRaisesRegex(OSError, "receipt disk failure"):
                        IMPORTER.main()
                self.assertFalse(target.exists())
                self.assertFalse(target.with_suffix(".csv.provenance.json").exists())
                IMPORTER.main()
                self.assertTrue(target.is_file())
                self.assertEqual(json.loads(target.with_suffix(".csv.provenance.json").read_text())["rows"], 2)


if __name__ == "__main__":
    unittest.main()
