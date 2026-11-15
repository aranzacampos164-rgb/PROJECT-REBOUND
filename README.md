# the game PROJECT: REBOUND

My game is a little space based platformer where you rocket has crashe dand you need to defeat 3 bosses on 3 seperate planets to regain the shard to help you build your hsip and get back home


## how to run it

1. Install Godot 4.3 or newer (this build was tested with Godot 4.7.2).
2. Open the Project Manager, choose **Import**, and select `project.godot`.
3. Let Godot import the art and audio on first open, then press the rectangle on top right hand cornr


## Controls

| Action | Keys |
| Move | `A` / `D` are `Left` / `Right` |
| Jump | `Space`, `W`, or `Up` (a quick press to hop) |
| Fire pulse blast | `J`, `X`, or `Z` |
| Bounce pad |first you land on it and then hold Jump if you extra height |
| Menus | arrow keys, `Enter` to confirm, `Esc` to go back |
| Pause | `Esc` while playing |
| Delete a save | on the save screen, select a slot and press `Backspace` twice to confirm its deletion |


## Game flow

- **Title** -> **START** -> choose one of three save slots.
- **rocket crash site ** -> step into a planet portal.
- **Centura / Astra / Ventura** -> cross the level, beat the guardian, take its shard.
- Return to the Haven after all three shards to trigger the ending.
- Progress autosaves on level transitions and when you leave a level.


## Planets and bosses

| Planet | Theme | Guardian | HP | Attack |
| Centura | Rust canyons | Stone Guardian (green slime) | 10 | Single shot |
| Astra | Frozen sky | Ice Crystal (blue slime) | 14 | triple shot |
| Ventura | Lava and black glass | Inferno Core (fire slime) | 18 | Fast triple shot |

Bosses are big slimes built from the same sprite sheets as the regular slimes just sized up


## Audio

- **Music:** `music/menu.ogg` ("Underclocked" by Eric Skiff) loops for the whole game: title, saves, cutscenes, levels, and the pause menu. The original file was Ogg Opus; it was re-encoded to Ogg Vorbis so Godot can import it.
- **SFX** live in `audio/` and are played through the `Sfx` autoload it `sfx.gd` (8-voice pool):
	

| Event | File |
|---|---|
| Player takes damage | `audio/hurt.mp3` |
| Player runs out of HP or falls | `audio/lose_life.mp3` |
| Player fires | `audio/shoot.mp3` |
| Boss fires | `audio/explosion.mp3` |

Volumes are set in code: music `-12 dB`, shoot `-10 dB`, hurt/explosion `-6 dB`,
lose-life `-4 dB`. Replace a file with the same name to swap a sound, or edit the
paths in `sfx.gd`.


## Saving

- Three slots, stored in `user://rebound_slot_0.json` through
  `user://rebound_slot_2.json`.
- On macOS: `~/Library/Application Support/Godot/app_userdata/PROJECT- REBOUND/`.
- To erase one: title -> **START** -> highlight the slot -> press `Delete` or
  `Backspace` twice. The first press asks for confirmation; `Esc` or `Enter`
  cancels.


## Cutscenes

- The intro, inter-planet travel, and ending are text cutscenes in `cutscene.gd`.
- Pages are defined in `main.gd` (`_intro_pages()`, `_travel_pages()`).
- `Enter` skips ahead; `Esc` jumps to the end of the flight.

<img width="1280" height="832" alt="Screenshot 2026-11-15 at 4 49 45 PM" src="https://github.com/user-attachments/assets/4a250de2-674b-4a95-bf77-05366dfacf61" />
<img width="1280" height="832" alt="Screenshot 2026-11-15 at 4 49 40 PM" src="https://github.com/user-attachments/assets/2d56a760-f1b4-4513-8d6b-37dea33895f0" />
<img width="1280" height="831" alt="Screenshot 2026-11-15 at 4 49 33 PM" src="https://github.com/user-attachments/assets/cb4045ac-09b5-4041-aeba-7e7936d853f1" />
<img width="1280" height="832" alt="Screenshot 2026-11-15 at 4 49 29 PM" src="https://github.com/user-attachments/assets/770cdabb-b952-49b0-882a-facd37543c4d" />
<img width="1280" height="832" alt="Screenshot 2026-11-15 at 4 49 22 PM" src="https://github.com/user-attachments/assets/3354de65-a8d8-42ff-b95b-ec507c8503b8" />
