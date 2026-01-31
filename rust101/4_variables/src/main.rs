const CONSTANT: u32 = 60 * 60 * 3;

fn main() {
    let mut x = CONSTANT;
    println!("The value of x is {x}");

    // mutable variable
    x = 6; // only value and not type can change
    println!("The value of x is: {x}");

    // Shadowing
    let x: char = 'a'; // even the type can change
    println!("The value of x is: {x}");

    // Shadowing and inner scope

    {
        let x: String = String::from("Scorreggina"); // even the type can change
        println!("The value of x is: {x}");
    }

    println!("The value of x is: {x}");
}
