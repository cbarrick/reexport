#![no_std]
#![allow(unexpected_cfgs)]
mod foo {
    //! This module exsit only because it is referenced by a test case.
}
pub use self::foo::*;
pub mod bar {
    //! This module exsit only because it is referenced by a test case.
}
pub use self::bar::*;
mod baz {
    //! This module exsit only because it is referenced by a test case.
}
pub use self::baz::*;
