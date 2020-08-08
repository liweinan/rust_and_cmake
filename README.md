## USAGE

```bash
$ cargo clean                                                                                                                                                                                                                   15:25:02
$ cargo build                                                                                                                                                                                                                   15:26:52
   Compiling cc v1.0.58
   Compiling cmake v0.1.44
   Compiling rust_and_cmake v0.1.0 (/Users/weli/works/rust_and_cmake)
    Finished dev [unoptimized + debuginfo] target(s) in 2.34s
$ cargo run                                                                                                                                                                                                                     15:26:55
    Finished dev [unoptimized + debuginfo] target(s) in 0.01s
     Running `target/debug/rust_and_cmake`
Hello, world from Rust!
Hello, world from C! Value passed: 3.141590
```

## DEBUG

```bash
$ cd target/debug/                                                                                                                                                                                          15:31:19
$ ls                                                                                                                                                                                                        15:31:21
build/               deps/                examples/            incremental/         rust_and_cmake*      rust_and_cmake.d     rust_and_cmake.dSYM@
$ lldb rust_and_cmake                                                                                                                                                                                       15:31:21
(lldb) target create "rust_and_cmake"
Current executable set to '/Users/weli/works/rust_and_cmake/target/debug/rust_and_cmake' (x86_64).
(lldb) list
   7   	fn main() {
   8   	    println!("Hello, world from Rust!");
   9
   10  	    // calling the function from foo library
   11  	    unsafe {
   12  	        testcall(3.14159);
   13  	    };
   14  	}
(lldb) b 12
Breakpoint 1: where = rust_and_cmake`rust_and_cmake::main::hb3a365e76c289cd7 + 72 at main.rs:12:9, address = 0x0000000100000a98
(lldb) run
Process 7294 launched: '/Users/weli/works/rust_and_cmake/target/debug/rust_and_cmake' (x86_64)
Hello, world from Rust!
Process 7294 stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.1
    frame #0: 0x0000000100000a98 rust_and_cmake`rust_and_cmake::main::hb3a365e76c289cd7 at main.rs:12:9
   9
   10  	    // calling the function from foo library
   11  	    unsafe {
-> 12  	        testcall(3.14159);
   13  	    };
   14  	}
Target 0: (rust_and_cmake) stopped.
(lldb) b testcall
Breakpoint 2: where = rust_and_cmake`testcall + 13 at foo.c:5:55, address = 0x0000000100000b3d
(lldb) run
There is a running process, kill it and restart?: [Y/n] n
(lldb) c
Process 7294 resuming
Process 7294 stopped
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 2.1
    frame #0: 0x0000000100000b3d rust_and_cmake`testcall(value=3.14159012) at foo.c:5:55
   2
   3   	// https://flames-of-code.netlify.app/blog/rust-and-cmake/
   4   	void testcall(float value) {
-> 5   	    printf("Hello, world from C! Value passed: %f\n", value);
   6   	}
Target 0: (rust_and_cmake) stopped.
```

## Shared Library Sample Project

* [Sample of building C based dynamic library with CMAKE and Rust main code to use the library.](https://github.com/liweinan/rust_and_cmake_dyn)
