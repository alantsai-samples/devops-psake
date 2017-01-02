function Get-PackagePath {
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)]$packagesDirectoryPath,		  [Parameter(Position=1,Mandatory=1)]$packageName)

	return (Get-ChildItem($packagesDirectoryPath + $packageName + "*")).FullName |
					Sort-Object $_ | select -Last 1
}

function Get-DirectoryInfoContainFile{
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)]$fileFilter)	

	Get-ChildItem $buildTempDirectory -Recurse -Filter $fileFilter | 
						Select -ExpandProperty DirectoryName -Unique |
						% { [io.directoryinfo]$_ }
}

function Get-TestAssemblyPath {
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)]$testFilePathFilter,
		  [Parameter(Position=1,Mandatory=1)]$testRestPath)	

	$testPath = Get-DirectoryInfoContainFile $testFilePathFilter

	$testDllPath = ""

	if(Test-Path $testPath) {
			Write-Host "建立測試結果的資料夾 $testRestPath"
			New-Item $testRestPath -ItemType Directory | Out-Null

			Write-Host "總共有 $($testPath.Count) 個專案"

			Write-Host ($testPath | Select $_.Name)

			Write-Host "準備執行測試"

			# 組執行的dll

			$testDlls = $testPath | % {$_.FullName + "\" + $_.Name + ".dll" }

			$testDllPath = [string]::Join(" ", $testDlls)

			Write-Host "執行的 assemblies: $testDllPath"
		}

		return $testDllPath
}

function Run-TestWithOpenCover {
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)]$testRunnerExe,
		 [Parameter(Position=1,Mandatory=1)]$testRunnerArg,
		 [Parameter(Position=2,Mandatory=1)]$openCoverExe,
		 [Parameter(Position=3,Mandatory=1)]$openCoverResult,
		 [Parameter(Position=4,Mandatory=1)]$filter,
		 [Parameter(Position=5,Mandatory=1)]$excludeAttribute,
		 [Parameter(Position=6,Mandatory=1)]$excludeFiles)

	Exec { &$openCoverExe "-target:$testRunnerExe" `
						"-targetargs:$testRunnerArg" `
						"-output:$openCoverResult" `
						-register:user `
						"-filter:$filter" `
						-excludebyattribute:$excludeAttribute `
						-excludebyfile:$excludeFiles `
						-skipautoprops `
						-mergebyhash `
						-mergeoutput `
						-hideskipped:All `
						-returntargetcode}
}