# Регрессионные проверки валидаторов без запуска контейнеров и загрузки образов.
$ErrorActionPreference = 'Stop'
$shell = (Get-Process -Id $PID).Path
$markdownValidator = Join-Path $PSScriptRoot 'check-markdown-links.ps1'
$composeValidator = Join-Path $PSScriptRoot 'check-compose-paths.ps1'
$tempBase = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath())
$testRoot = Join-Path $tempBase ('cheat-sheets-validators-' + [guid]::NewGuid())
$utf8 = New-Object System.Text.UTF8Encoding($false)
$count = 0

function Write-Fixture {
    param([string]$Path, [string]$Content)
    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Test-Validator {
    param([string]$Name, [string]$Script, [string]$Root, [bool]$ShouldPass)
    $ErrorActionPreference = 'Continue'
    $output = & $shell -NoProfile -ExecutionPolicy Bypass -File $Script -Root $Root 2>&1 | Out-String
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    if (($code -eq 0) -ne $ShouldPass) {
        throw "${Name}: unexpected exit code ${code}.`n$output"
    }
    $script:count++
    Write-Output "PASS: $Name"
}

try {
    $markdownRoot = Join-Path $testRoot 'markdown'
    $markdownPath = Join-Path $markdownRoot 'README.md'
    Write-Fixture $markdownPath "# One`n[Link](#one)`n[Cached link](#one)`n"
    Test-Validator 'single heading anchor and cache' $markdownValidator $markdownRoot $true
    Write-Fixture $markdownPath "# One`n[Link](#missing)`n"
    Test-Validator 'missing anchor' $markdownValidator $markdownRoot $false
    Write-Fixture $markdownPath @'
# One
```markdown
## Hidden
```
[Link](#hidden)
'@
    Test-Validator 'fenced heading is not an anchor' $markdownValidator $markdownRoot $false
    Write-Fixture $markdownPath @'
# One
## One
## One-1
[Link](#one-1-1)
'@
    Test-Validator 'colliding heading suffixes' $markdownValidator $markdownRoot $true
    Write-Fixture $markdownPath "# One`n[Link](#One)`n"
    Test-Validator 'anchor case matters' $markdownValidator $markdownRoot $false

    $composeRoot = Join-Path $testRoot 'compose'
    $composePath = Join-Path $composeRoot 'compose.yaml'
    Write-Fixture $composePath @'
services:
  app:
    image: alpine
    environment:
      OPTIONAL_VALUE: ${CHEAT_SHEETS_VALIDATOR_UNSET:-}
'@
    Test-Validator 'valid Compose' $composeValidator $composeRoot $true
    Write-Fixture $composePath @'
services:
  app:
    image: alpine
    environment:
      OPTIONAL_VALUE: ${CHEAT_SHEETS_VALIDATOR_UNSET}
'@
    Test-Validator 'Compose warning on stderr' $composeValidator $composeRoot $true
    Write-Fixture $composePath "services: [invalid`n"
    Test-Validator 'invalid Compose' $composeValidator $composeRoot $false
    Write-Fixture $composePath @'
services:
  app:
    build: .
'@
    Test-Validator 'missing default Dockerfile' $composeValidator $composeRoot $false
    Write-Fixture (Join-Path $composeRoot 'Dockerfile') "FROM alpine`n"
    Test-Validator 'existing default Dockerfile' $composeValidator $composeRoot $true
    Write-Fixture $composePath @'
services:
  app:
    image: alpine
    profiles: [optional]
    volumes:
      - ./missing:/data
'@
    Test-Validator 'missing bind mount in profile' $composeValidator $composeRoot $false
    Write-Fixture $composePath @'
services:
  app:
    image: alpine
    env_file: ../outside.env
'@
    Write-Fixture (Join-Path $testRoot 'outside.env') "VALUE=example`n"
    Test-Validator 'env_file outside repository' $composeValidator $composeRoot $false

    # Подмена Docker воспроизводит предупреждение с кодом 0 и повреждённый JSON.
    $mockScript = Join-Path $testRoot 'mock-docker.ps1'
    $mockTemplate = @'
param([string]$Root)
function docker {
    $outputIndex = [array]::IndexOf($args, '--output')
    [IO.File]::WriteAllText($args[$outputIndex + 1], '__JSON__')
    Write-Error 'Docker warning' -ErrorAction Continue
    $global:LASTEXITCODE = 0
}
& '__VALIDATOR__' -Root $Root
'@
    Write-Fixture $composePath "services:`n  app:`n    image: alpine`n"
    $mockTemplate = $mockTemplate.Replace('__VALIDATOR__', $composeValidator.Replace("'", "''"))
    Write-Fixture $mockScript ($mockTemplate.Replace('__JSON__', '{"services":{"app":{"image":"alpine"}}}'))
    Test-Validator 'warning does not corrupt JSON' $mockScript $composeRoot $true
    Write-Fixture $mockScript ($mockTemplate.Replace('__JSON__', 'broken JSON'))
    Test-Validator 'malformed JSON fails validation' $mockScript $composeRoot $false
    Write-Output "All $count validator regression checks passed."
}
finally {
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
    if (-not $resolvedTestRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -or
        (Split-Path -Leaf $resolvedTestRoot) -notlike 'cheat-sheets-validators-*') {
        throw "Unexpected cleanup path: $resolvedTestRoot"
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) {
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
