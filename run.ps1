<#
    .PARAMETER Dynamic
    False: 
        Build statically linked exe.
        This links all dependencies, including the Rust libstd. 
      
    True: 
        Build dynamically linked exe.
        Rust libstd will use the dylib from toolchain.
        Internal bevy crates will be linked into one big dylib.
#>

param (
    [string] $Toolchain = "nightly",
    [switch] $Incremental,
    [switch] $Dynamic,
    [switch] $StripSymbols
)

$RootDir = (Get-Location).Path
$TargetDir = "$RootDir/target"

# We need to use nightly toolchain for advanced and experimental options (primarily "-Z").
$Env:RUSTUP_TOOLCHAIN = $Toolchain

# Incremental compile slows down initial compile, and should be benched separately. 
# Incremental primarily uses 256 codegen units to function, which inhibits link-time opts.
$Env:CARGO_INCREMENTAL = If ($Incremental) { 1 } Else { 0 }

cargo -V

function SetRustFlags {
    param (
        [string] $RustProfile,
        [string] $Prefix,
        [string] $Linker,
        [string] $CCInline
    )

    $Env:RUSTFLAGS = "
    -Z self-profile=$TargetDir/$RustProfile/selfprof/$Prefix
    -Z self-profile-events=default
    $(If ($CCInline) {"-Z cross-crate-inline-threshold=$CCInline"})

    $(If ($StripSymbols) {"-C strip=symbols -C split-debuginfo=off"})
    $($Linker)
    $(If ($Dynamic) {"-C prefer-dynamic"})
    "
}

function Build {
    param (
        [string] $RustProfile,
        [string] $Linker,
        [string] $CCInline
    )
    $Prefix = $RustProfile
    $Prefix += If ($Dynamic) { "-dylib" } Else { '' } 
    $Prefix += If ($StripSymbols) { "-strip" } Else { '' }
    $Prefix += If ($Linker) { "-mold" } Else { '' } 
    $Prefix += If ($CCInline) { "-ccinline" } Else { '' } 

    SetRustFlags `
        -RustProfile $RustProfile `
        -Prefix $Prefix `
        If ($Dynamic) { -Dynamic } `
        -Linker $Linker `
        -CCInline $CCInline

    cargo build --timings `
        -Z unstable-options `
        --artifact-dir="$TargetDir/$RustProfile/out/$Prefix" `
        --profile $RustProfile `
        --features $(If ($Dynamic) { "dynamic_linking" } Else { '' })
}

function BuildProfiles {
    param (
        [string] $CCInline,
        [switch] $Mold
    )
    $Linker = If ($Mold) { "-C link-arg=--ld-path=/usr/bin/mold -C linker=clang" } Else { "" } 

    foreach ($prof in "_dev", "dev_clif", "iter", "iter_clif", "rel", "rel_clif") {
        Build -Linker $Linker -CCInline $CCInline -RustProfile $prof
    }
}

Push-Location "./crates/bevy-hello-world-bin"

& BuildProfiles
# BuildProfiles -Mold

& BuildProfiles       -CCInline "always"
# BuildProfiles -Mold -CCInline "always"

Pop-Location
