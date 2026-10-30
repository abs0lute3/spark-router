message for github
## Disclaimer

### 1. Educational and Research Purposes Only
This software is provided strictly for educational, research, and authorized testing purposes. It is not intended to be used for malicious purposes or in any environment without the explicit consent of the owner(s) of the target systems.

### 2. No Warranty (As-Is)
This code is provided "as is" without warranty of any kind, either expressed or implied, including but not limited to the implied warranties of merchantability and fitness for a particular purpose. The entire risk as to the quality and performance of the software is with you.

### 3. Limitation of Liability
In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software. You assume all responsibility and liability for any misuse, damage, or legal consequences resulting from the execution or modification of this code.

## Files (two scripts, plus Shelly's lines and portrait)

| File | What it is |
|---|---|
| `DandysWorld.lua` | DandyHub source, obfuscated with luaobfuscator.com. One fetch, runs. |
| `BikeUniverse.lua` | Bike script source, obfuscated with luaobfuscator.com. One fetch, runs. |
| `Text Lines.txt` | Shelly's lines, sorted by action. Add a line, she says it. |
| `Shelly.png` | Her portrait for the hub panel. |
| `rayfield.lua` | The UI library, mirrored here so the hub does not depend on sirius.menu. |

No router, no multi-hop fetching, no notifications — each file is fully self-contained: download, execute.

## Loadstrings (what users execute)

Dandy's World:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/abs0lute3/spark-router/main/DandysWorld.lua"))()
```

Bike Universe:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/abs0lute3/spark-router/main/BikeUniverse.lua"))()
```

## Updating (for AI agents)

Run the GUI in `Push (Read this for AI agents)/`:

```
python update_gui.py
```

First run: paste your luaobfuscator.com API key into the GUI and Save it (stored locally, never committed). Then pick each source file, hit Update, then Commit + Push. That's it.
