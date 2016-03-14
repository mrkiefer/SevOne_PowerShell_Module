Import-Module ..\SevOne.psd1

$Cred = New-Object pscredential -ArgumentList 'admin', (ConvertTo-SecureString -AsPlainText -Force SevOne)

Connect-SevOne 192.168.50.9 $Cred

Describe 'Testing the SevOne Module' {
  Context 'Looking at Devices' {
    It 'Returns at least 1 device' {
      (Get-SevOneDevice | Measure-Object).count -ge 1 | Should be $true
    }
  }
  Context 'Looking at Objects' {
    It 'Returns at least one object' {
      (Get-SevOneDevice | Get-SevOneObject |Measure-Object).count -ge 1 | Should be $true 
    }
  }
  Context 'Alerts' {
    It 'Gathers alerts' {
      (Get-SevOneAlert | Measure-Object).Count -ge 1 | should be $true
    }
  }
}
