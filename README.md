# `reexport::modules!`

A simple macro to declare modules and re-export their contents.


## Quick Start

Provide the macro with some number of module declarations:

```rust
reexport::modules! {
    mod foo;  // A private module.
    pub mod bar;  // A public module.

    #[cfg(feature = "baz")]
    mod baz;  // A module with an attribute.
}
```

And the macro will expand into something like this:

```rust
// Modules are declared as written in the macro.
// Then the contents of the module is re-exported with `pub use`.
mod foo;
pub use self::foo::*;

// Module declarations may include a visibility specifier.
pub mod bar;
pub use self::bar::*;

// If the original declaration contained any attributes,
// they are applied to both the `mod` statement and the `use` statement.
#[cfg(feature = "baz")] mod baz;
#[cfg(feature = "baz")] pub use self::baz::*;
```


## Dependencies

This macro has zero dependencies and is `no_std`.


## Testing

This crate uses [`macrotest`] to compare macro invocations against their
expected output. This requires that [`cargo expand`] is installed in your
testing environment.

[`macrotest`]: https://github.com/eupn/macrotest
[`cargo expand`]: https://github.com/dtolnay/cargo-expand


## Releases

Crate releases are built and published from GitHub Actions. There are two
release workflows:

- `release.yml` generates a draft GitHub Release. It is triggered when a new
  version tag is pushed to the repo.

- `publish.yml` published the crate to crates.io. It is triggered when the
  GitHub Release is marked as "published."

To prove that the crate was built from a checked-in source and workflow, the
release workflows will generate *attestations*. These are certificates, signed
by GitHub, that describes the crate and build process, including a hash of the
crate tarball, name of the workflow that performed the build, and the exact
commit hash it was built from.

You can view all attestations at
<https://github.com/cbarrick/reexport/attestations>.

For a given version on crates.io, you can download the crate and verify that it
was packaged from the public source at the corresponding tag using the following
command:

```shell
$ curl https://crates.io/api/v1/crates/reexport/2.0.0/download \
| gh attestation verify /dev/stdin --repo cbarrick/reexport --source-ref refs/tags/v2.0.0
```

Note that this only verifies that the tag pointed to the source of the crate
*at the time the crate was published*. If the tag is ever moved to a different
commit, the attestation check will continue to pass. Use the `--source-digest`
flag to verify the crate against a specific commit hash.

See docs/releasing.md for more details.


## History

The initial version of this crate is 2.0.0 because a different crate was
published under the same name to crates.io at version 1.0.0.

This initial version is likely feature complete. It will be maintained
indefinitely but is unlikely to see feature updates.


## License

Copyright 2026 Chris Barrick <<cbarrick1@gmail.com>>

Licensed under the MIT License.
