#!/usr/bin/env python3
"""Build an unsigned standalone tvOS IPA, for personal signing on a server."""
import argparse, os, pathlib, plistlib, shutil, subprocess, zipfile
root = pathlib.Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--output', type=pathlib.Path, default=root/'build')
parser.add_argument('--bundle-id', default=os.environ.get('ORION_BUNDLE_IDENTIFIER', 'com.oriontv.native'))
parser.add_argument('--server', default=os.environ.get('ORION_SERVER_URL', ''))
parser.add_argument('--precompiled-assets', type=pathlib.Path)
parser.add_argument('--disable-plugin-sandbox', action='store_true', help='For hosts where Apple compiler plugins cannot start a nested sandbox')
args = parser.parse_args(); output = args.output.resolve(); output.mkdir(parents=True, exist_ok=True)
developer = pathlib.Path(os.environ.get('DEVELOPER_DIR', '/Applications/Xcode.app/Contents/Developer'))
sdk = developer/'Platforms/AppleTVOS.platform/Developer/SDKs/AppleTVOS.sdk'
tools = developer/'Toolchains/XcodeDefault.xctoolchain/usr/bin'
app = output/'Payload/OrionTV.app'; app.mkdir(parents=True, exist_ok=True)
command = [str(tools/'swiftc'), '-swift-version', '5', '-parse-as-library', '-O', '-target', 'arm64-apple-tvos17.0', '-sdk', str(sdk), '-module-cache-path', str(output/'module-cache'), '-o', str(app/'OrionTVNative')]
if args.disable_plugin_sandbox: command += ['-Xfrontend', '-disable-sandbox']
command += [str(p) for p in sorted((root/'Sources').glob('*.swift'))]
subprocess.run(command, check=True)
info = plistlib.loads((root/'Info.plist').read_bytes())
info['CFBundleIdentifier'] = args.bundle_id; info['CFBundleExecutable'] = 'OrionTVNative'; info['OrionServerURL'] = args.server
if args.precompiled_assets:
    shutil.copyfile(args.precompiled_assets, app/'Assets.car')
    info['CFBundleIcons'] = {'CFBundlePrimaryIcon': 'App Icon - Small'}
else:
    partial = output/'asset-info.plist'
    subprocess.run([str(developer/'usr/bin/actool'), str(root/'Assets.xcassets'), '--compile', str(app), '--platform', 'appletvos', '--target-device', 'tv', '--minimum-deployment-target', '17.0', '--app-icon', 'TVAppIcon', '--output-partial-info-plist', str(partial)], check=True)
    info.update(plistlib.loads(partial.read_bytes()))
(app/'Info.plist').write_bytes(plistlib.dumps(info))
ipa = output/'OrionTVNative-unsigned.ipa'
with zipfile.ZipFile(ipa, 'w', zipfile.ZIP_DEFLATED) as archive:
    for file in sorted(app.rglob('*')):
        if file.is_file(): archive.write(file, file.relative_to(output))
print(ipa)
