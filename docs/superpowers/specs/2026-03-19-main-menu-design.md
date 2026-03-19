# Main Menu Screen Design

## Goal

Add a main menu screen that displays before gameplay begins. The menu shows the game title, logo, and a "Start" prompt over a demo level where an AI-controlled player runs around collecting tiles.

## Architecture

**New main scene:** `MainMenu.tscn` replaces `Game.tscn` as `project.godot`'s `run/main_scene`. The Game scene is loaded via `change_scene_to_file()` when the player starts.

**GameManager change:** Remove `call_deferred("load_level", start_level)` from `_ready()`. Instead, `GameCamera._ready()` calls `GameManager.load_level(0)` so levels only load when the Game scene is active.

## Scene Structure

```
MainMenu (Node2D) — scripts/MainMenu.gd
├── DemoLevel (Node2D)          — procedurally built flat level
│   ├── Floor tiles (gray)      — solid ground row
│   ├── Color tiles (random)    — collectible tiles above floor
│   └── Player (Player.tscn)    — AI-driven, input disabled
├── HUD (CanvasLayer)
│   ├── LogoImage (TextureRect) — icon.png, centered horizontally, upper screen
│   ├── TitleLabel (RichTextLabel) — "Pixel Monster", large bold, rainbow per-character
│   └── StartLabel (Label)      — "Press Enter to Start" or "Tap to Start", pulsing
```

## Demo Level

- Built procedurally in `MainMenu._ready()` — no level PNG
- ~20 `ColorSource` tiles in a single row with random RGB colors, positioned along the lower portion of the screen
- A row of gray `StaticBody2D` tiles beneath for the player to walk on
- Uses a real `Player.tscn` instance with `set_process_unhandled_input(false)` to block real input
- AI logic in `MainMenu._process()`:
  - Injects move_left/move_right actions to walk toward the edge, then reverses
  - Occasionally injects a jump
  - Player collects tiles normally (particles, color blending, sounds all work)
- When all color tiles are collected:
  - Brief pause (~1s)
  - Respawn all tiles with new random colors
  - Reset player color to white

## Title Display

- **Logo:** `icon.png` loaded as a `TextureRect`, centered horizontally, positioned in the upper third of the screen
- **Title:** `RichTextLabel` with BBCode for per-character rainbow coloring: "Pixel Monster" in large bold text, centered below the logo
- **Start prompt:** `Label` with "Press Enter to Start" (desktop) or "Tap to Start" (mobile, detected via `DisplayServer.is_touchscreen_available()`). Pulsing opacity animation via a simple sine wave on `modulate.a`

## Input / Transition

- Start triggered by:
  - `Input.is_action_just_pressed("jump")`
  - `Input.is_action_just_pressed("ui_accept")` (Enter key)
  - Any screen tap on mobile (via `_unhandled_input` checking `InputEventScreenTouch`)
- Transition: `get_tree().change_scene_to_file("res://scenes/Game.tscn")`
- GameManager autoload persists across scenes — no state lost

## Mobile Layout

- GameManager still configures the viewport/gutters in its `_ready()` (runs before any scene)
- Demo level and title UI centered over the 1024px game area (offset by left gutter on mobile)
- No touch controls shown on the menu screen

## Files Changed

| File | Change |
|------|--------|
| `scenes/MainMenu.tscn` | New scene |
| `scripts/MainMenu.gd` | New script — demo level, AI player, title, transition |
| `project.godot` | `run/main_scene` → `res://scenes/MainMenu.tscn` |
| `scripts/autoloads/GameManager.gd` | Remove `call_deferred("load_level")` from `_ready()` |
| `scripts/autoloads/GameCamera.gd` | Add `GameManager.load_level(0)` in `_ready()` |
