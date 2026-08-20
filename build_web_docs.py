from __future__ import annotations

from pathlib import Path
import os
import re
import shutil
import subprocess
import sys


ROOT_DIR = Path(__file__).resolve().parent
PUBSPEC_FILE = ROOT_DIR / "pubspec.yaml"
EXAMPLE_DIR = ROOT_DIR / "example"
EXAMPLE_WEB_DIR = EXAMPLE_DIR / "web"
BUILD_WEB_DIR = EXAMPLE_DIR / "build" / "web"
DOCS_DIR = ROOT_DIR / "docs"


def error(message: str, code: int = 1) -> None:
    print(f"\nERROR: {message}")
    sys.exit(code)


def get_package_name() -> str:
    if not PUBSPEC_FILE.exists():
        error(f"pubspec.yaml not found:\n{PUBSPEC_FILE}")

    content = PUBSPEC_FILE.read_text(encoding="utf-8")

    match = re.search(
        r"(?m)^\s*name\s*:\s*['\"]?([A-Za-z0-9_]+)['\"]?\s*(?:#.*)?$",
        content,
    )

    if not match:
        error("Could not read package name from pubspec.yaml.")

    return match.group(1)


def get_flutter_path() -> Path:
    # 1) Explicit path has highest priority.
    custom = os.environ.get("FLUTTER_BIN", "").strip().strip('"')

    if custom:
        flutter_path = Path(custom)

        print(f"FLUTTER_BIN  : {flutter_path}")

        if not flutter_path.is_file():
            error(
                "FLUTTER_BIN is set, but the file does not exist:\n"
                f"{flutter_path}"
            )

        return flutter_path.resolve()

    # 2) Otherwise search Windows/PATH.
    names = (
        ["flutter.bat", "flutter.cmd", "flutter"]
        if os.name == "nt"
        else ["flutter"]
    )

    for name in names:
        found = shutil.which(name)

        if found:
            return Path(found).resolve()

    error(
        "Flutter was not found.\n\n"
        "Set FLUTTER_BIN explicitly in PowerShell, for example:\n"
        r'$env:FLUTTER_BIN="G:\Libraries\flutter\bin\flutter.bat"'
        + "\n"
        "py build_web_docs.py"
    )


def run_flutter(
    flutter_path: Path,
    args: list[str],
    cwd: Path,
) -> None:
    """
    Execute a Flutter command.

    Handles flutter.bat correctly on Windows.
    """

    print("\nRunning:")
    print(f'"{flutter_path}" ' + " ".join(args))
    print(f"Working dir: {cwd}")
    print()

    try:
        if os.name == "nt":
            # flutter.bat must be executed through cmd.exe on Windows.
            command = subprocess.list2cmdline(
                [str(flutter_path), *args]
            )

            subprocess.run(
                [
                    "cmd.exe",
                    "/d",
                    "/s",
                    "/c",
                    command,
                ],
                cwd=str(cwd),
                check=True,
            )

        else:
            subprocess.run(
                [str(flutter_path), *args],
                cwd=str(cwd),
                check=True,
            )

    except subprocess.CalledProcessError as exc:
        error(
            f"Flutter command failed with exit code {exc.returncode}.\n"
            f"Command: flutter {' '.join(args)}",
            exc.returncode,
        )


def validate_example_project() -> None:
    """
    Ensure the example Flutter project exists.
    """

    if not EXAMPLE_DIR.is_dir():
        error(
            f"example directory not found:\n{EXAMPLE_DIR}"
        )

    example_pubspec = EXAMPLE_DIR / "pubspec.yaml"

    if not example_pubspec.is_file():
        error(
            f"example/pubspec.yaml not found:\n"
            f"{example_pubspec}"
        )


def ensure_web_support(flutter_path: Path) -> None:
    """
    Configure the example project for Flutter Web when needed.

    This fixes:

        This project is not configured for the web.
        To configure this project for the web,
        run flutter create . --platforms web
    """

    web_index = EXAMPLE_WEB_DIR / "index.html"

    # A valid Flutter web project should at least have:
    #
    # example/
    #   web/
    #     index.html
    #
    # Checking index.html is safer than checking the directory only.
    if EXAMPLE_WEB_DIR.is_dir() and web_index.is_file():
        print("\nFlutter Web configuration found.")
        print(f"Web dir     : {EXAMPLE_WEB_DIR}")
        return

    print("\n" + "=" * 72)
    print("Flutter Web is not configured.")
    print("=" * 72)

    if not EXAMPLE_WEB_DIR.exists():
        print(f"Missing      : {EXAMPLE_WEB_DIR}")
    elif not web_index.exists():
        print(f"Missing      : {web_index}")

    print("\nConfiguring Flutter Web automatically...")

    run_flutter(
        flutter_path=flutter_path,
        args=[
            "create",
            ".",
            "--platforms",
            "web",
        ],
        cwd=EXAMPLE_DIR,
    )

    # Verify configuration was actually created.
    if not EXAMPLE_WEB_DIR.is_dir():
        error(
            "Flutter Web configuration failed.\n"
            f"Directory was not created:\n{EXAMPLE_WEB_DIR}"
        )

    if not web_index.is_file():
        error(
            "Flutter Web configuration appears incomplete.\n"
            f"File was not created:\n{web_index}"
        )

    print("\nFlutter Web configured successfully.")
    print(f"Web dir     : {EXAMPLE_WEB_DIR}")


def build_web(
    flutter_path: Path,
    package_name: str,
) -> None:
    base_href = f"/{package_name}/"

    args = [
        "build",
        "web",
        "--release",
        "--base-href",
        base_href,
    ]

    print("\n" + "=" * 72)
    print("Building Flutter Web")
    print("=" * 72)
    print(f"Package name : {package_name}")
    print(f"Base href    : {base_href}")
    print(f"Flutter      : {flutter_path}")
    print(f"Working dir  : {EXAMPLE_DIR}")
    print("=" * 72)

    run_flutter(
        flutter_path=flutter_path,
        args=args,
        cwd=EXAMPLE_DIR,
    )


def copy_build_to_docs() -> None:
    if not BUILD_WEB_DIR.is_dir():
        error(
            f"Build output not found:\n{BUILD_WEB_DIR}"
        )

    print("\n" + "=" * 72)
    print("Copying build output to docs")
    print("=" * 72)

    if DOCS_DIR.exists():
        print(f"Removing old docs directory:\n{DOCS_DIR}")
        shutil.rmtree(DOCS_DIR)

    shutil.copytree(
        BUILD_WEB_DIR,
        DOCS_DIR,
    )

    print(f"Source : {BUILD_WEB_DIR}")
    print(f"Target : {DOCS_DIR}")


def main() -> None:
    package_name = get_package_name()
    flutter_path = get_flutter_path()

    # 1. Make sure example project exists.
    validate_example_project()

    # 2. Automatically configure Flutter Web when missing.
    ensure_web_support(flutter_path)

    # 3. Build Web release.
    build_web(
        flutter_path,
        package_name,
    )

    # 4. Copy build/web -> docs.
    copy_build_to_docs()

    print("\n" + "=" * 72)
    print("SUCCESS")
    print("=" * 72)
    print(f"Package   : {package_name}")
    print(f"Base href : /{package_name}/")
    print(f"Web       : {EXAMPLE_WEB_DIR}")
    print(f"Docs      : {DOCS_DIR}")


if __name__ == "__main__":
    main()