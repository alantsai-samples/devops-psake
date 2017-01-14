. .\helper.ps1

Properties{
	$testMsg = "Executed Test !"
	$cleanMsg = "Executed Clean !"

	$solutionDirectory = (Get-Item $solutionFile).DirectoryName
	$buildDirectory = "$solutionDirectory\.build"
	$buildTempDirectory = "$buildDirectory\temp"
	$buildTestResultDirectory = "$buildDirectory\testResult"
	$buildTestCoverageDirectory = "$buildDirectory\testCoverage"
	$buildArtifactDirectory = "$buildDirectory\artifact"

	$packageDirectoryPath = "$solutionDirectory\packages\"

	$xunitTestResultDirectory = "$buildTestResultDirectory\Xunit"
	$xunitExe = (Get-PackagePath $packageDirectoryPath "xunit.runner.console") + 
					"\tools\xunit.console.exe"

	$nunitExe = (Get-PackagePath $packageDirectoryPath "NUnit.ConsoleRunner") + 
                   "\tools\nunit3-console.exe"

	$nunitTestResultDirectory = "$buildTestResultDirectory\Nunit"

	$msTestExe = ((Get-ChildItem("C:\Program Files (x86)\Microsoft Visual Studio*\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe")).FullName |
                    Sort-Object $_ | select -Last 1)

	$msTestResultDirectory= "$buildTestResultDirectory\MSTest"

	$openCoverExe = (Get-PackagePath $packageDirectoryPath "OpenCover") +
						"\tools\OpenCover.Console.exe"

	$openCoverResult = "$buildTestCoverageDirectory\openCover.xml"
	$openCoverFilter = "+[*]* -[xunit.*]* -[*.NunitTest]* -[*.Tests]* -[*.XunitTest]*"
	$openCoverExcludeAttribute = "System.Diagnostics.CodeAnalysis.ExcludeFromCodeCoverageAttribute"
	$openCoverExcludeFie = "*\*Designer.cs;*\*.g.cs;*\*.g.i.cs"


	$reportGeneratorExe = (Get-PackagePath $packageDirectoryPath "ReportGenerator") +
						"\tools\ReportGenerator.exe"

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
	$testAssembly = Get-TestAssemblyPath "xunit*.dll" $xunitTestResultDirectory

	if(Test-Path $testAssembly){

		$xmlResult = "$xunitTestResultDirectory\xUnit.xml"
		$htmlResult = "$xunitTestResultDirectory\xUnit.html"

		$targetArg = "$testAssembly -xml $xmlResult -html $htmlResult -nologo -noshadow"

		Run-TestWithOpenCover -testRunnerExe $xunitExe `
							-testRunnerArg $targetArg `
							-openCoverExe $openCoverExe `
							-openCoverResult $openCoverResult `
							-filter $openCoverFilter `
							-excludeAttribute $openCoverExcludeAttribute `
							-excludeFiles $openCoverExcludeFie `
	}
}

task NunitTest -depends Compile -description "執行Nunit測試" `
{
	# 取得nunit project的路徑
	$testAssembly = Get-TestAssemblyPath "nunit*.dll" $nunitTestResultDirectory

	if(Test-Path $testAssembly){
		$targetArg = "$testAssembly --result=$nunitTestResultDirectory\nUnit.xml"

		Run-TestWithOpenCover -testRunnerExe $nunitExe `
							-testRunnerArg $targetArg `
							-openCoverExe $openCoverExe `
							-openCoverResult $openCoverResult `
							-filter $openCoverFilter `
							-excludeAttribute $openCoverExcludeAttribute `
							-excludeFiles $openCoverExcludeFie `
	}
}

task MSTest -depends Compile -description "執行MSTest測試" `
{
	# 取得nunit project的路徑
	$testAssembly = Get-TestAssemblyPath "Microsoft.VisualStudio.QualityTools.UnitTestFramework.dll" `
						$msTestResultDirectory

	if(Test-Path $testAssembly){
		# MSTest 無法設定結果輸出位置，因此移動進去
		Push-Location $msTestResultDirectory
		$targetArg = "$testAssembly /Logger:trx"

		Run-TestWithOpenCover -testRunnerExe $msTestExe `
							-testRunnerArg $targetArg `
							-openCoverExe $openCoverExe `
							-openCoverResult $openCoverResult `
							-filter $openCoverFilter `
							-excludeAttribute $openCoverExcludeAttribute `
							-excludeFiles $openCoverExcludeFie `

		Pop-Location

		$msTestDefaultResultPath = "$msTestResultDirectory\TestResults"
		$msTestResult = "$msTestResultDirectory\MsTest.trx"

		Write-Host "把測試結果移動到 $msTestResult"
		Move-Item -Path $msTestDefaultResultPath\*.trx -Destination $msTestResult
		Remove-Item $msTestDefaultResultPath
	}
}


task Test -depends Compile, Clean, XunitTest, NunitTest, MSTest -description "執行Test" { 
	
	if(Test-Path $openCoverResult){
		Write-Host "`r`n產生測試涵蓋率報告 html 格式"
		exec{ &$reportGeneratorExe $openCoverResult $buildTestCoverageDirectory}
	} else {
		Write-Host "`r`n沒有產生測試涵蓋率報告"
	}

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
	$buildParam = $buildParam + ";RunCodeAnalysis=true;CodeAnalysisRuleSet=MinimumRecommendedRules.ruleset;CodeAnalysisTreatWarningsAsErrors=true"

	exec {msbuild $solutionFile "/p:$buildParam"}
}

task Clean -description "刪除上次編譯遺留下來的內容"{ 

	if(Test-Path $buildDirectory){
		Write-Host "清除上次編譯的結果 $buildDirectory"
		Remove-Item $buildDirectory -Recurse -Force
	}

	Write-Host $cleanMsg
}
