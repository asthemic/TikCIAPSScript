param (
    [string]$path = "EncTitleKeys.tsv",
    [string]$Generate = "TIK",
    [string]$Usertype = "eShop/Application|DLC|DSiWare",
    [string]$UserRegion = "EUR",
    [bool]$renamefile = $true,
    [bool]$justmove = $false
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
	{Remove-Variable titelid;Remove-Variable DecryptedTitleKey;Remove-Variable EncryptedTitleKey;Remove-Variable Type;Remove-Variable Name;Remove-Variable Region;Remove-Variable Serial;} | out-null
    $titelid,$DecryptedTitleKey,$EncryptedTitleKey,$Type,$Name,$Region,$Serial = [regex]::split($_, '\t') |  foreach {$_.Trim()};

	if(($Region -eq $UserRegion) -or ($Region -eq 'ALL'))
	{
        $excludes = '(Video)$|(Demo)$|(Demo Version)$|(3D Trailer)$|(Trailer)$';
		if ($titelid.Length -gt 15 -and ($EncryptedTitleKey.Length -gt 31) -and ($Type -match $Usertype) -and !($Name -imatch $excludes))
		{
			# remove unicode
			$Name = Remove-InvalidFileNameChars(-Join $encoding.GetChars([System.Text.Encoding]::Convert($uencoding, $encoding, $uencoding.GetBytes($Name)))).Replace("?","");
            
			write-host $titelid $EncryptedTitleKey $Name $Type
			$FolderLocation = $(Get-Location).PATH;
			if ($Generate -eq 'CIA')
			{
			   .\FunKeyCIA.py -title $titelid -key $EncryptedTitleKey
				$FolderLocation = $FolderLocation + '\' + $Generate.ToLower();
			}
			else
			{
				.\TikGenerator.py -title $titelid -key $EncryptedTitleKey | write-output
				$FolderLocation = $FolderLocation + '\' + $Generate.ToLower();
			}
			$CIALocation = $FolderLocation + '\' + $titelid;
			$Dest = $FolderLocation + '\' + $Name;
            
            $FolderType = Remove-InvalidFileNameChars(-Join $encoding.GetChars([System.Text.Encoding]::Convert($uencoding, $encoding, $uencoding.GetBytes($Type)))).Replace("?","").Replace("/","");
            $to = $FolderLocation + '\' + $FolderType;
            if(!(Test-Path $to))
            {
                New-Item -Path $to -ItemType Directory -Force | Out-Null
            }
            $Dest = $to + '\' + $Name;
            If ($renamefile)
            {         
    			$CIAMoveFileLocation = $CIALocation + '\' + $titelid + '.' + $Generate.ToLower();
    			$Dest = $Dest + '.' + $Generate.ToLower();
                
                $incnum = 1;
                $origDest = $Dest;
                while(Test-Path -Path $Dest)
                {
                    $Dest = Join-Path (Get-Item $origDest).DirectoryName  ((Get-Item $origDest).Basename + " ($incnum)" + (Get-Item $origDest).Extension);
               
                   $incnum += 1;
                }
    			Move-item -Path $CIAMoveFileLocation -Destination $Dest -Force -Verbose;
                Del -Path $CIALocation;
            }
            Elseif($justmove)
            {            
			    Rename-item -Path $CIALocation -NewName $Dest -Force;
            }
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