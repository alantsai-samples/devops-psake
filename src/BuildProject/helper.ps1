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