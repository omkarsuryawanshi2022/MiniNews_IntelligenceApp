param(
    [Alias('d')]
    [string] $Device,
    [switch] $Release
)

$configPath = Join-Path (Split-Path $PSScriptRoot -Parent) ".env"
if (-not (Test-Path $configPath)) {
    throw "Missing .env. Copy .env.example to .env and add your NewsAPI key."
}

$settings = @{}
foreach ($line in Get-Content $configPath) {
    if ($line -match '^\s*(NEWS_API_KEY|NEWS_COUNTRY|NEWS_SEARCH_SORT)\s*=\s*(.*?)\s*$') {
        $settings[$Matches[1]] = $Matches[2].Trim('"').Trim("'")
    }
}

if ([string]::IsNullOrWhiteSpace($settings['NEWS_API_KEY'])) {
    throw "NEWS_API_KEY is missing from .env."
}

$defines = @("--dart-define=NEWS_API_KEY=$($settings['NEWS_API_KEY'])")
foreach ($name in @('NEWS_COUNTRY', 'NEWS_SEARCH_SORT')) {
    if (-not [string]::IsNullOrWhiteSpace($settings[$name])) {
        $defines += "--dart-define=$name=$($settings[$name])"
    }
}

$flutterArguments = @('run')
if (-not [string]::IsNullOrWhiteSpace($Device)) {
    $flutterArguments += @('-d', $Device)
}
if ($Release) {
    $flutterArguments += '--release'
}
$flutterArguments += $defines

flutter @flutterArguments
