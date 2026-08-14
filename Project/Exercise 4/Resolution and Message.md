# Floor 6 Message

Most likely cause: a Friday app deployment colliding with the Floor 6 Win11/Intune login path, so first sign-in is getting slowed or timing out while the app and policy work completes.

Immediate fix if it is app-deployment driven:
```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All","Device.ReadWrite.All","DeviceManagementManagedDevices.ReadWrite.All"
$deploymentGroupId = "<floor6-app-assignment-group-id>"
$affectedGroupId = "<floor6-affected-devices-group-id>"

$affected = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/groups/$affectedGroupId/members?`$select=id,displayName"
$affected.value | Export-Csv ".\floor6-affected-devices.csv" -NoTypeInformation

foreach ($device in $affected.value) {
    Invoke-MgGraphRequest -Method DELETE -Uri "https://graph.microsoft.com/v1.0/groups/$deploymentGroupId/members/$($device.id)/`$ref"
}
```

Plain-language note to Floor 6:
We’re looking into the login delays and working to stabilize access now. The issue appears tied to recent system changes, and we’re isolating the affected devices and reversing the change where needed. We’ll keep you updated as soon as we confirm the next step.
