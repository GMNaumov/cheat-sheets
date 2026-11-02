param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$problems = [System.Collections.Generic.List[object]]::new()

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error 'Docker CLI with Compose is required to validate Compose paths.'
    exit 1
}

function Resolve-ComposePath {
    param(
        [string]$BasePath,
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $BasePath $Path))
}

function Test-ComposePath {
    param(
        [string]$Compose,
        [string]$Field,
        [string]$BasePath,
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return
    }

    $resolvedPath = Resolve-ComposePath -BasePath $BasePath -Path $Path
    $insideRoot = $resolvedPath -eq $rootPath -or
        $resolvedPath.StartsWith(
            $rootPath + [System.IO.Path]::DirectorySeparatorChar,
            [System.StringComparison]::OrdinalIgnoreCase
        )

    if (-not $insideRoot -or -not (Test-Path -LiteralPath $resolvedPath)) {
        $problems.Add([PSCustomObject]@{
                Compose = $Compose
                Field   = $Field
                Path    = $Path
                Problem = if ($insideRoot) { 'path not found' } else { 'path leaves repository' }
            })
    }
}

Get-ChildItem -LiteralPath $rootPath -Recurse -File |
    Where-Object {
        $_.Name -in @('compose.yaml', 'compose.yml', 'docker-compose.yaml', 'docker-compose.yml') -and
        $_.FullName -notmatch '[\\/]\.git[\\/]'
    } |
    Sort-Object FullName |
    ForEach-Object {
        $composeFile = $_
        $relativeCompose = $composeFile.FullName.Substring($rootPath.Length + 1)
        $configJson = & docker compose -f $composeFile.FullName config --format json 2>&1 | Out-String

        if ($LASTEXITCODE -ne 0) {
            $problems.Add([PSCustomObject]@{
                    Compose = $relativeCompose
                    Field   = 'config'
                    Path    = '-'
                    Problem = $configJson.Trim()
                })
            return
        }

        $config = $configJson | ConvertFrom-Json
        foreach ($serviceProperty in $config.services.PSObject.Properties) {
            $serviceName = $serviceProperty.Name
            $service = $serviceProperty.Value

            if ($null -ne $service.build) {
                $buildContext = if ($service.build -is [string]) {
                    $service.build
                }
                else {
                    $service.build.context
                }

                Test-ComposePath -Compose $relativeCompose -Field "services.$serviceName.build.context" `
                    -BasePath $composeFile.DirectoryName -Path $buildContext

                if ($service.build -isnot [string] -and $service.build.dockerfile) {
                    $resolvedContext = Resolve-ComposePath -BasePath $composeFile.DirectoryName -Path $buildContext
                    Test-ComposePath -Compose $relativeCompose -Field "services.$serviceName.build.dockerfile" `
                        -BasePath $resolvedContext -Path $service.build.dockerfile
                }
            }

            foreach ($volume in @($service.volumes)) {
                if ($volume.type -eq 'bind') {
                    Test-ComposePath -Compose $relativeCompose -Field "services.$serviceName.volumes.source" `
                        -BasePath $composeFile.DirectoryName -Path $volume.source
                }
            }

            foreach ($envFile in @($service.env_file)) {
                $envPath = if ($envFile -is [string]) { $envFile } else { $envFile.path }
                Test-ComposePath -Compose $relativeCompose -Field "services.$serviceName.env_file" `
                    -BasePath $composeFile.DirectoryName -Path $envPath
            }
        }
    }

if ($problems.Count -gt 0) {
    $problems | Format-Table -AutoSize
    Write-Error "Found $($problems.Count) Compose configuration problem(s)."
    exit 1
}

Write-Output 'All Compose paths are valid.'
