param (
    [string]$path = "EncTitleKeys.tsv",
    [string]$Generate = "TIK",
    [string]$Usertype = "eShop/Application",
    [string]$UserRegion = "EUR"
 )

$encoding = [System.Text.Encoding]::ASCII;
$uencoding = [System.Text.Encoding]::UNICODE;
 
Function Remove-InvalidFileNameChars {
  param(
    [Parameter(Mandatory=$true,
      Position=0,
      ValueFromPipeline=$true,
      ValueFromPipelineByPropertyName=$true)]
    [String]$Name
  )

  $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
  $re = "[{0}]" -f [RegEx]::Escape($invalidChars)
  return ($Name -replace $re)
}
 
Get-Content -Path $path | Foreach-Object {
	Remove-Variable titelid;Remove-Variable DecryptedTitleKey;Remove-Variable EncryptedTitleKey;Remove-Variable Type;Remove-Variable Name;Remove-Variable Region;Remove-Variable Serial;
    $titelid,$DecryptedTitleKey,$EncryptedTitleKey,$Type,$Name,$Region,$Serial = [regex]::split($_, '\t') |  foreach {$_.Trim()};

	if(($Region -eq $UserRegion) -or ($Region -eq 'ALL'))
	{
		if ($titelid.Length -gt 15 -and ($EncryptedTitleKey.Length -gt 31) -and ($Type -eq $Usertype))
		{
			# remove unicode
			$Name = Remove-InvalidFileNameChars(-Join $encoding.GetChars([System.Text.Encoding]::Convert($uencoding, $encoding, $uencoding.GetBytes($Name)))).Replace("?","");
            
			write-host $titelid $EncryptedTitleKey $Name $Type
			$FolderLocation = $(Get-Location).PATH;
			if ($Generate -eq 'CIA')
			{
			   .\FunKeyCIA.py -title $titelid -key $EncryptedTitleKey
				$FolderLocation = $FolderLocation + '\cia';
			}
			else
			{
				.\TikGenerator.py -title $titelid -key $EncryptedTitleKey | write-output
				$FolderLocation = $FolderLocation + '\tik';
			}
			$CIALocation = $FolderLocation + '\' + $titelid;
			$Dest = $FolderLocation + '\' + $Name;
			Rename-item -Path $CIALocation -NewName $Dest -Force;
		}
        elseif ($titelid.Length -gt 15 -and ($EncryptedTitleKey.Length -lt 31) -and ($Type -eq $Usertype))
		{
            write-output "Missing encryptedkey $Name $Type"            
        }
        else
        {
            write-output "Ignoring $Name $Type"
        }
	}
}
Write-Host "Done"
#Write-Host "Press any key to continue..."
#$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
