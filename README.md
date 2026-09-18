# RLengine 3.0 — Quantum Dynamics & PostFX Edition

**RLengine 3.0** is a major overhaul of the high-performance LuaJIT/FFI 3D particle physics engine for LÖVE2D. Built for maximum speed, visual fidelity, and interactive sandbox experimentation, version 3.0 introduces real-time 3D shape morphing, custom GLSL shaders, multi-shockwave physics, and a completely modernized interface.

---

### What's New in Version 3.0

* **Completely Overhauled & Redesigned UI/HUD**
* Modernized translucent cyber-style HUD panel with custom borders and glowing status indicators.
* Real-time performance diagnostics showing exact FPS, frametime in milliseconds, and active Lua Memory (RAM) usage.
* Formatted particle counters (e.g., `1,500,000 / 3,000,000`) paired with a dynamic visual particle capacity progress bar.
* Clean, scannable keybinding reference guide for rapid experimentation.


* **3D Shape Morphing Engine (`[F1]–[F8]`)**
* **8 Procedural Geometries:** Switch smoothly between *Cube Dust, Fibonacci Sphere, Cosmic Galaxy, Torus Ring, Spatial Lattice, 4D Tesseract Projection, DNA Helix,* and *Accretion Black Hole*.
* **Smooth Spring Interpolation:** Particles fluidly morph towards target shape vectors (`ox, oy, oz`) with lock/free state toggles (`[M]`).


* **Multi-Shockwave System (`[E]` / `[MMB]`)**
* FFI-driven shockwave pool supporting up to **16 simultaneous active radial impulses** with independent expansion radii and speed vectors.


* **GLSL Post-Processing & Rendering Pipeline**
* **Custom Pixel Shader:** Real-time Chromatic Aberration (`[P]`) for dynamic RGB edge-splitting.
* **Motion Trails & Blending:** Motion blur trail buffer (`[T]`) combined with instant toggling between Additive Neon and Alpha Soft blending modes (`[B]`).


* **Expanded Quantum Force Fields (`[1]–[6]`)**
* Added complex non-linear physics models, including *Dipole Magnetic Fields* and *Lorenz Chaotic Attractors*, alongside classic Singularity and Anti-Gravity forces.


* **3D Raycast Interaction & Orbit Camera (`[C]`)**
* **3D Cursor Projection:** Force fields now cast rays directly into 3D world space relative to the camera instead of locked 2D screen positions.
* **Cinematic Orbit Camera:** Smooth auto-rotating camera mode with mouse wheel distance zooming.


* **Color Palette System (`[7]–[0]`)**
* 8 pre-computed fast Look-Up-Table (LUT) palettes, featuring new *Acid Toxic* and *Neon Synth* color profiles.
