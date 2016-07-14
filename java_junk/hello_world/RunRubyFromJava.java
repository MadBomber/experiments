// RunRubyFromJava.java

import org.jruby.embed.ScriptingContainer;
ScriptingContainer container = new ScriptingContainer();
container.runScriptlet("puts 'Hello Nibiru; welcome to the neighborhood.'");
