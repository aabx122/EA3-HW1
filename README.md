# Mechanics Learning Lab

Mechanics Learning Lab is a MATLAB teaching application for two mechanics
topics:

- motion of a box on a frictional ramp;
- one-dimensional elastic and inelastic collisions.

The application includes animations, position/speed/momentum/energy plots,
initial and final state summaries, configurable final conditions, and
conservation checks.

## Run in MATLAB

Requirements:

- MATLAB R2025a or a compatible release;
- no additional toolbox is required for the simulation source code.

From the repository folder, run:

```matlab
launchPhysicsTeachingApp
```

## Verify the physics engines

```matlab
testRamp
testCollision
```

Both scripts contain assertions and print their conservation errors.

## Build the Windows executable

A Windows `.exe` must be compiled on Windows using MATLAB Compiler. Follow
[WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md), or run the provided build
function from Windows MATLAB:

```matlab
results = buildWindowsExe;
```

The generated executable is named `MechanicsLearningLab.exe` and is placed
in a timestamped folder under `build/`.

## Source files

| File | Purpose |
| --- | --- |
| `launchPhysicsTeachingApp.m` | Application and compiler entry point |
| `PhysicsTeachingApp.m` | User interface, plots, animations, and callbacks |
| `simulateRamp.m` | Frictional-ramp physics engine |
| `simulateCollision.m` | One-dimensional collision physics engine |
| `testRamp.m` | Ramp verification cases |
| `testCollision.m` | Collision verification cases |
| `buildWindowsExe.m` | Reproducible Windows build command |

## Deployment note

Computers without MATLAB need the MATLAB Runtime version corresponding to
the MATLAB release used for compilation. Confirm with the instructor whether
the submission should contain only the `.exe` or a packaged installer.
