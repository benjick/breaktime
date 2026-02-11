# BreakTime

A macOS menu bar app that reminds you to take breaks to prevent RSI. It tracks your active time across configurable break tiers (e.g. stretch every 20 min, walk every 60 min) and gently nudges you with warnings and overlay screens when it's time to step away.

## Install

1. Download **BreakTime.dmg** from the [latest release](https://github.com/benjick/breaktime/releases/latest)
2. Open the DMG and drag BreakTime to Applications
3. Run this once in Terminal to remove the quarantine flag:
   ```bash
   xattr -cr /Applications/BreakTime.app
   ```
4. Launch from Applications or Spotlight

## Dev Install

```bash
git clone https://github.com/benjick/breaktime.git && cd breaktime
bash scripts/build-app.sh
cp -r .build/release/BreakTime.app /Applications/
```
