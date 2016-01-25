
struct Foo;

impl Foo {
	fn hello(&self) -> &str {
	  "hello"
	}
}



fn main(){
  let f = Foo;
  f.hello();
}