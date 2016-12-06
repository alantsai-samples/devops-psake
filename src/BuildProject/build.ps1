# 如果psake module有存在，先把他反註解
if (Get-Module -ListAvailable -Name psake) {
	Remove-Module psake
} 

# 找到psake module並且註冊
$psakeModulePath = (Get-ChildItem("..\packages\psake*\tools\psake.psm1")).FullName |
					Sort-Object $_ | select -Last 1

if(Test-Path $psakeModulePath){
	Import-Module $psakeModulePath
}else{
	Write-Host "找不到psake module，請確認好nuget package有restore完成"
	return
}

# 執行psake
Invoke-psake -buildFile .\default.ps1 -taskList Test `
			 -framework "4.5.2" `
			 -parameters @{
				"solutionFile" = (Get-ChildItem("..\*.sln")).FullName |
					Sort-Object $_ | select -Last 1
			 }`
			 -properties @{
				"testMsg"="測試訊息"
			 }
