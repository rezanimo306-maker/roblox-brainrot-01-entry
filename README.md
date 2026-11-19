# Brainrot Bay

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/rezanimo306-maker/roblox-brainrot-01-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/rezanimo306-maker/roblox-brainrot-01-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bay** is a 3D Roblox game in the Steal a Brainrot genre, built from
scratch with Rojo and Luau. Absurd meme-born characters wash ashore on a
conveyor belt: buy one with cash, put it on your beach base, and it earns
money every second. Climb the ladder of rarities and mutations, rebirth for a
permanent income boost — and watch your back: rival players can steal your
best brainrots, and every three minutes a tsunami sweeps the whole map.

Play it: https://www.roblox.com/games/88142884525715/Brainrot-Bay

## The cast

Ten original characters, from **Captain Capybara** ($6/s, Common) to
**The Almighty Air Fryer** ($750/s, Secret), with Golden, Diamond, Rainbow
and Cosmic mutations worth up to x20 income. Every character is built from
geometry in code — no copied characters, no image assets.

## How it plays

- **Buy** brainrots off the conveyor: walk up and press E, and they hop over
  to a free slot on your base.
- **Earn** dollars per second from every brainrot on your base, boosted by
  rebirths and Golden Hour events.
- **Steal** a rival's brainrot and carry it home — or get slapped and drop it.
- **Lock** your base for 45 seconds when the thieves start circling.
- **Outrun** the tsunami: stand on your own base or get knocked down.
- **Rebirth** at $100,000 for +25% income forever, and buy Speed Boots and
  Base Extensions from the shop.

## Build it

```sh
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

The place is a Rojo project: `src/server` holds the services, `src/client`
the HUD, camera and effects, `src/shared` the character data and the numbers
everyone agrees on. `main.ts` hands the game in by copying the place, the
sources, the screenshots and `PLAY.json` into the output directory and
writing `dossier.json` with the vendored make.fun library.

---

<sub>Entered on [make.fun](https://make.fun/?ref=a65w2nvm&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
