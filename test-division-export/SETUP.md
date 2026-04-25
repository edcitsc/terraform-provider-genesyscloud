# Quick Setup Guide

## Prerequisites

Before running the tests, you need Genesys Cloud OAuth credentials configured.

### Option 1: Environment Variables (Recommended)

```powershell
# Set these environment variables
$env:GENESYSCLOUD_OAUTHCLIENT_ID = "your-client-id"
$env:GENESYSCLOUD_OAUTHCLIENT_SECRET = "your-client-secret"
$env:GENESYSCLOUD_REGION = "us-east-1"  # or your region
```

### Option 2: Direct Configuration

Edit `main.tf` and uncomment/fill in the provider block:

```hcl
provider "genesyscloud" {
  oauthclient_id     = "your-client-id"
  oauthclient_secret = "your-client-secret"
  aws_region         = "us-east-1"
}
```

## Running the Test

### Simple Test (All Divisions)
```powershell
.\Test-DivisionExport.ps1
```

### Test Specific Division
```powershell
.\Test-DivisionExport.ps1 -DivisionGuid "12345678-1234-1234-1234-123456789012"
```

### Manual Test (If Script Fails)

```powershell
# Initialize
terraform init

# Run Test 1
terraform apply "-target=genesyscloud_tf_export.test_division_no_deps" -auto-approve

# Check results
.\Analyze-Export.ps1 -ExportDirectory ".\export_division_no_deps"
```

## Common Issues

### "No valid credential sources found"
- You haven't set environment variables or configured the provider
- Set the environment variables as shown in Option 1 above

### "Invalid target" error  
- This was a quoting issue, now fixed in the script
- If you still see this, run terraform commands manually as shown above

### Test hangs/takes too long
- This suggests many resources are being exported (unexpected)
- Let the test complete, then run: `.\Analyze-Export.ps1 -ExportDirectory ".\export_division_no_deps"`
- This confirms what's being exported

## Expected Results

For division-only exports:
- ✅ Completes in < 5 seconds (for small org)
- ✅ Only exports divisions
- ✅ Test 1 and Test 2 produce similar results
