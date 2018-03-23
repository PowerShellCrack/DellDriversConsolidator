## Goal ##
I am trying to compare Dell driver packs that were extracted into a folder ( a very large list) 

The goal is to filter by operating system, model, Dell CAB version (A01, A02, etc), and architecture. 

I wrote a PowerShell script that will parse this folder structure (a small subset of the actual list):

    \\share\drivers\E6530-win10-A01-PXT6R\E6530\win10\x64
	\\share\drivers\E6530-win10-A01-PXT6R\E6530\win10\x86
	\\share\drivers\E7450-win10-A04-DNY52\E7450\win10\x64
	\\share\drivers\E7450-win10-A04-DNY52\E7450\win10\x86
	\\share\drivers\E7470-win10-A05-6K6HR\E7470\win10\x64
	\\share\drivers\E6540-win10-A03-FHWDF\E6540\win10\x64
	\\share\drivers\E6540-win10-A03-FHWDF\E6540\win10\x86
	\\share\drivers\M6700-win10-A02-T08R2\M6700\win10\x64
	\\share\drivers\M6700-win10-A02-T08R2\M6700\win10\x86
	\\share\drivers\E7470-win10-A09-PY2N2\E7470\win10\x64
	\\share\drivers\E6500-win7-A05-JJ15G\E6500\win7\x64
	\\share\drivers\E6500-win7-A05-JJ15G\E6500\win7\x86
	\\share\drivers\E7470-win8.1-A01-DCD7V\E7470\win8.1\x64
	\\share\drivers\9343-Win8.1-A04-HXWH4\9343\Win8.1\x64
	\\share\drivers\E7470-win10-A07-WXGDV\E7470\win10\x64

## Script Breakdown ##
First grab all the folders and add it to a collection:

	$scriptRoot = '\\share\drivers'
	#grab only root folders
	$RootDriverCabs = Get-ChildItem $AllDriversPath | ?{ $_.PSIsContainer }
	
	#create hashtable
	$CabCollection = @()
	
	#loop through folder within root folder and break it apart into an hashtable
    ForEach ($Driver in $RootDriverCabs){
        #$FullDir = $Driver.FullName
        $Model = ($Driver.Name -split '-')[0]
        $OS = ($Driver.Name -split '-')[1]
        $ver = ($Driver.Name -split '-')[2]

        #combine root driver path with model and OS sub-folders
        $FullPath = Join-Path -Path $Driver.FullName -ChildPath "$Model\$OS"

		#if the full path exists get architecture
        If (Test-Path $FullPath){ 
            $arch = Get-ChildItem $FullPath | ForEach-Object {
                $FullDir = "$FullPath\$($_.Name)"
				
				#build object
                $CabTable = New-Object -TypeName PSObject -Property ([ordered]@{
                        Model    = $Model
                        OS       = $OS
                        Ver      = $ver
                        Arch     = $_.Name
                        FullPath = $FullDir
                    })

					#add to object
                    $CabCollection += $CabTable
                }
        } 
		Else{
            Write-host "$FullPath is not found, drivers must have proper naming convention" -ForegroundColor White -BackgroundColor Red
            break
        }   
    }

    Write-host "Collected $($CabCollection.Count) drivers packages"

the Cab Collection result is: 

	Model    : E6530
	OS       : win10
	Ver      : A01
	Arch     : x64
	FullPath : \\share\drivers\E6530-win10-A01-PXT6R\E6530\win10\x64

	Model    : E6530
	OS       : win10
	Ver      : A01
	Arch     : x86
	FullPath : \\share\drivers\E6530-win10-A01-PXT6R\E6530\win10\x86

	Model    : E7450
	OS       : win10
	Ver      : A04
	Arch     : x64
	FullPath : \\share\drivers\E7450-win10-A04-DNY52\E7450\win10\x64

	Model    : E7450
	OS       : win10
	Ver      : A04
	Arch     : x86
	FullPath : \\share\drivers\E7450-win10-A04-DNY52\E7450\win10\x86

	Model    : E7470
	OS       : win10
	Ver      : A05
	Arch     : x64
	FullPath : \\share\drivers\E7470-win10-A05-6K6HR\E7470\win10\x64

	Model    : E6540
	OS       : win10
	Ver      : A03
	Arch     : x64
	FullPath : \\share\drivers\E6540-win10-A03-FHWDF\E6540\win10\x64

	Model    : E6540
	OS       : win10
	Ver      : A03
	Arch     : x86
	FullPath : \\share\drivers\E6540-win10-A03-FHWDF\E6540\win10\x86

	Model    : M6700
	OS       : win10
	Ver      : A02
	Arch     : x64
	FullPath : \\share\drivers\M6700-win10-A02-T08R2\M6700\win10\x64

	Model    : M6700
	OS       : win10
	Ver      : A02
	Arch     : x86
	FullPath : \\share\drivers\M6700-win10-A02-T08R2\M6700\win10\x86

	Model    : E7470
	OS       : win10
	Ver      : A09
	Arch     : x64
	FullPath : \\share\drivers\E7470-win10-A09-PY2N2\E7470\win10\x64

	Model    : E6500
	OS       : win7
	Ver      : A05
	Arch     : x64
	FullPath : \\share\drivers\E6500-win7-A05-JJ15G\E6500\win7\x64

	Model    : E6500
	OS       : win7
	Ver      : A05
	Arch     : x86
	FullPath : \\share\drivers\E6500-win7-A05-JJ15G\E6500\win7\x86

	Model    : E7470
	OS       : win8.1
	Ver      : A01
	Arch     : x64
	FullPath : \\share\drivers\E7470-win8.1-A01-DCD7V\E7470\win8.1\x64

	Model    : 9343
	OS       : Win8.1
	Ver      : A04
	Arch     : x64
	FullPath : \\share\drivers\9343-Win8.1-A04-HXWH4\9343\Win8.1\x64

	Model    : E7470
	OS       : win10
	Ver      : A07
	Arch     : x64
	FullPath : \\share\drivers\E7470-win10-A07-WXGDV\E7470\win10\x64

	
The count is 15 with all architectures

Now I need to filter them. I am then comparing them with other arrays (set as constants:

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
	$DriverCategory = @('audio','chipset','communication','input','network','security','storage')

Based on theses filters I should get:

	5 models with x86 drivers
	2 unsupported drivers: E6500, M6700
	3 unsupported OS: E6500(Win7), 9343(Win8.1), E7470(Win8.1)
	3 drivers in conflict: E7470(A01), E7470(A07), E7470(A09)
	
With filters in place, it should leave me with:

	\\share\drivers\E6530-win10-A01-PXT6R\E6530\win10\x64
	\\share\drivers\E6530-win10-A01-PXT6R\E6530\win10\x86
	\\share\drivers\E7450-win10-A04-DNY52\E7450\win10\x64
	\\share\drivers\E7450-win10-A04-DNY52\E7450\win10\x86
	\\share\drivers\E7470-win10-A05-6K6HR\E7470\win10\x64
	\\share\drivers\E6540-win10-A03-FHWDF\E6540\win10\x64
	\\share\drivers\E6540-win10-A03-FHWDF\E6540\win10\x86
	\\share\drivers\M6700-win10-A02-T08R2\M6700\win10\x64
	\\share\drivers\M6700-win10-A02-T08R2\M6700\win10\x86
	\\share\drivers\E7470-win10-A09-PY2N2\E7470\win10\x64
	\\share\drivers\E6500-win7-A05-JJ15G\E6500\win7\x64
	\\share\drivers\E6500-win7-A05-JJ15G\E6500\win7\x86
	\\share\drivers\E7470-win8.1-A01-DCD7V\E7470\win8.1\x64
	\\share\drivers\9343-Win8.1-A04-HXWH4\9343\Win8.1\x64
	\\share\drivers\E7470-win10-A07-WXGDV\E7470\win10\x64
	
I am able to filter OS, Arch and Model:

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

This leaves me with 6 models, 1 of them having multiple versions of drivers. 

	Model    : E6530
	OS       : win10
	Ver      : A01
	Arch     : x64
	FullPath : \\share\drivers\E6530-win10-A01-PXT6R\E6530\win10\x64

	Model    : E7450
	OS       : win10
	Ver      : A04
	Arch     : x64
	FullPath : \\share\drivers\E7450-win10-A04-DNY52\E7450\win10\x64

	Model    : E7470
	OS       : win10
	Ver      : A05
	Arch     : x64
	FullPath : \\share\drivers\E7470-win10-A05-6K6HR\E7470\win10\x64

	Model    : E6540
	OS       : win10
	Ver      : A03
	Arch     : x64
	FullPath : \\share\drivers\E6540-win10-A03-FHWDF\E6540\win10\x64

	Model    : E7470
	OS       : win10
	Ver      : A09
	Arch     : x64
	FullPath : \\share\drivers\E7470-win10-A09-PY2N2\E7470\win10\x64

	Model    : E7470
	OS       : win10
	Ver      : A07
	Arch     : x64
	FullPath : \\share\drivers\E7470-win10-A07-WXGDV\E7470\win10\x64

After many of hours trying to figure out how to filter the cab versions, i have figured it out, but felt there could be an easier way. here is my code to filter them:


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

Not I only see 4 drivers in my collection. The only next thing to do is grab those drivers and copy them to another folder. This should drop the size down dramatically, eepecially if you don't include video drivers (which you should exclude becuse you should download jsut the three catalyst drivers from (ati,intel,nvidia)

mine went down from 13gb to 3gb. Now the next thing to do is filter the drivers inf even further to grab only the latest....coming soon 


	
