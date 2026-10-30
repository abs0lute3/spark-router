# SparkRouter — private repo

Game-detecting loader for the user's Roblox scripts. **Lua here is a Roblox script** (runs in the executor). The Python push tooling lives in `Push (Read this for AI agents)/`.

## What it does

`Router.lua` checks `game.GameId` (with `game.PlaceId` fallback):

| Game | Universe (GameId) | Main PlaceId | Behavior |
|---|---|---|---|
| Dandy's World | 5569032992 | 16116270224 | Sends a Roblox notification, downloads the **latest** DandyHub paste, decrypts, executes |
| Bike Universe | 10768284407 | 98628861455414 | **Nothing yet** — shows "coming soon", reserved for another AI agent |
| Anything else | — | — | "Unsupported game" notification, stops |

## Setup (make this repo private on GitHub)

```bash
cd SparkRouter
git init
git add Router.lua README.md
git commit -m "SparkRouter v1: Dandy live, Bike reserved"
gh repo create spark-router --private --source=. --push
```

Or create an empty **private** repo on github.com first, then:

```bash
git remote add origin https://github.com/YOUR-USERNAME/spark-router.git
git branch -M main
git push -u origin main
```

## Wire it to your latest paste

1. `cd "Push (Read this for AI agents)"` → `push.bat new dandy-v1 ..\DandyHub.lua`
2. `push.bat list` won't show secrets — open `pastes.json`, copy `raw_url` + `key` for `dandy-v1`.
3. Paste them into `Router.lua` → `CONFIG.DANDY.raw_url` / `CONFIG.DANDY.key`.
4. `git commit -am "point router at latest dandy paste" && git push`.
5. After later `push.bat update dandy-v1 ...` runs, the URL is unchanged — you only re-edit `Router.lua` if you rotated the key (`--new-key`).

## The loadstring (what users execute)

```
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR-USERNAME/spark-router/main/Router.lua"))()
```

Replace `YOUR-USERNAME`/`spark-router` with the real repo path. Note: a **private** repo's raw URL needs access — either keep just this router file in a public repo and everything else private, or append a read-only personal access token you never share publicly. The payload pastes stay encrypted on rentry regardless.
