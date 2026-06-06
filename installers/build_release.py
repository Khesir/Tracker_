import re
import subprocess
import sys
import os

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INSTALLERS_DIR = os.path.dirname(os.path.abspath(__file__))
ISS_SCRIPT = os.path.join(INSTALLERS_DIR, "desktop_inno_script.iss")
ISCC = r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe"


def get_version() -> str:
    pubspec = os.path.join(PROJECT_DIR, "pubspec.yaml")
    with open(pubspec) as f:
        for line in f:
            match = re.match(r"^version:\s*(\d+\.\d+\.\d+)", line)
            if match:
                return match.group(1)
    raise RuntimeError("Could not find version in pubspec.yaml")


def sync_iss_version(version: str):
    with open(ISS_SCRIPT) as f:
        content = f.read()
    content = re.sub(r'(#define MyAppVersion\s+")[^"]*(")', rf'\g<1>{version}\2', content)
    content = re.sub(r'(OutputBaseFilename=trackr-v)[^\n]*', rf'\g<1>{version}', content)
    with open(ISS_SCRIPT, "w") as f:
        f.write(content)
    print(f"ISS version synced to {version}")


def run(cmd: list[str], cwd: str = PROJECT_DIR):
    print(f"\n> {' '.join(cmd)}")
    result = subprocess.run(cmd, cwd=cwd, shell=True)
    if result.returncode != 0:
        print(f"Command failed with exit code {result.returncode}")
        sys.exit(result.returncode)


def build_windows():
    print("\n=== Building Windows release ===")
    run(["flutter", "build", "windows", "--release"])
    print("Windows build complete: build/windows/x64/runner/Release/")

    if not os.path.exists(ISCC):
        print(f"Inno Setup not found at {ISCC} — skipping installer compilation.")
        return

    print("\n=== Compiling Inno Setup installer ===")
    run([ISCC, ISS_SCRIPT])
    print(f"Installer output: {INSTALLERS_DIR}")


def main():
    version = get_version()
    print(f"Version: {version}")

    sync_iss_version(version)

    print("\n=== Cleaning build ===")
    run(["flutter", "clean"])
    run(["flutter", "pub", "get"])

    build_windows()

    print("\nBuild complete.")


if __name__ == "__main__":
    main()
