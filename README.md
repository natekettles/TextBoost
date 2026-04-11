# TextBoost

A lightweight macOS menu bar app for AI-powered text rewrites. Select text in any app, hit a hotkey, and get it rewritten instantly using your own API key (Anthropic or OpenAI).

## Features

- **Global hotkey** - trigger rewrites from any app
- **Custom prompts** - create and manage rewrite styles (fix grammar, shorten, translate, etc.)
- **BYO API key** - works with Anthropic (Claude) and OpenAI models
- **Menu bar app** - stays out of your way, no dock icon

## Getting Started

### Requirements

- macOS 14.0+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (install via `brew install xcodegen`)
- An API key from [Anthropic](https://console.anthropic.com/) or [OpenAI](https://platform.openai.com/)

### Build & Run

```bash
# Generate the Xcode project
xcodegen generate

# Open in Xcode
open TextBoost.xcodeproj
```

Build and run from Xcode (Cmd+R). TextBoost will appear in your menu bar.

### Setup

1. Click the TextBoost icon in the menu bar and open **Settings**
2. Add your API key (Anthropic or OpenAI)
3. Configure your preferred hotkey
4. Add or edit prompts to customize your rewrite styles

### Usage

1. Select text in any app
2. Press your hotkey
3. Pick a prompt from the floating panel
4. The rewritten text replaces your selection

## License

MIT
