package net.sf.clipsrules.jni;

public abstract class NumberValue extends PrimitiveValue 
  {
   /****************/
   /* NumberValue: */
   /****************/
   protected NumberValue(Number value) 
     {
      super(value);
     }

   /*************/
   /* getValue: */
   /*************/
   @Override
   public Number getValue()
     {
      return (Number) super.getValue();
     }
     
   /*************/
   /* intValue: */
   /*************/
   public int intValue()
     {
      return ((Number) super.getValue()).intValue();
     }

   /**************/
   /* longValue: */
   /**************/
   public long longValue()
     {
      return ((Number) super.getValue()).longValue();
     }
     
   /***************/
   /* floatValue: */
   /***************/
   public float floatValue()
     {
      return ((Number) super.getValue()).floatValue();
     }

   /****************/
   /* doubleValue: */
   /****************/
   public double doubleValue()
     {
      return ((Number) super.getValue()).doubleValue();
     }
     

   @Override
   public boolean isNumber()
     { return true; }

  }
