# GCP Setup Guide - Free Tier Focus

## 🎯 Quick Start: GCP Account Setup

### Step 1: Create GCP Account
1. Go to https://cloud.google.com/
2. Click "Get started for free"
3. Sign in with Google account
4. **You get $300 free credit for 90 days!**

### Step 2: Create New Project
1. Go to Cloud Console: https://console.cloud.google.com/
2. Click project dropdown → "New Project"
3. Name: `automation-alchemy`
4. Click "Create"

### Step 3: Enable Billing (Required, but we'll use free tier)
1. Go to "Billing" in left menu
2. Link billing account (can use free trial)
3. **Important**: We'll set up alerts to prevent charges

### Step 4: Set Up Billing Alerts (CRITICAL!)
1. Go to "Billing" → "Budgets & alerts"
2. Click "Create Budget"
3. Set budget amount: **$30/month**
4. Add alert thresholds:
   - 50% of budget ($15)
   - 90% of budget ($27)
   - 100% of budget ($30)
5. Add email notifications
6. **Enable "Disable billing" at 100%** (optional, but safe)

### Step 5: Enable Required APIs
We'll enable these via Terraform, but you can also do it manually:
- Compute Engine API
- Cloud Resource Manager API
- IAM API

---

## 💰 Cost Breakdown

### Free Tier (Always Free)
- **1x e2-micro VM**: FREE forever (1 vCPU, 1GB RAM, 30GB disk)
- **30GB standard persistent disk**: FREE
- **1GB network egress/month**: FREE
- **Cloud Load Balancing**: FREE (forwarding rules)

### Paid Resources (After Free Tier)
- **Additional e2-micro VMs**: ~$7/month each
- **Additional disk storage**: ~$0.17/GB/month
- **Network egress**: ~$0.12/GB (after 1GB free)

### Our Plan
- **Start**: 1 VM (FREE forever)
- **Scale up**: 4 VMs (1 free + 3 paid = ~$21/month)
- **With $300 credit**: FREE for ~14 months!

---

## 🛡️ Cost Protection Checklist

- [ ] Billing account linked
- [ ] Budget set at $30/month
- [ ] Alerts configured (50%, 90%, 100%)
- [ ] Email notifications enabled
- [ ] Budget limit action: Alert only (or disable billing)

---

## 🚀 Next Steps

1. **Set up GCP account** (follow steps above)
2. **Install gcloud CLI** (for local development)
3. **Set up Terraform** (we'll do this next)
4. **Create infrastructure** (Phase 1)

---

## 📝 Install gcloud CLI (Optional but Helpful)

### Windows:
```powershell
# Download and install from:
# https://cloud.google.com/sdk/docs/install

# Or use Chocolatey:
choco install gcloudsdk
```

### Verify Installation:
```bash
gcloud --version
gcloud auth login
gcloud config set project automation-alchemy
```

---

## ✅ Ready to Proceed?

Once you've:
1. ✅ Created GCP account
2. ✅ Created project "automation-alchemy"
3. ✅ Set up billing alerts
4. ✅ Enabled billing (required for VMs)

**Let me know and we'll start Phase 1 with Terraform!** 🚀

