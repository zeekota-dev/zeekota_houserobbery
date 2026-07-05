# ZeeKota House Robbery

Professional FiveM house robbery resource by ZeeKota.

Resource name: `zeekota_houserobbery`

## Dependencies

- `ox_lib`
- `ox_inventory`
- ESX or QBCore
- A MySQL provider, preferably `oxmysql`

Start order example:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure es_extended # or qb-core
ensure zeekota_houserobbery
```

## Installation

1. Place `zeekota_houserobbery` in your server resources folder.
2. Import `sql/install.sql` into your database.
3. Add the ensure lines above to `server.cfg`.
4. Configure `shared/config.lua` for your economy, police jobs, dispatch provider, houses, loot, levels, and peds.
5. Restart the server.

## Framework Setup

`Config.Framework = 'auto'` detects ESX or QBCore from running resources.

Use `Config.Framework = 'esx'` or `Config.Framework = 'qbcore'` to force a framework. The bridge handles identifiers, names, jobs, framework money, usable items, and police counts. Inventory is always handled through `ox_inventory`.

## Contact Ped

Edit `Config.ContactPed` for model, coordinates, scenario, blip, interaction distance, and ox_lib text UI copy. Players walk to this ped and press `E` to open the ZeeKota House Robbery NUI.

## Houses

All houses live in `Config.Houses`. Nothing is hardcoded.

Each house supports:

- Outside `entrance`
- `interiorSpawn`
- `exit`
- `tier`
- `requiredLevel`
- `requiredItem`
- `cooldown`
- `dispatchAlertChance`
- `lootZones`
- `pedSpawns`
- `interior` label

Add a new house by copying an existing entry and changing the coordinates, tier, required level, loot, and ped spawns.

## Loot Zones

Each loot zone is validated server-side by zone index, active robbery state, searched state, and distance. Rewards are rolled server-side and granted through `ox_inventory`.

Example loot entry:

```lua
{
    coords = vector3(262.86, -1002.74, -99.01),
    radius = 1.2,
    label = 'Search Drawer',
    duration = 5000,
    policeAlertChance = 5,
    requiredItem = nil,
    loot = {
        { item = 'money', min = 500, max = 1500, chance = 80 },
        { item = 'rolex', min = 1, max = 2, chance = 20 }
    }
}
```

Set item values in `Config.Rewards.itemValues` so stats and XP reflect realistic loot value.

## XP and Levels

Progression is controlled in `Config.Progression`.

Players gain XP from successful robberies, house tier, loot value, and stealth completion. Failed or cancelled robberies can grant reduced XP. Tier level gates are set in `levelRequiredByTier`.

## Cooldowns

`Config.Cooldowns` supports:

- Per-player cooldowns
- Per-house cooldowns
- Global cooldowns
- Cancel penalty cooldowns

The UI displays remaining cooldown on each contract.

## Police Requirement

Set required police in:

```lua
Config.PoliceRequirement.required = 2
Config.PoliceJobs = { 'police', 'sheriff', 'state' }
```

For QBCore, `countDutyOnly = true` counts only on-duty jobs.

## Dispatch

Supported systems:

- `cd_dispatch`
- `qs-dispatch`
- `ps-dispatch`
- `custom`

Set:

```lua
Config.Dispatch.system = 'cd_dispatch'
```

Dispatch can trigger from failed keypad attempts, door breach, noisy loot, gunfire, and completion depending on `Config.Dispatch.triggers`.

For custom dispatch, set `Config.Dispatch.system = 'custom'` and change `Config.Dispatch.customClientEvent`.

## Armed Peds

Configure armed occupants in `Config.ArmedPeds`. Higher tier houses can spawn more hostile peds using `spawnByTier` and `chanceByTier`. Peds are cleaned up when the robbery ends or is cancelled.

## Commands

Default:

```text
/cancelhouserobbery
```

This cancels the active robbery, teleports the player outside if needed, cleans local peds/blips/prompts, applies optional failed/cancelled stats, and can apply a cooldown penalty.

## Security Notes

Server validates:

- Police count
- Cooldowns
- Level requirements
- Required items
- Active robbery state
- Door distance
- Loot zone distance
- One-time loot zones
- Reward rolls and amounts
- XP and stats
- Completion and cancellation

The client never grants rewards.

## Troubleshooting

- UI does not open: verify `ox_lib` is started before this resource.
- No rewards: verify item names exist in `ox_inventory`.
- Stats do not save: import `sql/install.sql` and ensure `oxmysql` or `mysql-async` is running.
- Police count is wrong: check `Config.PoliceJobs` and QBCore duty state.
- Dispatch does not fire: confirm the provider resource is started and `Config.Dispatch.system` matches its resource name.
- Interior exits feel wrong: tune `interiorSpawn`, `exit`, and `entrance` coordinates per house.
