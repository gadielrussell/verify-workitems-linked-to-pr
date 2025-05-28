param (
    [string]$org = $null, #Azure DevOps Organization.
    [string]$project $null, #Azure DevOps Project.
    [string]$repo = $null, #Azure DevOps Repository. Provided by pipeline or if running locally, provide when executing or set as an Environment Variable.
    [string]$prId = $null, #Pull Request ID. Provided by pipeline or if running locally, provide when executing or set as an Environment Variable.
    [string]$pat = $null #Personal Access Token. Provided by pipeline or if running locally, provide when executing or set as an Environment Variable.
)
 
# HOW TO SET ENVIRONMENT VARIABLES IN POWERSHELL
# Example -> '$pat:{paste PAT}' and then press ENTER
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables

$baseUri = "https://dev.azure.com/$org/$project/_apis/"

if ([string]::IsNullOrEmpty($pat)) {

    #Write-Host "PAT argument was null. Checking for (env:pat) environment variable."
    $pat = $env:pat

    if ([string]::IsNullOrEmpty($pat)) {
        Write-Host "Unable to validate linked Work Items because no Personal Access Token (PAT) was provided"
        exit 1
    }

    Write-Host "Personal Access Token (PAT) environment variable (env:pat) found!"
}

if ([string]::IsNullOrEmpty($repo)) {

    #Write-Host "Repository argument was null. Checking for (env:repo) environment variable."
    $repo = $env:repo

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Host "Unable to validate linked Work Items because no Repository was provided"
        exit 1
    }

    Write-Host "Repository environment variable (env:repo) found!"
}

if ([string]::IsNullOrEmpty($prId)) {

    #Write-Host "PR ID argument was null. Checking for (env:prId) environment variable."
    $prId = $env:prId

    if ([string]::IsNullOrEmpty($prId)) {
        Write-Host "Unable to validate linked Work Items because no Pull Request Id was provided"
        exit 1
    }

    Write-Host "PR ID environment variable (env:prId) found!"
}

# Create Auth Header
$headers = @{
    "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
    "Content-Type"  = "application/json"
}

# Request Work Items linked to Pull Request
$prUri = $baseUri + "git/repositories/$repo/pullrequests/$prId/workitems?api-version=7.1"
#Write-Host $prUri
$prResponse = Invoke-RestMethod -Uri $prUri -Headers $headers -Method Get
$workItems = $prResponse.value

if ($null -eq $workItems -or $workItems.Count -eq 0) {
    Write-Host "Validation Failed: No Work Items are associated with Pull Request $prId"
    exit 1
}

$missingFields = @()
$validatedWorkItemMsgs = @()

foreach ($workItem in $workItems) {

    $workItemId = $workItem.Id
    $workItemUri = $baseUri + "wit/workitems/" + $workItemId + "?api-version=7.1"
    $workItemNavUri = "https://dev.azure.com/$org/$proj/_workitems/edit/$workItemId"
    #Write-Host $workItemUri
    $workItemData = Invoke-RestMethod -Uri $workItemUri -Headers $headers -Method Get
    #Write-Host ConvertTo-Json($workItemData.fields)

    # Modify these as needed
    $reviewedBy = $workItemData.fields.'Custom.CodeReviewer'
    $reviewDate = $workItemData.fields.'Custom.CodeReviewDate'

    if ($null -eq $reviewedBy -or [string]::IsNullOrEmpty($reviewDate)) {

        $missingFields += "$workItemId - $workItemNavUri" 
        continue
    }

    $reviewDateStr = [string]::Format("{0:MM/dd/yyyy}", [datetime]$reviewDate)
    $reviewStr = "Work Item {0} was reviewed by {1} on {2}." -f $workItemId, $reviewedBy.displayName, $reviewDateStr
    $validatedWorkItemMsgs += $reviewStr
}

if ($missingFields.Count -gt 0) {

    Write-Host "Validation Failed: Code Review fields on the following Work Items are incomplete:"
    $missingFields | ForEach-Object { Write-Host $_ }
    exit 1  # Fail if any work items are missing Code Review information 

}
else {
    $successMsg = "Validation Passed: All Code Review fields on Work Items linked to Pull Request {0} have been properly assigned:" -f $prId
    Write-Host $successMsg
    $validatedWorkItemMsgs | ForEach-Object { Write-Host $_ }
    exit 0 
}
