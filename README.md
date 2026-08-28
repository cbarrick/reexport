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


## History

The initial version of this crate is 2.0.0 because a different crate was
published under the same name to crates.io at version 1.0.0.

This initial version is likely feature complete. It will be maintained
indefinitely but is unlikely to see feature updates.


## License

Copyright 2026 Chris Barrick <<cbarrick1@gmail.com>>

Licensed under the MIT License.
