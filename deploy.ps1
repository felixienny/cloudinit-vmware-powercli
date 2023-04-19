param (
    # Server
    [Parameter(Mandatory)]
    [string]$Server,

    # VM template
    [Parameter(Mandatory)]
    [string]$Template,

    # VM name
    [Parameter(Mandatory)]
    [string]$Name,

    # VM folder
    [Parameter(Mandatory)]
    [string]$Folder,
    
    # ResourcePool: VMHost, Cluster, ResourcePool, or VApp objects
    [Parameter(Mandatory)]
    [string]$ResourcePool,


    # Number of CPU
    [Parameter()]
    [int]$NumCPU,

    # Memory in GB
    [Parameter()]
    [Decimal]$MemoryGB,
    
    # Disk in GB
    [Parameter()]
    [Decimal]
    $DiskGB,

    # Portgroup
    [Parameter()]
    [string]$Portgroup
)




function SetCloudImgData {

    $UserDataFile = "$($PWD.Path)\$($VM)\userdata.yml"
    $MetaDataFile = "$($PWD.Path)\$($VM)\metadata.yml"

    if (-not (Test-Path -Path $MetaDataFile) -and -not (Test-Path -Path $UserDataFile)) {
        Write-Host "Problem in file path for user or metadata file"
        Write-Host "Please be aware the files should be in the same folder as the VM name and named metadata.yml and userdata.yml"
        Exit
    }

    $UserData = Get-Content -Path $UserDataFile -Encoding UTF8 -Raw
    $MetaData = Get-Content -Path $MetaDataFile -Encoding UTF8 -Raw

    $UserDataEncoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($UserData))
    $MetaDataEncoded = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($MetaData))

    function SetGuestInfoParam {
        param (
            $VM, $Name, $Value
        )
        $setting = Get-AdvancedSetting -Entity $VM -Name $Name
        if ($setting) {
            $setting | Set-AdvancedSetting -Value $Value -Confirm:$false 
        }
        else {
            New-AdvancedSetting -Entity $VM -Name $Name -Value $Value -Confirm:$false 
        }
    }

    SetGuestInfoParam -VM $vm -Name "guestinfo.metadata.encoding" -Value "base64"
    SetGuestInfoParam -VM $vm -Name "guestinfo.metadata" -Value $MetaDataEncoded
    SetGuestInfoParam -VM $vm -Name "guestinfo.userdata.encoding" -Value "base64"
    SetGuestInfoParam -VM $vm -Name "guestinfo.userdata" -Value $UserDataEncoded
}

if (-not ($Env:VICredentials)) {
    Write-Host "Please set the VICredentials environment variable."
    Exit
}

if (-not (Test-Path -Type Folder -Path $($PWD)\$($VM))) {
    Write-Host "VM folder not found. Please create a folder with the VM name and place the metadata.yml and userdata.yml files in it."
    Exit
}

# Connect to vCenter
Write-Host "Connecting to $Server"
Connect-VIServer -Server $Server -Force 

# Create VM
Write-Host "Creating VM $Name"
$VM = New-VM -Name $Name -Template $Template -ResourcePool $ResourcePool -Location $Folder


# Check if VM was created
if (-not $VM) {
    Write-Host "VM $Name not created, exiting..."
    Exit
}
Write-Host "VM $Name created"



# Customize VM settings
if ($NumCPU -or $MemoryGB) {
    Write-Host "Customizing VM $Name"
    try {
        if ($NumCPU) {
            Write-Host "Setting $NumCPU CPU"
            $VM | Set-VM -NumCPU $NumCPU -Confirm:$false
        }
        if ($MemoryGB) {
            Write-Host "Setting $MemoryGB GB of memory"
            $VM | Set-VM -MemoryGB $MemoryGB -Confirm:$false         
        }
    }
    catch {
        Write-Host "Error customizing VM $Name"
    }
}



# Set VM disk
Write-Host "Adding disk to VM $Name"
try {
    if ($DiskGB) {
        Write-Host "Setting $DiskGB GB of disk"
        $VM | Get-HardDisk | Set-HardDisk -CapacityGB $DiskGB -Confirm:$false
    }
}
catch {
    Write-Host "Error adding disk to VM $Name"
}


# Set network adapter
if ($Portgroup) {
    Write-Host "Setting up network adapter on VM $Name"
    $VM | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $Portgroup -Confirm:$false
}

# Set cloud-init data
Write-Host "Setting cloud-init data for $Name"
try {
    SetCloudImgData
    Write-Host "Cloud-init data set for $Name"
}
catch {
    Write-Host "Error setting cloud-init data for $Name"
}
