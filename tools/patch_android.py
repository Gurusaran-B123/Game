#!/usr/bin/env python3
"""Android tweaks for Deplo Hatch (run from the project root; setup.sh does it).
 - app name shown under the icon
 - optional release signing from Codemagic / GitHub env variables
"""
import os, re, sys
from pathlib import Path

ROOT = Path.cwd()

def patch_manifest():
    path = ROOT / "android/app/src/main/AndroidManifest.xml"
    if not path.exists():
        sys.exit("AndroidManifest.xml not found - run `flutter create` first.")
    text = path.read_text(encoding="utf-8")
    text = re.sub(r'android:label="[^"]*"', 'android:label="Deplo Hatch"', text, count=1)
    # lock to portrait
    if "screenOrientation" not in text:
        text = text.replace("<activity", '<activity\n            android:screenOrientation="portrait"', 1)
    path.write_text(text, encoding="utf-8")
    print("[ok] AndroidManifest.xml patched")

def patch_signing():
    """Sign with CM_KEYSTORE_* variables when present, otherwise use the debug key."""
    app = ROOT / "android/app"
    kts, groovy = app / "build.gradle.kts", app / "build.gradle"
    in_ci = bool(os.environ.get("CM_KEYSTORE_PATH"))
    def fail(msg):
        print(f"[warn] {msg}")
        if in_ci:
            sys.exit("Signing could not be configured - stopping.")
    if kts.exists():
        text = kts.read_text(encoding="utf-8")
        if "CM_KEYSTORE_PATH" in text:
            print("[ok] signing already configured"); return
        block = (
            "    signingConfigs {\n"
            '        create("release") {\n'
            '            val ksPath = System.getenv("CM_KEYSTORE_PATH")\n'
            "            if (ksPath != null) {\n"
            "                storeFile = file(ksPath)\n"
            '                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")\n'
            '                keyAlias = System.getenv("CM_KEY_ALIAS")\n'
            '                keyPassword = System.getenv("CM_KEY_PASSWORD")\n'
            "            }\n        }\n    }\n\n")
        new, n1 = re.subn(r"^([ \t]*)buildTypes\s*\{", lambda m: block + m.group(0), text, count=1, flags=re.M)
        new, n2 = re.subn(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
            'signingConfig = if (System.getenv("CM_KEYSTORE_PATH") != null) '
            'signingConfigs.getByName("release") else signingConfigs.getByName("debug")', new, count=1)
        if n1 != 1 or n2 != 1:
            return fail("could not patch build.gradle.kts")
        kts.write_text(new, encoding="utf-8"); print("[ok] signing configured (kts)"); return
    if groovy.exists():
        text = groovy.read_text(encoding="utf-8")
        if "CM_KEYSTORE_PATH" in text:
            print("[ok] signing already configured"); return
        block = (
            "    signingConfigs {\n        release {\n"
            '            if (System.getenv("CM_KEYSTORE_PATH")) {\n'
            '                storeFile file(System.getenv("CM_KEYSTORE_PATH"))\n'
            '                storePassword System.getenv("CM_KEYSTORE_PASSWORD")\n'
            '                keyAlias System.getenv("CM_KEY_ALIAS")\n'
            '                keyPassword System.getenv("CM_KEY_PASSWORD")\n'
            "            }\n        }\n    }\n\n")
        new, n1 = re.subn(r"^([ \t]*)buildTypes\s*\{", lambda m: block + m.group(0), text, count=1, flags=re.M)
        new, n2 = re.subn(r"signingConfig\s+signingConfigs\.debug",
            'signingConfig System.getenv("CM_KEYSTORE_PATH") ? signingConfigs.release : signingConfigs.debug',
            new, count=1)
        if n1 != 1 or n2 != 1:
            return fail("could not patch build.gradle")
        groovy.write_text(new, encoding="utf-8"); print("[ok] signing configured (groovy)"); return
    fail("android/app/build.gradle(.kts) not found")

if __name__ == "__main__":
    patch_manifest()
    patch_signing()
