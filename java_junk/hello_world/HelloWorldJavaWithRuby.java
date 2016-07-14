// HelloWorldJavaWithRuby.java
//    javac HelloWorldJavaWithRuby.java
//    java HelloWorldJavaWithRuby

import org.jruby.embed.ScriptingContainer;

public class HelloWorldJavaWithRuby {

    private HelloWorldJavaWithRuby() {
        ScriptingContainer container = new ScriptingContainer();
        container.runScriptlet("puts 'Hello Nibiru; welcome to the neighborhood.'");
    }

    public static void main(String[] args) {
        new HelloWorldJavaWithRuby();
    }
}

/*

import org.jruby.embed.ScriptingContainer;
ScriptingContainer container = new ScriptingContainer();
container.runScriptlet("puts 'Hello Nibiru; welcome to the neighborhood.'");

*/
