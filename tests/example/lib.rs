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

// This file is expanded using `cargo expand` and compared against the file
// `main.expanded.rs`. Note that `cargo expand` also inlines modules and
// processes `cfg` attributes, in addition to expanding macros. So the expanded
// file includes inlined modules, even though the macro outputs a simple module
// declaration.

#![allow(unexpected_cfgs)]

reexport::modules! {
    mod foo;  // A private module.
    pub mod bar;  // A public module.

    // `cargo expand` will automatically evaluate `#[cfg(...)]`, so we can't test
    // for cfg attributes in the output directly. Instead, we have two cases, one
    // where the cfg is true and one where it is false. To test that the macro
    // output includes the cfg, we expect `cargo expand` to keep the one where it
    // evaluates to true and to strip the one where it evaluates to false.
    #[cfg(true)] mod baz;
    #[cfg(false)] mod quux;
}
