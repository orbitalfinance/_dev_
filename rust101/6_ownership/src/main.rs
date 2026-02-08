fn main() {
    let s: &str = "hello"; //string literal: s as (&str, length) to the bytes in the static memory. On the stack at runtime.
    println!("{s}!");

    //not mutable String
    let s1: String = String::from("hello");
    println!("{s1}!");

    //mutable String
    let mut mstring: String = String::from("hello");
    mstring.push_str(", world!");
    println!("{mstring}");

    //Are you copying a String? Yes, on the stack!
    let s2: String = s1;
    //println!("{s1}, world!"); //compiling error
    println!("{s2}, world!");

    //Freeing memory on the heap after assigning a new value to an existing variable
    let mut mstring2: String = String::from("hello");
    mstring2 = String::from("world!");
    println!("hello, {mstring2}");

    //Clone heap data
    let cstring: String = s2.clone();
    println!("{s2}, world!");
    println!("{cstring}, world!");
    // Address of the String struct (ptr, len, cap) - typically on the stack
    println!("&s2 (String struct addr):      {:p}", &s2);
    println!("&cstring (String struct addr): {:p}", &cstring);
    // Address of the heap buffer that stores the characters
    println!("s2 heap buffer ptr:            {:p}", s2.as_ptr());
    println!("cstring heap buffer ptr:       {:p}", cstring.as_ptr());

    // Ownership and functions
    takes_ownership(s2);
    let x: u32 = 2;
    simple_copy(x);
    //println!("s2 visible is not visible anymore inthis scope: {s2}!");
    println!("x is visible in main: {x}");
}

fn takes_ownership(s: String) {
    println!("Passing a String to a function --> is a move!");
    println!("s is visible in takes_ownership: {s}!");
}

fn simple_copy(x: u32) {
    println!(
        "Passing a type that implements Copy to a function --> is a simple copy on the Stack!"
    );
    println!("x is visible in simple_copy: {x}");
}
