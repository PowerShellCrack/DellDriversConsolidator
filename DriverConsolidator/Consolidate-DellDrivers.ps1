#========================================================================
#
#       Title: Dell Driver Consolidator
#     Created: 2018-03-22
#      Author: Richard tracy
#
#
# GOALS:
# Inventory all extracted Dell Driver CABs in folder. Compare them, copying only unique folders to AIO folder.
# Then parse all driver inf and consolidate the unique ones. 
#
# Name convention must be
# [model]-[OS]-[ver]-[build]\[model]\[OS]\[arch]\[drivertype]
#
# e.g.
# E6530-win10-A01-PXT6R\E6530\win10\x64
# E6540-win10-A03-FHWDF\E6540\win10\x86
# 
#>
#========================================================================

Function Copy-WithProgress{
    [CmdletBinding()]
    Param
    (
      [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=0)]
    $Source,
      [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=0)]
    $Destination
    )
    $Source=$Source.tolower()
    $Filelist=Get-Childitem $Source –Recurse
    $Total=$Filelist.count
    $Position=0
    foreach ($File in $Filelist){
        $Filename=$File.Fullname.replace($Source,'')
        $DestinationFile=($Destination+$Filename)
        Write-Progress -Activity "Copying data from $source to $Destination" -Status "Copying File $Filename" -PercentComplete (($Position/$total)*100)
        Copy-Item $File.FullName -Destination $DestinationFile -Recurse -Force
        $Position++
    }
}

##*===============================================
##* VARIABLE DECLARATION
##*===============================================
$Dated = (Get-Date -Format yyyyMMdd)

## Variables: Script Name and Script Paths
[string]$scriptPath = $MyInvocation.MyCommand.Definition
[string]$scriptName = [IO.Path]::GetFileNameWithoutExtension($scriptPath)
[string]$scriptFileName = Split-Path -Path $scriptPath -Leaf
[string]$scriptRoot = Split-Path -Path $scriptPath -Parent
[string]$invokingScript = (Get-Variable -Name 'MyInvocation').Value.ScriptName

$scriptRoot = '\\filer\s3isoftware\Software\drivers\DriverConsolidatorTest'
#Get required folder and File paths
[string]$AllDriversPath = Join-Path -Path $scriptRoot -ChildPath 'AllDrivers'
[string]$AIODriversPath = Join-Path -Path $scriptRoot -ChildPath 'AIODrivers'
    New-Item $AIODriversPath -ItemType Directory -ErrorAction SilentlyContinue
[string]$WorkingPath = Join-Path -Path $scriptRoot -ChildPath 'Working'
    New-Item $WorkingPath -ItemType Directory -ErrorAction SilentlyContinue

If(!(Test-Path $AllDriversPath)){Write-Host "AllDrivers folder not found, unable to continue." -ForegroundColor White -BackgroundColor Red; Break}

#Specify which type of folders to look for based on Operating System.
#Supported Values: Win7, Win8, Win8.1, Win10
$OSCheck = @('Win10')

#Specify which type of folders to look for based on architecture.
#Supported Values: x86,x64
$archCheck = @('x64')

#Break it down even further based on model.
$FilterByModel = $true 
$DellModels = @('E7470','E7450','E6530','E6540')

#search driver types
$FilterbyDriverCategory = $true
$DriverCategory = @('audio','chipset','communication','input','network','security','storage','video')

#Get all drivers folders and buuld a collection database for all details
$RootDriverCabs = Get-ChildItem $AllDriversPath | ?{ $_.PSIsContainer }
If ($RootDriverCabs){
    $CabCollection = @()
    ForEach ($Driver in $RootDriverCabs){
        #$FullDir = $Driver.FullName
        $Model = ($Driver.Name -split '-')[0]
        $OS = ($Driver.Name -split '-')[1]
        $ver = ($Driver.Name -split '-')[2]

        #combine Root driver path with model and OS subfolders
        $FullPath = Join-Path -Path $Driver.FullName -ChildPath "$Model\$OS"

        If (Test-Path $FullPath){ #if naming convention matches
            $arch = Get-ChildItem $FullPath | ForEach-Object {
                $FullDir = "$FullPath\$($_.Name)"

                $CabTable = New-Object -TypeName PSObject -Property ([ordered]@{
                        Model    = $Model
                        OS       = $OS
                        Ver      = $ver
                        Arch     = $_.Name
                        FullPath = $FullDir
                    })

                    $CabCollection += $CabTable
                }
        } Else{
            Write-host "$FullPath is not found, drivers must have proper naming convention" -ForegroundColor White -BackgroundColor Red
            break
        }   
    }

    Write-host "$($CabCollection.Count) drivers packages in collection" -ForegroundColor Cyan

    #Create new hashtable for temporary use
    $CabCollection_oschk = @()
    Foreach ($driverSet in $CabCollection){ 
        #filter by Operating System
        $OSFound = Compare-Object $driverSet.OS $OSCheck -IncludeEqual | Where-Object {$_.SideIndicator -eq "=="}
        If($OSFound){
            #write-host $driverSet.FullPath
            $CabTable_oschk = New-Object -TypeName PSObject -Property ([ordered]@{
                    Model    = $driverSet.Model
                    OS       = $driverSet.OS
                    Ver      = $driverSet.Ver
                    Arch     = $driverSet.Arch
                    FullPath = $driverSet.FullPath
                })

                $CabCollection_oschk += $CabTable_oschk
        }  
            
    }
    #Rebuild original collection
    $CabCollection = $CabCollection_oschk
    Write-host "$($CabCollection.Count) drivers filtered for specified operating systems" -ForegroundColor Cyan

    #Create new hashtable for temporary use
    $CabCollection_archchk = @()
    Foreach ($driverSet in $CabCollection){ 
        #filter by architecture
        $ArchFound = Compare-Object $driverSet.Arch $archCheck -IncludeEqual | Where-Object {$_.SideIndicator -eq "=="}
        If($ArchFound){
            #write-host $driverSet.FullPath
            $CabTable_archchk = New-Object -TypeName PSObject -Property ([ordered]@{
                    Model    = $driverSet.Model
                    OS       = $driverSet.OS
                    Ver      = $driverSet.Ver
                    Arch     = $driverSet.Arch
                    FullPath = $driverSet.FullPath
                })

                $CabCollection_archchk += $CabTable_archchk
        }  
            
    }
    #Rebuild original collection
    $CabCollection = $CabCollection_archchk
    Write-host "$($CabCollection.Count) drivers filtered for specified architecture" -ForegroundColor Cyan



    If ($FilterByModel){
        #Create new hashtable for temporary use
        $CabCollection_modelchk = @()
        Foreach ($driverSet in $CabCollection){ 
            #filter by model
            $ModelFound = Compare-Object $driverSet.Model $DellModels -IncludeEqual | Where-Object {$_.SideIndicator -eq "=="}
            If($ModelFound){
                #write-host $driverSet.FullPath
                $CabTable_modelchk = New-Object -TypeName PSObject -Property ([ordered]@{
                        Model    = $driverSet.Model
                        OS       = $driverSet.OS
                        Ver      = $driverSet.Ver
                        Arch     = $driverSet.Arch
                        FullPath = $driverSet.FullPath
                    })

                    $CabCollection_modelchk += $CabTable_modelchk
            }  
            
        }
        #Rebuild original collection
        $CabCollection = $CabCollection_modelchk
        Write-host "$($CabCollection.Count) drivers filtered for specified models" -ForegroundColor Cyan
    }

    #Create new hashtable for temporary use
    $CabCollection_verchk = @()
    

    Foreach ($driverSet in ($CabCollection | Group-object Model | Where-Object {$_.Count -eq 1}) ){
        $CabTable_verchk = New-Object -TypeName PSObject -Property ([ordered]@{
            Model    = $driverSet.Group.Model
            OS       = $driverSet.Group.OS
            Ver      = $driverSet.Group.Ver
            Arch     = $driverSet.Group.Arch
            FullPath = $driverSet.Group.FullPath
        })

        $CabCollection_verchk += $CabTable_verchk
    }

    Foreach ($driverSet in ($CabCollection | Group-object Model | Where-Object {$_.Count -gt 1}) ){
        $SimilarModels = $driverSet | Foreach {$_.Group}
        $LatestVersion = ($SimilarModels.ver | measure -Maximum | Select -First 1).Maximum
        Foreach ($Model in ($SimilarModels | Where-Object {$_.Ver -eq $LatestVersion}) ){
            $CabCollection_verchk += $Model
        }
    }

    #Rebuild original collection
    $CabCollection = $CabCollection_verchk
    Write-host "$($CabCollection.Count) drivers filtered for latest version" -ForegroundColor Cyan

    #Remove-Item "$AIODriversPath\*" -Recurse -Force
    $copycnt = 1
    $cabTotal = $CabCollection.Count

    Foreach ($driverSet in $CabCollection){
        $SourcePath = $driverSet.FullPath
        $archTotal = $archCheck.Count

        Foreach($arch in $archCheck){
            $ArchDestPath = "$AIODriversPath\$arch"
            New-Item -Path $ArchDestPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
            
            If ($FilterbyDriverCategory){
                $catTotal = $DriverCategory.Count
                
                Foreach ($cat in $DriverCategory){
                    $catSourcePath = "$SourcePath\$cat"
                    $catDestPath = "$ArchDestPath\$cat"
                    New-Item -Path $catDestPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
                    
                    If(Test-Path $catSourcePath){
                        Write-Host "COPY: $copycnt of $($catTotal*$cabTotal*$archTotal): " -NoNewline -ForegroundColor Cyan
                        Write-Host "Copying [$arch] files from [$catSourcePath]" -ForegroundColor DarkCyan
                        Write-Host "                    to [$catDestPath]"  -ForegroundColor DarkCyan             
                        Write-Host "`n"
                        
                        Copy-WithProgress -Source $catSourcePath -Destination $catDestPath
                        $copycnt++
                        #Windows compy UI
                        #$FOF_CREATEPROGRESSDLG = "&H0&"
                        #$objShell = New-Object -ComObject "Shell.Application"
                        #$objFolder = $objShell.NameSpace($AIODriversPath) 
                        #$objFolder.CopyHere($driverSet.FullPath, $FOF_CREATEPROGRESSDLG)
                    }
                    Else{
                        Write-Host "No folder named [$cat] was found in" -ForegroundColor DarkYellow
                        Write-Host "                [$SourcePath], skipping " -ForegroundColor DarkYellow
                        Write-Host "`n"
                    }
                }
            }
            Else{
                Write-Host "Copying [$arch] files from [$SourcePath]" -ForegroundColor DarkCyan
                Write-Host "              to [$ArchDestPath]"  -ForegroundColor DarkCyan

                Copy-WithProgress -Source $SourcePath -Destination $ArchDestPath
                $copycnt++
            }
        }
        $cabCount ++
    }

}
Else{
    Write-Host "No drivers found. Extract drivers to [$AllDriversPath] and rerun script" -ForegroundColor White -BackgroundColor Red; Break
}
