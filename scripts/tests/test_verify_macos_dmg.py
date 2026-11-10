import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "verify_macos_dmg.sh"


class VerifyMacosDmgTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "commands"
        self.env = {
            **os.environ,
            "PATH": f"{self.bin}:{os.environ['PATH']}",
            "RUNNER_TEMP": str(self.root),
            "COMMAND_LOG": str(self.log),
            "DISTRIBUTION_BUILD": "false",
        }
        self.stub("hdiutil", """
echo "hdiutil $*" >> "$COMMAND_LOG"
if [ "$1" = attach ]; then
  for arg in "$@"; do mount="$arg"; done
  mkdir -p "$mount/MCCompanion.app/Contents/MacOS"
  ln -s /Applications "$mount/Applications"
  printf '#!/bin/bash\\nif [ "${APP_EXITS:-false}" = true ]; then exit 1; fi\\nexec /bin/sleep 30\\n' > "$mount/MCCompanion.app/Contents/MacOS/MCCompanion"
  chmod +x "$mount/MCCompanion.app/Contents/MacOS/MCCompanion"
fi
""")
        self.stub("ditto", 'cp -R "$1" "$2"')
        for name in ("codesign", "xcrun", "spctl"):
            self.stub(name, f'echo "{name} $*" >> "$COMMAND_LOG"')
        self.stub("sleep", "/bin/sleep 0.2")

    def stub(self, name, body):
        path = self.bin / name
        path.write_text(f"#!/bin/bash\nset -e\n{body}\n")
        path.chmod(0o755)

    def run_script(self, **env):
        return subprocess.run(
            ["bash", str(SCRIPT), str(self.root / "app.dmg")],
            env={**self.env, **env},
            capture_output=True,
            text=True,
            timeout=10,
        )

    def test_ci_build_checks_app_without_distribution_assessments(self):
        result = self.run_script()
        self.assertEqual(result.returncode, 0, result.stderr)
        log = self.log.read_text()
        self.assertIn("hdiutil verify", log)
        self.assertIn("codesign --verify --deep --strict", log)
        self.assertIn("hdiutil detach", log)
        self.assertNotIn("spctl", log)
        self.assertNotIn("stapler", log)

    def test_distribution_build_checks_tickets_and_gatekeeper(self):
        result = self.run_script(DISTRIBUTION_BUILD="true")
        self.assertEqual(result.returncode, 0, result.stderr)
        log = self.log.read_text()
        self.assertEqual(log.count("xcrun stapler validate"), 2)
        self.assertIn("spctl --assess --type execute", log)
        self.assertIn("hdiutil detach", log)

    def test_startup_failure_fails_and_detaches(self):
        result = self.run_script(APP_EXITS="true")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("exited during startup", result.stdout)
        self.assertIn("hdiutil detach", self.log.read_text())


if __name__ == "__main__":
    unittest.main()
