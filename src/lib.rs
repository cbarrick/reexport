// SPDX-License-Identifier: MIT
//
// Copyright 2026 Chris Barrick <cbarrick1@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// The doc comment is inherited from the README and doctests are disabled.
// The examples in the README are untestable as written, and we want proper
// syntax highlighting in the README. This prevents us from marking the code
// blocks as `ignore` without breaking syntax highlighting elsewhere.
// (Doctests are disabled in Cargo.toml.)
#![doc = include_str!("../README.md")]
#![no_std]

/// A simple macro to declare modules and re-export their contents.
///
/// See the [crate-level documentation] for more details.
///
/// [crate-level documentation]: crate
#[macro_export]
macro_rules! modules {
    {$($(#[$attr:meta])* $vis:vis mod $name:ident ;)*} => {
        $(
            $(#[$attr])*
            $vis mod $name;

            $(#[$attr])*
            pub use self::$name::*;
        )*
    };
}
