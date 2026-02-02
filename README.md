# OpenClawKit Project

OpenClawKit is a one-click installer and website for setting up OpenClaw AI on macOS.

## Project Structure

```
openclaw-kit/
├── README.md                   # This file
├── PROJECT_PLAN.md             # Overall project plan
├── BRANDING_GUIDELINES.md      # Branding and design guidelines
├── serve.sh                    # Script to run local web server
├── website/                    # Website files
│   ├── index.html              # Main website HTML
│   ├── css/                    # CSS styles
│   │   └── styles.css          # Main stylesheet
│   ├── js/                     # JavaScript files
│   │   └── main.js             # Main JavaScript file
│   └── images/                 # Website images
└── installer/                  # macOS installer (in development)
```

## Testing the Website Locally

To test the website locally, run:

```bash
./serve.sh
```

Then visit [http://localhost:8000](http://localhost:8000) in your web browser.

## Current Status

- Website: Complete and ready for testing
- Installer: In development

## About OpenClaw

OpenClaw AI is a personal AI assistant you run on your own devices. It answers you on the channels you already use (WhatsApp, Telegram, Slack, Discord, Google Chat, Signal, iMessage, Microsoft Teams), plus extension channels. The Gateway is just the control plane — the product is the assistant.

## OpenClawKit Value Proposition

Our installer provides significant value by:

1. **GUI Interface** - Replacing terminal commands with clickable buttons
2. **One-click Installation** - Handling all dependencies automatically:
   - Installing Node.js 22+
   - Setting up the OpenClaw package
   - Running the onboarding wizard graphically
   - Service configuration
3. **Visual Channel Setup** - Simplifying the channel connection process
4. **API Key Management** - Secure storage and setup for API keys
5. **Friendly Error Handling** - No cryptic terminal errors

## Next Steps

1. Complete macOS installer bundle
2. Add real payment processing
3. Deploy website to Vercel
4. Create test distribution