# BreakTime

A macOS menu bar app that reminds you to take breaks to prevent RSI. It tracks your active time across configurable break tiers (e.g. stretch every 20 min, walk every 60 min) and gently nudges you with warnings and overlay screens when it's time to step away.

## Install

```bash
git clone https://github.com/benjick/breaktime.git && cd breaktime
bash scripts/build-app.sh
cp -r .build/release/BreakTime.app /Applications/
```

Launch from Applications or Spotlight.
