# zig-quickphf

[![CI][ci-shd]][ci-url]
[![CD][cd-shd]][cd-url]
[![DC][dc-shd]][dc-url]
[![LC][lc-shd]][lc-url]

## Zig port of [quickphf library](https://github.com/dtrifuno/quickphf) for static hash map generation.

### Usage

- Add `quickphf` dependency to `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/tensorush/zig-quickphf#<git_tag_or_commit_hash>
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

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-quickphf/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/zig-quickphf/blob/main/.github/workflows/ci.yaml
[cd-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/zig-quickphf/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/tensorush/zig-quickphf/blob/main/.github/workflows/cd.yaml
[dc-shd]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=docs&labelColor=black
[dc-url]: https://tensorush.github.io/zig-quickphf
[lc-shd]: https://img.shields.io/github/license/tensorush/zig-quickphf.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/tensorush/zig-quickphf/blob/main/LICENSE
