# Verify Work Items are Properly Linked to PR (PowerShell) Script
_This PowerShell script, can be added executed by a Pull Request Trigger in Azure DevOps to validate that Work Items have been properly updated and linked to a PR._

## NOTES
Check params to make sure they are accurate and provided properly during script execution.

### Azure DevOps Personal Access Token (PAT) Parameter ($pat) 
Ensure a valid Personal Access Token (PAT) is available as an environment variable before executing this script whether if running locally or in a DevOps pipeline. To set an environment variable in PowerShell when running locally execute the following: 
  *'$pat:{paste PAT}' and then press ENTER (https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables).*
  
### To generate an Azure DevOps PAT:
1. Navigate to Azure DevOps -> User Settings -> Personal Access Tokens
2. Click the "+ New Token" (button)
3. Add a Name
4. Add an Expiration Date
5. Add a Custom Scope with the following Grants: Packaging (Read) and Work Items (Read).

This Personal Access Token needs to have Packaging (Read) and Work Items (Read) Grants in order to access Work Items associated with Pull Requests.

Modify as needed!
