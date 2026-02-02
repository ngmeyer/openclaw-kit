# OpenClawKit Deployment Guide

## Website Deployment (Vercel)

### Prerequisites
- Vercel account (free at https://vercel.com)
- Git repository with OpenClawKit code
- Domain (optional, can use Vercel subdomain)

### Steps

1. **Connect GitHub Repository**
   - Go to https://vercel.com/import
   - Import the OpenClawKit repository
   - Vercel will auto-detect the static site

2. **Configure Deployment**
   - Framework: None (Static)
   - Root Directory: `./openclaw-kit`
   - Build Command: `echo 'Static site'`
   - Output Directory: `website`

3. **Deploy**
   - Click "Deploy"
   - Vercel will build and deploy automatically
   - Your site will be live at `https://openclawkit.vercel.app`

4. **Configure Custom Domain** (optional)
   - Go to Project Settings → Domains
   - Add your custom domain
   - Follow DNS instructions for your registrar

### Environment Variables
None required for static site deployment.

---

## Payment Integration (Lemonsqueezy)

### Setup Instructions

1. **Create Lemonsqueezy Account**
   - Go to https://lemonsqueezy.com
   - Sign up (free account)
   - Verify email

2. **Create Product**
   - Dashboard → Products → New Product
   - **Product Name:** OpenClawKit
   - **Description:** One-click installer for OpenClaw AI on macOS
   - **Price:** $49.99 USD
   - **Product Type:** One-time purchase
   - **License Terms:** Include 30-day support

3. **Create Variant**
   - Add variant with price $49.99
   - Set to "unlimited" purchases
   - Enable "Send buyer to URL after purchase" (optional - for delivery)

4. **Get Checkout Link**
   - In product page, copy the "Checkout Link"
   - Format: `https://lemonsqueezy.com/checkout/...`

5. **Configure Website**
   - Update `website/index.html`
   - Find: `data-lemon-overlay="checkout_link_id"`
   - Replace with your actual checkout link ID (the part after `/checkout/`)
   - Example: `data-lemon-overlay="abcd1234"`

### Webhook Setup (for download delivery)

1. **Configure Webhook**
   - Lemonsqueezy Dashboard → Webhooks
   - Add new webhook
   - **URL:** `https://yourdomain.com/api/webhook` (implement this)
   - **Events:** `order.created`

2. **Handle Webhook**
   - Receive order confirmation
   - Send download link via email
   - Update customer record

---

## Installer Distribution

### DMG File
The compiled installer is in: `build/OpenClawKit.dmg`

#### Distribute via:
1. **Lemonsqueezy** - Host DMG file in product assets
2. **GitHub Releases** - Upload to GitHub as release asset
3. **Your Server** - Host on CDN or static server

### Code Signing (Recommended)
For production, you should code-sign the macOS app:
```bash
codesign -s - --deep build/OpenClawKit.app
```

---

## Testing Locally

### Test Website
```bash
./serve.sh
# Visit http://localhost:8000
```

### Test Payment Flow
1. Visit local server
2. Enter test email
3. Click "Pay $49.99 and Download"
4. Use Lemonsqueezy test mode (if enabled)
5. Verify success page

---

## After First Deploy

### Monitoring
- Vercel Dashboard → Analytics
- Monitor traffic, performance, errors
- Set up Slack/email notifications

### Updates
1. Make changes locally
2. Commit to git
3. Push to main branch
4. Vercel auto-deploys (usually within 2 min)

### Email Setup
- Configure email service for receipt/download delivery
- Options:
  - SendGrid (Vercel integration)
  - Mailgun
  - Sendmail
  - AWS SES

---

## Troubleshooting

### Website not deploying
- Check build logs in Vercel dashboard
- Verify `vercel.json` is in root
- Ensure `website/` folder exists with `index.html`

### Payment button not working
- Verify Lemonsqueezy script is loaded (check browser console)
- Confirm checkout link ID is correct in HTML
- Test in incognito mode to clear cache

### DMG installer won't launch
- Ensure Swift compilation completed successfully
- Check code signing if distributing externally
- Verify Info.plist has correct bundle ID

---

## Support

For questions about Vercel deployment: https://vercel.com/docs
For Lemonsqueezy integration: https://docs.lemonsqueezy.com
