/******************************************************************************
 *  Compilation:  javac HelloWorld.java
 *  Execution:    java HelloWorld
 ******************************************************************************/

public class HelloWorld {

  public static void main() { // String[] args) {
    System.out.println("Hello, Main");
  }

    public static void world() {
    System.out.println("Hello, World");
  }

  public static void earth() {
    System.out.println("Hello, Earth");
  }

  public static void moon() {
    System.out.println("Hello, Moon");
  }

  public static void somebody( String person ) {
    System.out.print("Hello, ");
    System.out.println(person);
  }

  public static void people( String[] persons ) {
    if (persons.length > 0) {
      for(int i = 0; i < persons.length; i++) {
        System.out.print("Hello, ");
        System.out.println(persons[i]);
      }
    } else {
      System.out.println("Hello, People");
    }
  }

} // end public class HelloWorld {
