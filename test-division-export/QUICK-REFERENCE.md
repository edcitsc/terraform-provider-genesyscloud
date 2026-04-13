# Quick Reference: Division Export Behavior

## Key Facts

### 1. Division Dependencies
```go
// From: genesyscloud/auth_division/resource_genesyscloud_auth_division_schema.go
RefAttrs: map[string]*resourceExporter.RefAttrSettings{}, // No references
```

**What this means**: `genesyscloud_auth_division` has **ZERO dependencies**.

### 2. What Depends ON Divisions

Many resources reference divisions via their `division_id` field:
- `genesyscloud_user`
- `genesyscloud_group`
- `genesyscloud_routing_queue`
- `genesyscloud_flow`
- `genesyscloud_architect_emergencygroup`
- And many more...

### 3. Dependency Resolution Direction

`enable_dependency_resolution = true` works **DOWNWARD**:
```
Division (export this)
    ↓ No dependencies
    → Result: Only division exported
```

It does **NOT** work upward:
```
Division (export this)
    ↑ (IGNORED)
Users, Groups, Queues, etc. (these reference the division)
```

## Expected Export Times

| Scenario | Expected Time | Resources Exported |
|----------|---------------|-------------------|
| Single division, no deps | < 5 seconds | 1 division |
| All divisions, no deps | < 30 seconds | ~50-100 divisions |
| Single division, WITH deps | < 5 seconds | 1 division (same as without) |

## Common Misconfigurations

### ❌ Wrong: This exports EVERYTHING
```hcl
resource "genesyscloud_tf_export" "bad" {
  directory = "./export"
  enable_dependency_resolution = true
  # Missing: include_filter_resources
}
```

### ❌ Wrong: Typo in resource type
```hcl
resource "genesyscloud_tf_export" "bad" {
  directory = "./export"
  include_filter_resources = ["genesyscloud_divisions"]  # Wrong!
  enable_dependency_resolution = true
}
```

### ✅ Correct: Export only divisions
```hcl
resource "genesyscloud_tf_export" "good" {
  directory = "./export"
  include_filter_resources = ["genesyscloud_auth_division"]
  enable_dependency_resolution = false  # Not needed for divisions
}
```

### ✅ Correct: Export specific division
```hcl
resource "genesyscloud_tf_export" "good" {
  directory = "./export"
  include_filter_resources_by_id = ["genesyscloud_auth_division::12345678-1234-1234-1234-123456789012"]
  enable_dependency_resolution = false  # Not needed for divisions
}
```

## Debugging Steps

### 1. Check what was exported
```powershell
# Quick count of resource types
$json = Get-Content .\export\genesyscloud.tf.json | ConvertFrom-Json
$json.resource.PSObject.Properties.Name
```

### 2. Enable debug logging
```powershell
$env:TF_LOG = "DEBUG"
$env:TF_LOG_PATH = "terraform-debug.log"
terraform apply

# Search for what's being processed
Get-Content terraform-debug.log | Select-String "Processing resource type|LoadSanitizedResourceMap"
```

### 3. Verify filter syntax
```powershell
# List available resource types
terraform console
> data.genesyscloud_tf_export.test.resource_types
```

## Source Code References

- **Division Exporter**: `genesyscloud/auth_division/resource_genesyscloud_auth_division_schema.go:70`
  - RefAttrs is empty

- **Export Logic**: `genesyscloud/tfexporter/genesyscloud_resource_exporter.go`
  - Line ~292: `computeDependsOn()` determines if dependency resolution is active
  - Line ~1426: `exportAndResolveDependencyAttributes()` handles recursive dependency export
  - Line ~2589: `resolveReference()` populates dependencies from RefAttrs

- **BCP Exporter**: `genesyscloud/bcp_tf_exporter/resource_genesyscloud_bcp_tf_exporter.go`
  - Line ~310: `extractSpecificDependencies()` uses RefAttrs to find dependencies
  - This is similar but for JSON export format (used for BCP purposes)

## Contact

If you've verified:
- ✅ Your filter syntax is correct
- ✅ Only `genesyscloud_auth_division` is specified
- ✅ Still seeing many resources exported
- ✅ Export takes a long time

Then there may be a bug in the filter logic. Provide:
1. Your exact tf_export configuration
2. Output from `Analyze-Export.ps1`
3. Count of resources exported
4. Time taken for export
