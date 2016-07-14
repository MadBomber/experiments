/******************************************************************************
 *  Compilation:  javac HelloWorld.java
 *  Execution:    Because there is no "main" method you can not execute this class
 *                It must be called from another main.  See for example:
 *                  HelloWorldJava.java   For a Java mainline
 *                  hello_world.rb        For a jRuby mainline
 *                  hello_world.py        For a jython mainline
 ******************************************************************************/


public class HelloWorld {

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
