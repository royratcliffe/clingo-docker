if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
  package.path = os.getenv("LOCAL_LUA_DEBUGGER_PATH") .. ";" .. package.path
  assert(require("lldebugger")).start()
end

local clingo = require "clingo"
local control = clingo.Control()
control:add("base", {}, [[
a :- not b.
b :- not a.
]])
control:ground { { "base", {} } }
local solve_result = control:solve {
  on_model = function(model)
    for _, symbol in ipairs(model:symbols { shown = true }) do
      print(symbol)
    end
  end
}
print(solve_result)
