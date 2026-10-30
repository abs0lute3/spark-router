# SparkRouter — public repo

Game-detecting loader for the user's Roblox scripts. **Lua here is a Roblox script** (runs in the executor). The Python push tooling lives in `Push (Read this for AI agents)/`.

Repo: **https://github.com/abs0lute3/spark-router** (public — executors fetch `Router.lua` and `payloads/*.enc` via `raw.githubusercontent.com` with plain `game:HttpGet`, no auth).

## What it does

`Router.lua` (commentless, single file) checks `game.GameId` (with `game.PlaceId` fallback):

| Game | Universe (GameId) | Main PlaceId | Behavior |
|---|---|---|---|
| Dandy's World | 5569032992 | 16116270224 | Roblox notification, downloads the latest `payloads/dandy-v1.enc`, decrypts with embedded key, executes |
| Bike Universe | 10768284407 | 98628861455414 | **Nothing yet** — "coming soon" notification, reserved for another AI agent |
| Anything else | — | — | "Unsupported game" notification, stops |

`payloads/` holds the encrypted blobs (`Base64(XOR(source, key))`). Same filename = same URL forever — updating is just overwrite + push.

## Updating a payload (for AI agents)

```bash
cd "Push (Read this for AI agents)"
python push.py publish dandy-v1 ../DandyHub.lua   # or: push.bat publish dandy-v1 ..\DandyHub.lua
cd ../SparkRouter
git add payloads/dandy-v1.enc
git commit -m "update dandy-v1"
git push
```

Key rotation: `push.py publish dandy-v1 ../DandyHub.lua --key NEWKEY`, then also update `CONFIG.DANDY.key` in `Router.lua`, commit both, push. Old key = router can't decrypt.

## The loadstring (what users execute)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/abs0lute3/spark-router/main/Router.lua"))()
```
