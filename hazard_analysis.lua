-- Space Shuttle Hazard Analysis using Answer Set Programming
--
-- Models a fault tree for a simplified space shuttle propulsion and
-- flight-control system. The ASP solver enumerates every minimal cut
-- set: the smallest combinations of component failures that produce a
-- catastrophic mission outcome.
--
-- Run inside the Docker container:
--   docker run --rm -v $(pwd):/srv clingo-lua54 hazard_analysis.lua
--
-- "--opt-mode=optN" asks clingo to enumerate ALL models that share the
-- minimum optimisation cost, giving us all minimum-cardinality cut sets.

local clingo = require "clingo"

local control = clingo.Control { "--opt-mode=optN" }

control:add("base", {}, [[
  % ── System components ────────────────────────────────────────────────
  component(main_engine(1..3)).   % three main propulsion engines
  component(fuel_pump).           % propellant feed
  component(flight_computer).     % primary guidance
  component(backup_computer).     % redundant guidance
  component(thermal_shield).      % re-entry heat protection
  component(abort_system).        % crew/vehicle escape capability

  % ── Generate failure scenarios ────────────────────────────────────────
  % Each component independently may or may not fail in a given scenario.
  { failed(C) } :- component(C).

  % ── Fault propagation ─────────────────────────────────────────────────
  % Propulsion loss: fuel supply cut or all three engines out.
  propulsion_loss :- failed(fuel_pump).
  propulsion_loss :- failed(main_engine(1)),
                     failed(main_engine(2)),
                     failed(main_engine(3)).

  % Guidance loss: both computers down simultaneously.
  guidance_loss :- failed(flight_computer), failed(backup_computer).

  % Thermal breach: heat shield fails during re-entry.
  thermal_breach :- failed(thermal_shield).

  % ── Catastrophic hazard conditions ────────────────────────────────────
  % Loss of propulsion combined with loss of guidance.
  catastrophic :- propulsion_loss, guidance_loss.
  % Thermal breach when the abort system cannot protect the crew.
  catastrophic :- thermal_breach, failed(abort_system).
  % Thermal breach combined with propulsion loss (no escape possible).
  catastrophic :- thermal_breach, propulsion_loss.

  % ── Constraint: retain only catastrophic scenarios ────────────────────
  :- not catastrophic.

  % ── Objective: minimise the number of component failures ──────────────
  % Combined with --opt-mode=optN this yields all minimum-cardinality
  % cut sets (smallest failure combinations that cause the hazard).
  #minimize { 1,C : failed(C) }.

  #show failed/1.
]])

control:ground { { "base", {} } }

print("Space Shuttle Hazard Analysis")
print("Minimal cut sets -- smallest failure combinations causing catastrophic loss:")
print(string.rep("-", 64))

local n = 0
local solve_result = control:solve {
  on_model = function(model)
    n = n + 1
    local failures = {}
    for _, sym in ipairs(model:symbols { shown = true }) do
      local arg = tostring(sym):match("failed%((.-)%)")
      if arg then
        table.insert(failures, arg)
      end
    end
    table.sort(failures)
    print(string.format("  Cut set %2d: { %s }", n, table.concat(failures, ", ")))
  end
}

print(string.rep("-", 64))
print(string.format("  %d minimal cut set(s) found.  Solve result: %s",
  n, tostring(solve_result)))
