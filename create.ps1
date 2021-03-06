## Settings ##
$config = ConvertFrom-Json $configuration;
$onboardDate = Get-Date -Format "yyyy-MM-dd";

#AD Domain
$domain = "t4etest.local";

#Initialize default properties
$p = $person | ConvertFrom-Json;
$success = $False;
$auditMessage = "Enrolled in SSRPM onboarding for person " + $p.DisplayName;
 
$account = [PSCustomObject]@{
                    Action = "new"
                    OnboardingToken = $config.token
                    users = [System.Collections.ArrayList]@()
                };
 
$user = [PSCustomObject]@{
    Domain = $domain
    SAMAccountName = $p.Accounts.ActiveDirectory.SamAccountName;
    OnboardingDate = $onboardDate
    Attributes = [System.Collections.ArrayList]@()
};
 
#Claim ID
[void]$user.Attributes.add([PSCustomObject]@{
                                Name = "ID"
                                Value = $p.externalId
                                Options = 1
                            }
);
 
#Birth date
[void]$user.Attributes.add([PSCustomObject]@{
                                Name = "DOB"
                                Value = (Get-Date -Date $p.details.birthdate).ToUniversalTime().toString("dd/MM/yyyy")
                                Options = 34
                            }
)
 
[void]$account.users.Add($user);
try {
 
    if(-Not($dryRun -eq $True)) {
        $response = (Invoke-WebRequest -Uri "$($config.ssrpmServer)/onboarding/import" -Method POST -ContentType "application/json" -Body ($account | ConvertTo-Json -Depth 10) -UseBasicParsing | ConvertFrom-Json).Success
    }
    else
    {
        $response = $true;
    }
     
    if($response -eq $true)
    {
        $success = $True;
        $auditMessage = "Enrolled in SSRPM onboarding for person " + $p.DisplayName;
    }
     
}
catch
{
        $auditMessage = $_.toString() + " : General error"
}
 
 
#build up result
$result = [PSCustomObject]@{
    Success= $success;
    AccountReference= $account_guid;
    AuditDetails=$auditMessage;
    Account = $account;
};
 
#send result back
Write-Output $result | ConvertTo-Json -Depth 10
