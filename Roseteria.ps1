# Core functions
$pdftotext = "pdftotext"
$opt = " "
$out_dir = "roseteria"

if (Get-Command pdftotxt -ea SilentlyContinue)
{
    $pdftotext = "pdftotxt"
    $opt = " -o "
}

if (!(Get-Command pdftotext -ea SilentlyContinue))
{
    Write-Host "pdftotxt and pdftotext commands don't exist."
    Write-Host "Please install either."
    return;
}

if (!(Test-Path $out_dir))
{
    mkdir $out_dir
}

function Download-Menu($pdf_name)
{
    try
    {
        $url = [String]::Format('https://www.yrp.co.jp/facilities/menu/{0}', $pdf_name)
        Invoke-WebRequest $url -o $pdf_name
    }
    catch
    {
        # 404
        Write-Host "$pdf_name not exist"
        return $false
    }
    return $true
}

function Parse-Pdf($pdftotext, $pdf_path, $opt)
{
    if (!(Test-Path $pdf_path))
    {
        Write-Host "$pdf_path doesn't exist"
        return $false
    }
    Invoke-Expression "$pdftotext $pdf_path $opt temp.txt"
    $dates = Select-String -Pattern "^[1-9]{1,2}月[1-9]{1,2}日" ./temp.txt

    $date = $dates[0].Line.Split("月").Split("日")
    $year = $( Get-Date ).Year
    $month = [Convert]::ToInt16($date[0])
    $day = [Convert]::ToInt16($date[1])
    if ( $pdf_path.StartsWith("lunch"))
    {
        $meal = "lunch"
    }
    else
    {
        $meal = "dinner"
    }
    # lunchYYYYMMDD_hash.pdf
    $hash = (Get-FileHash -Algorithm SHA256 ./$pdf_path).hash
    $new_path = [String]::Format('{0}{1:0000}{2:00}{3:00}_{4}.pdf', $meal, $year, $month, $day, $hash)
    if (Test-Path $out_dir/$new_path)
    {
        Write-Host "$out_dir/$new_path already exists"
        Remove-Item $pdf_path
        Remove-Item "temp.txt"
        return $false
    }
    Move-Item $pdf_path $out_dir/$new_path
    Write-Host "$new_path is created"
    Remove-Item "temp.txt"
    return $true
}

function Get-Menu($pdf_name)
{
    if (Download-Menu($pdf_name))
    {
        Parse-Pdf $pdftotext $pdf_name $opt
    }
}

function Parse-EventMenu($pdf_path)
{
    if (!(Test-Path $pdf_path))
    {
        Write-Host "$pdf_path doesn't exist"
        return $false
    }
    $new_hash = (Get-FileHash -Algorithm SHA256 ./$pdf_path).hash
    $is_exists = $false
    $pdfs = Get-ChildItem $out_dir/eventmenu*.pdf
    foreach ($d in $pdfs)
    {
        $name = $d.name
        $idx = $name.IndexOf("_")
        $now_hash = ""
        if ($idx -eq -1)
        {
            continue
        }
        $now_hash = $name.Substring($idx + 1, $name.Length - $idx - 5)
        if ($new_hash -eq $now_hash)
        {
            $is_exists = $true
            break
        }
    }
    if (!$is_exists)
    {
        $date = Get-Date -Format "yyyyMMdd"
        # eventmenuYYYYMMDD_hash.pdf
        $new_path = [String]::Format('eventmenu{0}_{1}.pdf', $date, $new_hash)
        Move-Item $pdf_path $out_dir/$new_path
    }
    else
    {
        Write-Host "$pdf_path is already exists"
        Remove-Item $pdf_path
        return $false
    }
    return $true
}

function Get-EventMenu($pdf_name)
{
    if (Download-Menu($pdf_name))
    {
        Parse-EventMenu $pdf_name
    }
}
