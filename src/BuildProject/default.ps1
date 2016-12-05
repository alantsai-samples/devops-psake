Properties{
	$testMsg = "Executed Test !"
	$compileMsg = "Executed Compile !"
	$cleanMsg = "Executed Clean !"

	$solutionDirectory = (Get-Item $solutionFile).DirectoryName
	$buildDirectory = "$solutionDirectory\.build"
}

task default -depends Test

task Init -depends Clean -description "初始化建制所需要的設定"{
	
	Write-Host "建立建制結果的資料夾 $buildDirectory"
	New-Item $buildDirectory -ItemType Directory | Out-Null
}

task Test -depends Compile, Clean -description "執行Test" { 
	Write-Host $testMsg
}

task Compile -depends Clean, Init -description "編譯程式碼" { 
	Write-Host $compileMsg
}

task Clean -description "刪除上次編譯遺留下來的內容"{ 
	Write-Host $cleanMsg
}
