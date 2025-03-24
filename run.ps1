
$SourceDir = "./crates/bevy-hello-world-bin"

Push-Location $SourceDir

# We need to use nightly toolchain for advanced and experimental options (primarily "-Z").
$Env:RUSTUP_TOOLCHAIN = "nightly"

# Incremental compile slows down initial compile, and should be benched separately. 
# Incremental primarily uses 256 codegen units to function, which inhibits link-time opts.
$Env:CARGO_INCREMENTAL = 0

cargo -V

$CurDir = (Get-Location).Path

# Build statically linked exe.
# This links all dependencies, including the Rust libstd. 
$Env:RUSTFLAGS="
    -Zself-profile=$($CurDir)/target/profiles-static 
    -Zself-profile-events=default
    "
    
cargo build `
    -Z unstable-options `
    --artifact-dir="$($CurDir)/target/out-static" `

cargo run

# Build dynamically linked exe.
# Rust libstd will use the dylib from toolchain.
# Internal bevy crates will be linked into one big dylib.
$Env:RUSTFLAGS="
    -Z self-profile=$($CurDir)/target/profiles-dylib
    -Z self-profile-events=default

    -C strip=symbols
    -C split-debuginfo=off
    -C link-arg=--ld-path=/usr/bin/mold
    -C linker=clang
    -C prefer-dynamic=yes
    "

 cargo build `
 --features bevy-hello-world/dynamic_linking `
     -Z unstable-options `
     --artifact-dir="$($CurDir)/target/out-dylib" `
     --profile dev

cargo run `
    -Z unstable-options `
    --profile dev