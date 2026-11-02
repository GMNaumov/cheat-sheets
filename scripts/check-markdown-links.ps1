param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$problems = [System.Collections.Generic.List[object]]::new()
$anchorCache = @{}
$inlinePattern = '!?' + '\[[^\]]*\]' + '\((?<target><[^>]+>|[^)\s]+)(?:\s+["''][^"'']*["''])?\)'
$referencePattern = '^\s*\[[^\]]+\]:\s*(?<target><[^>]+>|\S+)'

function Get-MarkdownAnchors {
    param([string]$Path)

    if ($anchorCache.ContainsKey($Path)) {
        return $anchorCache[$Path]
    }

    $anchors = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $duplicates = @{}

    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line -notmatch '^\s{0,3}#{1,6}\s+(?<heading>.+?)\s*#*\s*$') {
            continue
        }

        $slug = $Matches['heading'].ToLowerInvariant()
        $slug = [regex]::Replace($slug, '<[^>]+>', '')
        $slug = [regex]::Replace($slug, '[^\p{L}\p{Nd}\s_-]', '')
        $slug = [regex]::Replace($slug.Trim(), '\s+', '-')

        if ($duplicates.ContainsKey($slug)) {
            $duplicates[$slug]++
            $slug = "$slug-$($duplicates[$slug])"
        }
        else {
            $duplicates[$slug] = 0
        }

        [void]$anchors.Add($slug)
    }

    $anchorCache[$Path] = $anchors
    return $anchors
}

function Test-LocalLink {
    param(
        [System.IO.FileInfo]$Source,
        [int]$LineNumber,
        [string]$RawTarget
    )

    $target = $RawTarget.Trim().Trim('<', '>')
    if ($target -match '^[a-z][a-z0-9+.-]*:' -or $target.StartsWith('//')) {
        return
    }

    $parts = $target -split '#', 2
    $pathPart = [Uri]::UnescapeDataString($parts[0])
    $fragment = if ($parts.Count -eq 2) { [Uri]::UnescapeDataString($parts[1]) } else { '' }

    if ([string]::IsNullOrWhiteSpace($pathPart)) {
        $resolvedPath = $Source.FullName
    }
    elseif ($pathPart.StartsWith('/')) {
        $resolvedPath = Join-Path $rootPath $pathPart.TrimStart('/')
    }
    else {
        $resolvedPath = Join-Path $Source.DirectoryName $pathPart
    }

    $relativeSource = $Source.FullName.Substring($rootPath.Length + 1)
    if (-not (Test-Path -LiteralPath $resolvedPath)) {
        $problems.Add([PSCustomObject]@{
                Source  = $relativeSource
                Line    = $LineNumber
                Target  = $target
                Problem = 'path not found'
            })
        return
    }

    if (-not [string]::IsNullOrWhiteSpace($fragment) -and
        [System.IO.Path]::GetExtension($resolvedPath) -eq '.md') {
        $resolvedFile = (Resolve-Path -LiteralPath $resolvedPath).Path
        $anchors = Get-MarkdownAnchors -Path $resolvedFile
        if (-not $anchors.Contains($fragment)) {
            $problems.Add([PSCustomObject]@{
                    Source  = $relativeSource
                    Line    = $LineNumber
                    Target  = $target
                    Problem = 'anchor not found'
                })
        }
    }
}

Get-ChildItem -LiteralPath $rootPath -Recurse -File -Filter '*.md' |
    Where-Object { $_.FullName -notlike '*\.git\*' } |
    ForEach-Object {
        $source = $_
        $lineNumber = 0
        $fenceMarker = ''
        $fenceLength = 0

        foreach ($line in Get-Content -LiteralPath $source.FullName -Encoding UTF8) {
            $lineNumber++

            if ($fenceLength -eq 0 -and $line -match '^\s{0,3}(?<marker>`{3,}|~{3,})') {
                $fenceMarker = $Matches['marker'].Substring(0, 1)
                $fenceLength = $Matches['marker'].Length
                continue
            }

            if ($fenceLength -gt 0) {
                $closingPattern = '^\s{0,3}' + [regex]::Escape($fenceMarker) +
                    '{' + $fenceLength + ',}\s*$'
                if ($line -match $closingPattern) {
                    $fenceMarker = ''
                    $fenceLength = 0
                }
                continue
            }

            foreach ($match in [regex]::Matches($line, $inlinePattern)) {
                Test-LocalLink -Source $source -LineNumber $lineNumber -RawTarget $match.Groups['target'].Value
            }

            if ($line -match $referencePattern) {
                Test-LocalLink -Source $source -LineNumber $lineNumber -RawTarget $Matches['target']
            }
        }
    }

if ($problems.Count -gt 0) {
    $problems | Format-Table -AutoSize
    Write-Error "Found $($problems.Count) invalid local Markdown link(s)."
    exit 1
}

Write-Output 'All local Markdown links and anchors are valid.'
