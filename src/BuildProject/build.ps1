# 目前script的位置
$sciptCurrentDir = Split-Path $MyInvocation.MyCommand.Path -Parent

# build script 位置
$buildFile = Join-Path $sciptCurrentDir .\default.ps1

# solution檔案位置
$solutionFile = (Get-ChildItem(Join-Path $sciptCurrentDir "..\*.sln")).FullName |
					Sort-Object $_ | select -Last 1

# 找到和 build一起的 psake module
$psakeModulePath = (Get-ChildItem( Join-Path $sciptCurrentDir ".\Tool\psake.psm1")).FullName |
						Sort-Object $_ | select -Last 1

$nugetExePath = Join-Path $sciptCurrentDir .\Tool\nuget.exe				

function LoadPsakePackage {

	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)]$psakeModulePath)

	# 如果psake module有存在，先把他反註解
	if (Get-Module -ListAvailable -Name psake) {
		Remove-Module psake
	} 

	if(Test-Path $psakeModulePath){
		Import-Module $psakeModulePath
	}else{
		Write-Host "找不到psake module，請確認好nuget package有restore完成"
		return
	}
}

LoadPsakePackage $psakeModulePath

# 執行psake
Invoke-psake -buildFile $buildFile -taskList Test `
			 -framework "4.6" `
			 -parameters @{
				"solutionFile" = $solutionFile
				"nugetExePath" = $nugetExePath
			 }`
			 -properties @{
				"testMsg"="測試訊息"
				"isRunCodeAnalysis" = $false
				"isRunStyleCop" = $false
			 }

Write-Host "建制的Exit Code：$LastExitCode"

# 把錯誤碼往上傳
exit $LastExitCode