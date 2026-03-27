fn main() {
    //not mutable reference
    let s1 = String::from("hello"); //crea: sullo stack la struct String { ptr, len, cap }, sullo heap un buffer con i byte di hello
    //The reference is in this case to the pointer saved on the stack.
    let len: usize = calculate_length(&s1);
    println!("The length of {s1} is {len}");

    //mutable
    let mut s2 = String::from("hello");
    change(&mut s2);
    println!("{s2}");

    //More borrowings are dangerous
    let _r0: &String = &s2;
    let _r1: &mut String = &mut s2;
    let _r2: &mut String = &mut s2;
}

fn calculate_length(ref_: &String) -> usize {
    //usize as output type of length
    (*ref_).len() //Deferenziazione automatica
} //the reference is dropped at the end of this scope but not the String s1.

fn change(mref: &mut String) {
    (*mref).push_str(", world!");
}
