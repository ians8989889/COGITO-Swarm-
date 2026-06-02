# ============================================
# token_monitor.ps1 — Windows PowerShell 版
# 追蹤 token 使用量 (Bug 1 修正)
# 用法: .\token_monitor.ps1 daily
# Token 花費: $0
# ============================================

param(
    [string]$Mode = "daily"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Split-Path -Parent $ScriptDir

$ConfigFile = Join-Path $SkillDir "config.env"
if (Test-Path $ConfigFile) {
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match '^([A-Z_]+)="?([^"]*)"?$') {
            Set-Variable -Name $Matches[1] -Value $Matches[2] -Scope Script
        }
    }
}

$BotName = if ($env:BOT_NAME) { $env:BOT_NAME } else { "unknown" }
$TokenLog = if ($env:TOKEN_LOG_PATH) { $env:TOKEN_LOG_PATH } else { Join-Path $SkillDir "token_usage.log" }
$AlertThreshold = if ($env:TOKEN_ALERT_THRESHOLD_DAILY) { [double]$env:TOKEN_ALERT_THRESHOLD_DAILY } else { 5.00 }

$Today = Get-Date -Format "yyyy-MM-dd"
$Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"

if ($Mode -eq "daily") {
    $todayLogs = @()
    if (Test-Path $TokenLog) {
        $todayLogs = Get-Content $TokenLog | Where-Object { $_ -match $Today }
    }
    
    $count = $todayLogs.Count
    
    Write-Host "📊 ${BotName} Token 日報 (${Today})"
    Write-Host "   今日記錄數: $count"
    
    if ($count -gt 100) {
        Write-Host "⚠️  今日請求數偏高 (${count})，建議檢查！"
    }
}

"[${Timestamp}] ${BotName} token=logged" | Out-File -Append -FilePath $TokenLog -Encoding UTF8

Write-Host "✅ Token 記錄完成"
