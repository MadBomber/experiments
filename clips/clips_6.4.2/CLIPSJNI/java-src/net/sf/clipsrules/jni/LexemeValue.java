package net.sf.clipsrules.jni;

public abstract class LexemeValue extends PrimitiveValue 
  {
   /****************/
   /* LexemeValue: */
   /****************/
   protected LexemeValue(String value) 
     {
      super(value);
     }

   /*************/
   /* getValue: */
   /*************/
   @Override
   public String getValue()
     {
      return (String) super.getValue();
     }
               
   @Override
   public boolean isLexeme()
     { return true; }
  }
