fn main() {
    println!("Hello, world!");

    another_function();

    let x: u32 = 15;
    let deg: char = '°';
    print_number(x);

    temperature_string(x, deg);

    println!("{}", fifteen(x));
}

fn another_function() {
    println!("This is a new function!");
}

fn print_number(x: u32) {
    println!("The input number is: {x}");
}

fn temperature_string(x: u32, deg: char) {
    println!("The temperature is {x}{deg}");
}

fn fifteen(x: u32) -> u32 {
    x
}
