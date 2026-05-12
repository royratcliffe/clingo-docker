# Clingo in a Docker Container with Lua 5.x Support

The `Dockerfile.lua5x` builds a container with Clingo and Lua 5.x support. It is based on the official Ubuntu image and installs the necessary dependencies, including Lua 5.x and its development headers. The Clingo source code is cloned from the official repository, built using CMake and Ninja, and installed in the container.

To build the Docker image, run the following command in a terminal:

```bash
docker build -f Dockerfile.lua5x --build-arg LUA_VERSION=5.4 -t clingo-lua54 .
docker run -it --rm clingo-lua54 -e "require('clingo')"
```

Test the Lua 5.4 support by running the second command, which will start a Lua 5.4 interpreter and attempt to require the Clingo module. If everything is set up correctly, you should see no errors, indicating that Clingo is successfully integrated with Lua 5.4 in the Docker container.

## Customisation and Testing

Note that the `Dockerfile.lua5x` allows you to specify the Lua version to install by passing the `LUA_VERSION` build argument. You can choose between Lua 5.1, 5.2, 5.3, and 5.4 by setting the appropriate version number when building the image. It defaults to Lua 5.4 if no version is specified.

The Docker configuration is designed to be flexible and can be easily modified to include additional dependencies or configurations as needed. You can customise the `Dockerfile.lua5x` to suit your specific requirements, such as adding more Lua libraries or changing the base image.

It accounts for the architecture of the system, ensuring compatibility with both x86_64 and ARM64 platforms. This makes it suitable for a wide range of environments, including development machines and production servers.

### Testing the Clingo Lua API

You can also test the Clingo Lua API by running a simple Lua script that uses Clingo. Create a file named `test.lua` with the following content:

```lua
local clingo = require "clingo"
local control = clingo.Control()
control:add("base", {}, [[
a :- not b.
b :- not a.
]])
control:ground { { "base", {} } }
local res = control:solve {
  on_model = function(model)
    for _, atom in ipairs(model:symbols { shown = true }) do
      print(atom)
    end
  end
}
print(res)
```

Then, run the script inside the Docker container:

```bash
docker run --rm -v $(pwd):/srv clingo-lua54 test.lua
```

The `-v` option mounts the current directory into the container in its default working directory, allowing access the `test.lua` script. If everything is set up correctly, you should see the output of the Clingo model and the result of the solving process.

```text
b
SAT
```

## Hazard Analysis Example

The repository also includes `hazard_analysis.lua`, an Answer Set Programming model that performs a **fault-tree analysis** of a simplified space shuttle system.

The model contains:

* **Components** — three main engines, a fuel pump, primary and backup flight computers, a thermal heat shield, and an abort system.
* **Fault propagation rules** — propulsion loss, guidance loss, and thermal breach are derived from component failures.
* **Hazard conditions** — three combinations of intermediate faults that constitute a catastrophic mission outcome.
* **Objective** — `#minimize` reduces the search to the smallest failure combinations; running with `--opt-mode=optN` then enumerates **all** minimum-cardinality **minimal cut sets** (the irreducible failure combinations that cause the hazard).

Run the analysis inside the Docker container:

```bash
docker run --rm -v $(pwd):/srv clingo-lua54 hazard_analysis.lua
```

Expected output:

```text
Space Shuttle Hazard Analysis
Minimal cut sets -- smallest failure combinations causing catastrophic loss:
----------------------------------------------------------------
  Cut set  1: { abort_system, thermal_shield }
  Cut set  2: { fuel_pump, thermal_shield }
----------------------------------------------------------------
  2 minimal cut set(s) found.  Solve result: SAT
```

Each cut set identifies components whose simultaneous failure is sufficient—and necessary—to produce a catastrophic outcome, directly supporting safety and reliability engineering activities such as FMEA and FMECA.
