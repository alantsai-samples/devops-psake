Properties{
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

	$nunitExe = ((Get-ChildItem("$solutionDirectory\packages\NUnit.ConsoleRunner*")).FullName |
                    Sort-Object $_ | select -Last 1) + "\tools\nunit3-console.exe"

	$nunitTestResultDirectory = "$buildTestResultDirectory\Nunit"

	$msTestExe = ((Get-ChildItem("C:\Program Files (x86)\Microsoft Visual Studio*\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe")).FullName |
                    Sort-Object $_ | select -Last 1)

	$msTestResultDirectory= "$buildTestResultDirectory\MSTest"

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
	$xunitTestPath =  Get-ChildItem $buildTempDirectory -Recurse -Filter xunit*.dll | 
						Select -ExpandProperty DirectoryName -Unique | % { [io.directoryinfo]$_ }

	if(Test-Path $xunitTestPath){

		Write-Host "建立Xunit測試結果的資料夾 $xunitTestResultDirectory"
		New-Item $xunitTestResultDirectory -ItemType Directory | Out-Null

		Write-Host "總共有 $($xunitTestPath.Count) 個專案"

		Write-Host ($xunitTestPath | Select $_.Name)

		Write-Host "準備執行Xunit測試"

		# 組執行的dll

		$testDlls = $xunitTestPath | % {$_.FullName + "\" + $_.Name + ".dll" }

		$testDllsJoin = [string]::Join(" ", $testDlls)

		Write-Host "執行的 Dll: $testDllsJoin"

		exec{ &$xunitExe $testDllsJoin -xml $xunitTestResultDirectory\xUnit.xml `
				-html $xunitTestResultDirectory\xUnit.html `
				-nologo -noshadow}
		
		Write-Host "完成執行Xunit測試"
	}

}

task NunitTest -depends Compile -description "執行Nunit測試" `
{
	# 取得nunit project的路徑
	$nunitTestPath =  Get-ChildItem $buildTempDirectory -Recurse -Filter nunit*.dll | 
						Select -ExpandProperty DirectoryName -Unique | % { [io.directoryinfo]$_ }

	if(Test-Path $nunitTestPath){
		Write-Host "建立Nunit測試結果的資料夾 $nunitTestResultDirectory"
		New-Item $nunitTestResultDirectory -ItemType Directory | Out-Null

		Write-Host "總共有 $($nunitTestPath.Count) 個專案"

		Write-Host ($nunitTestPath | Select $_.Name)

		Write-Host "準備執行Nunit測試"
	}

	# 組執行的dll
	$testDlls = $nunitTestPath | % {$_.FullName + "\" + $_.Name + ".dll" }
 
	$testDllsJoin = [string]::Join(" ", $testDlls)

	Write-Host "執行的 Dll: $testDllsJoin"

	exec{ & $nunitExe $testDllsJoin --result=$nunitTestResultDirectory\nUnit.xml}
}

task MSTest -depends Compile -description "執行MSTest測試" `
{
	# 取得nunit project的路徑
	$msTestPath =  Get-ChildItem $buildTempDirectory -Recurse -Filter Microsoft.VisualStudio.QualityTools.UnitTestFramework.dll | 
						Select -ExpandProperty DirectoryName -Unique | 
						% { [io.directoryinfo]$_ } 

	if(Test-Path $msTestPath){
		Write-Host "建立MS Test測試結果的資料夾 $msTestResultDirectory"
		New-Item $msTestResultDirectory -ItemType Directory | Out-Null

		Write-Host "總共有 $($msTestPath.Count) 個專案"

		Write-Host ($msTestPath | Select $_.Name)

		Write-Host "準備執行MS Test測試"
	}

	# 組執行的dll
	$testDlls = $msTestPath  | % {$_.FullName + "\" + $_.Name + ".dll" }
 
	$testDllsJoin = [string]::Join(" ", $testDlls)

	Write-Host "執行的 Dll: $testDllsJoin"

	# MSTest 無法設定結果輸出位置，因此移動進去
	Push-Location $msTestResultDirectory
	exec {& $msTestExe $testDllsJoin /Logger:trx}
	Pop-Location

	$msTestDefaultResultPath = "$msTestResultDirectory\TestResults"
	$msTestResult = "$msTestResultDirectory\MsTest.trx"

	Write-Host "把測試結果移動到 $msTestResult"
	Move-Item -Path $msTestDefaultResultPath\*.trx -Destination $msTestResult
	Remove-Item $msTestDefaultResultPath
}


task Test -depends Compile, Clean, XunitTest, NunitTest, MSTest -description "執行Test" { 
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
