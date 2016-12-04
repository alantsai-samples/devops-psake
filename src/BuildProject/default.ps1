Properties{
	$testMsg = "Executed Test !"
	$compileMsg = "Executed Compile !"
	$cleanMsg = "Executed Clean !"
}

task default -depends Test

task Test -depends Compile, Clean -description "執行Test" { 
	Write-Host $testMsg
}

task Compile -depends Clean -description "編譯程式碼" { 
	Write-Host $compileMsg
}

task Clean -description "刪除上次編譯遺留下來的內容"{ 
	Write-Host $cleanMsg
}
