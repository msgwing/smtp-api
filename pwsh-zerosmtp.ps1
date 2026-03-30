# pwsh-zerosmtp.ps1
# PowerShell 7.5+ Send-MailKitMessage 2.2 - ZeroSMTP mx.msgwing.com:587 STARTTLS
# Production-ready | Let's Encrypt | PSCredential, params block
#Requires -Version 7.5
#Requires -Module Send-MailKitMessage

param(
    [Parameter(Mandatory=$false)]
    [string]$Username = $env:USERNAME,

    [Parameter(Mandatory=$false)]
    [string]$Password = $env:PASSWORD,

    [Parameter(Mandatory=$false)]
    [string]$From = $env:FROM,

    [Parameter(Mandatory=$false)]
    [string]$To = $env:TO,

    [Parameter(Mandatory=$false)]
    [string]$Subject = $env:SUBJECT,

    [Parameter(Mandatory=$false)]
    [string]$HtmlBody = @"
<html><body><h1>Hello from ZeroSMTP!</h1><p>This is an HTML email sent via mx.msgwing.com:587 STARTTLS</p></body></html>
"@
)

# Defaults
if (-not $Username) { $Username = 'your-username' }
if (-not $Password) { $Password = 'your-password' }
if (-not $From)     { $From    = 'sender@example.com' }
if (-not $To)       { $To      = 'recipient@example.com' }
if (-not $Subject)  { $Subject = 'Test Email from ZeroSMTP' }

# Create PSCredential
$credential = [PSCredential]::new(
    $Username,
    (ConvertTo-SecureString $Password -AsPlainText -Force)
)

try {
    # Prepare parameters for Send-MailKitMessage
    $sendMailKitSplat = @{
        SMTPServer    = 'mx.msgwing.com'
        Port          = 587
        UseSsl        = $false  # STARTTLS requires $false
        Credential    = $credential
        From          = $From
        To            = $To
        Subject       = $Subject
        TextBody      = 'Hello from ZeroSMTP! This is plain text.'
        HtmlBody      = $HtmlBody
        BodyEncoding  = [System.Text.Encoding]::UTF8
        ErrorAction   = 'Stop'
        Verbose       = $false
    }

    # Send email
    Send-MailKitMessage @sendMailKitSplat
    Write-Host "Email sent successfully via ZeroSMTP" -ForegroundColor Green
    exit 0
}
catch [System.Net.Mail.SmtpException] {
    Write-Error "SMTP error: $_" -ErrorAction Continue
    exit 1
}
catch [System.UnauthorizedAccessException] {
    Write-Error "Authentication failed: $_" -ErrorAction Continue
    exit 1
}
catch {
    Write-Error "Unexpected error: $_" -ErrorAction Continue
    exit 1
}
