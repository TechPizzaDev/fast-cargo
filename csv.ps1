param (
    [string] $mode = "static"
)

function Convert-Duration {
    param (
        $duration
    )
    return $duration.secs + ($duration.nanos / 1000000000)
}

$names = ("_dev", "dev_clif", "iter", "iter_clif", "rel", "rel_clif")

$list_time      = [System.Collections.ArrayList]::new()
$list_arti_size = [System.Collections.ArrayList]::new()
$list_bin_size  = [System.Collections.ArrayList]::new()

foreach ($prof in $names) {
    $name = If ($mode -ne "static") { "$prof-$mode" } Else { $prof }

    $src_dir = "./target/$mode/$prof"
    $dst_dir = "./dist/$mode/$prof"
    New-Item $dst_dir -Type Directory -Force | Out-Null

    $prof_name = $prof.TrimStart("_")
    $item_time      = @{ prof = $prof_name }
    $item_arti_size = @{ prof = $prof_name }
    $item_bin_size  = @{ prof = $prof_name }

    foreach ($opts in "", "-ccinline") {
        $id = "$name$opts"
        $json = Get-Content "$dst_dir/selfprof/$id.json" -Raw | ConvertFrom-Json
        
        $key = If ($opts -eq "") {"default"} Else { $opts.TrimStart("-") }
        
        $join_time = Convert-Duration ($json.query_data 
        | Where-Object { $_.label -eq "finish_ongoing_codegen" }
        | Select-Object -ExpandProperty "time")

        $item_time.$key = (Convert-Duration $json.total_time) - $join_time

        $item_arti_size.$key = $json.artifact_sizes 
        | Where-Object { $_.label -eq "linked_artifact" } 
        | Select-Object -ExpandProperty "value"

        $item_bin_size.$key = (Get-ChildItem "$src_dir/out/$id" | Measure-Object Length -Sum).Sum 
    }

    . {
        $list_time.Add($item_time)
        $list_arti_size.Add($item_arti_size)
        $list_bin_size.Add($item_bin_size)
    } | Out-Null
}

$list_time      | Export-Csv -UseQuotes AsNeeded -Path "./dist/$mode/time.csv"      -NoTypeInformation
$list_arti_size | Export-Csv -UseQuotes AsNeeded -Path "./dist/$mode/arti_size.csv" -NoTypeInformation
$list_bin_size  | Export-Csv -UseQuotes AsNeeded -Path "./dist/$mode/bin_size.csv"  -NoTypeInformation