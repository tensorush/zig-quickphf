# zig-quickphf

## Zig port of [quickphf library](https://github.com/dtrifuno/quickphf) for static hash map generation.

### Usage

- Add `quickphf` dependency to `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/tensorush/zig-quickphf
```

- Use `quickphf` dependency in `build.zig`.

```zig
const quickphf_dep = b.dependency("quickphf", .{
    .target = target,
    .optimize = optimize,
});
const quickphf_mod = quickphf_dep.module("quickphf");
<compile>.root_module.addImport("quickphf", quickphf_mod);
```
