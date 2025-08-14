param (
    [string] $mode = "static"
)

$cmd = "./target/release/summarize"

function SumAll {
    param (
        [string] $prof
    )
    $name = If ($mode -ne "static") { "$prof-$mode" } Else { $prof }

    $src_dir = "./target/$mode/$prof/selfprof"
    $dst_dir = "./dist/$mode/$prof/selfprof"
    New-Item $dst_dir -Type Directory -Force | Out-Null

    & $cmd summarize --json "$dst_dir/$name.json"          --dir "$src_dir/$name"
    # $cmd summarize --json "$dst_dir/$name-mold.json"     --dir "$src_dir/$name-mold"
    & $cmd summarize --json "$dst_dir/$name-ccinline.json" --dir "$src_dir/$name-ccinline"
    # $cmd summarize --json "$dst_dir/$name-both.json"     --dir "$src_dir/$name-mold-ccinline"
}

foreach ($prof in "_dev", "dev_clif", "iter", "iter_clif", "rel", "rel_clif") {
    SumAll -prof $prof
}