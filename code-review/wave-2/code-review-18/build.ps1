$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot 'article')
try {
    & latexmk -pdf -interaction=nonstopmode -halt-on-error audit.tex
    if ($LASTEXITCODE -ne 0) { throw "latexmk failed with exit code $LASTEXITCODE" }
}
finally {
    Pop-Location
}
