# arm64-to-sim

A simple command-line tool for hacking native ARM64 binaries to run on the Apple Silicon iOS Simulator.

## Background

If you are running your iOS project on a Apple Silicon simulator, you might have encountered the following error:

```
In ...somelib.a(SomeObject.o), building for iOS Simulator, but linking in object file built for iOS, file '...somelib.a' for architecture arm64
```

![error](https://user-images.githubusercontent.com/47009/144603266-8eb1fde7-6459-4c48-b105-18bc16df8c08.png)

The third-party static libraries you are using don't have support for ARM64 simulator. And technically they can't unless they are migrated to the XCFramework format.

This tool will hack the static libraries to make them run for your ARM64 simulator.

## Prepare

Compile the code using Swift 5.5.

```bash
swift build -c release
```

You'll find the `arm64-to-sim` binary in your `.build/release` directory.

Or you can just download a pre-compiled binary from [Releases](https://github.com/luosheng/arm64-to-sim/releases).

## USage

```bash
USAGE: arm64-to-sim <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  patch
  restore

  See 'arm64-to-sim help <subcommand>' for detailed help.
```

Start by patching the library with `arm64-to-sim patch [file]`.

 `arm64_to_sim` will back up your original file as `[file].original`, and create a patched one named `[file].patch`. It will then create a symbolic link to the patched file. Now you are ready to run your apps targeting simulators.

If you are preparing for a release, just use the `restore` command and it will point the symbolic link back to your original library file.

## Can it go further?

Sure. Put `arm64_to_sim` to the root directory of your iOS projects (or wherever you like). Then add a `Run Script` phase to your `Build Phases` and move it above `Compile Sources`.

Paste the following script to the editor, then add the libraries to the `Input Files` section.

```bash
if [[ "${ARCHS}" == *arm64* ]]; then
  i=0
  while [ $i -ne $SCRIPT_INPUT_FILE_COUNT ]; do
    lib=SCRIPT_INPUT_FILE_$i
    if [[ "${SDKROOT}" == *Simulator* ]]; then
      ./arm64-to-sim patch "${!lib}"
    else
      ./arm64-to-sim restore "${!lib}"
    fi
    i=$(($i + 1))
  done
fi
```

![screenshot](https://user-images.githubusercontent.com/47009/144601342-4d55108e-c1c1-4f39-a64d-89348e7f12fc.png)

This script phase will target ARM64 archs only, patch your libraries when you are running on a simulator, and restore them otherwise.
