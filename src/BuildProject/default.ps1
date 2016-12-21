﻿Properties{
	$testMsg = "Executed Test !"
	$cleanMsg = "Executed Clean !"

	$solutionDirectory = (Get-Item $solutionFile).DirectoryName
	$buildDirectory = "$solutionDirectory\.build"
	$buildTempDirectory = "$buildDirectory\temp"
	$buildTestResultDirectory = "$buildDirectory\testResult"
	$buildTestCoverageDirectory = "$buildDirectory\testCoverage"
	$buildArtifactDirectory = "$buildDirectory\artifact"

	$xunitTestResultDirectory = "$buildTestResultDirectory\Xunit"
	$xunitExe = ((Get-ChildItem("$solutionDirectory\packages\xunit.runner.console*")).FullName |
					Sort-Object $_ | select -Last 1) + "\tools\xunit.console.exe"

	$buildConfiguration = "Release"
	$buildTarget = "Any CPU"
}

FormatTaskName ("`r`n`r`n" + ("-"*25) + "[{0}]" + ("-"*25))

function InitDirectory{
	Write-Host "建立建制結果的資料夾 $buildDirectory"
	New-Item $buildDirectory -ItemType Directory | Out-Null

	Write-Host "建立建制結果裡面的Temp資料夾 $buildTempDirectory"
	New-Item $buildTempDirectory -ItemType Directory | Out-Null

	Write-Host "建立建制結果裡面的TestResult資料夾 $buildTestResultDirectory"
	New-Item $buildTestResultDirectory -ItemType Directory | Out-Null

	Write-Host "建立建制結果裡面的TestCoverage資料夾 $buildTestCoverageDirectory"
	New-Item $buildTestCoverageDirectory -ItemType Directory | Out-Null

	Write-Host "建立建制結果裡面的Artifact資料夾 $buildArtifactDirectory"
	New-Item $buildArtifactDirectory -ItemType Directory | Out-Null
}

task default -depends Test

task Init -depends Clean -description "初始化建制所需要的設定"{
	InitDirectory

	# 檢查test framework runner
	Assert (Test-Path $xunitExe) "xunit console runner 找不到"
}

task XunitTest -depends Compile -description "執行Xunit測試" `
{
	# 取得Xunit project的路徑
	if($xunitTestPath -eq ""){
		$xunitTestPath =  Get-ChildItem $buildTempDirectory -Recurse -Filter xunit*.dll | 
							Select -ExpandProperty DirectoryName -Unique
	}

	if(Test-Path $xunitTestPath){

		Write-Host "準備執行Xunit測試"

		Write-Host $xunitTestPath

		Write-Host "完成執行Xunit測試"
	}

}

task Test -depends Compile, Clean, XunitTest -description "執行Test" { 
	Write-Host $testMsg
}

task Compile -depends Clean, Init -description "編譯程式碼" `
			 -requiredVariables solutionFile, buildConfiguration, buildTarget, buildTempDirectory `
{ 
	Write-Host "開始建制檔案：$solutionFile"

	$buildParam = "Configuration=$buildConfiguration" +
					";Platform=$buildTarget" + 
					";OutDir=$buildTempDirectory"
	
	$buildParam = $buildParam + ";GenerateProjectSpecificOutputFolder=true"

	exec {msbuild $solutionFile "/p:$buildParam"}
}

task Clean -description "刪除上次編譯遺留下來的內容"{ 

	if(Test-Path $buildDirectory){
		Write-Host "清除上次編譯的結果 $buildDirectory"
		Remove-Item $buildDirectory -Recurse -Force
	}

	Write-Host $cleanMsg
}
