function Get-PackagePath {
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)]$packagesDirectoryPath,		  [Parameter(Position=1,Mandatory=1)]$packageName)

	return (Get-ChildItem($packagesDirectoryPath + $packageName + "*")).FullName |
					Sort-Object $_ | select -Last 1
}