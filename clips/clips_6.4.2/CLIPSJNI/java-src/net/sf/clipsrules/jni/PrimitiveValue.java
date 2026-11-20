package net.sf.clipsrules.jni;

import java.util.List;

public abstract class PrimitiveValue
  { 
   private Object value;

   /*******************/
   /* PrimitiveValue: */
   /*******************/
   protected PrimitiveValue(Object value)
     {
      this.value = value;
     }

   /*******************/
   /* PrimitiveValue: */
   /*******************/
   protected PrimitiveValue()
     {
      this.value = null;
     }

   /*************/
   /* getValue: */
   /*************/
   public Object getValue()
     {
      return this.value;
     }

   /*************/
   /* toString: */
   /*************/
   @Override
   public String toString()
     {
      if (this.value == null) return null;
      return this.value.toString();
     }
     
   /*************/
   /* hashCode: */
   /*************/
   @Override
   public int hashCode()
     {     
      if (this.value == null) return 0;
      return this.value.hashCode();
     }
     
   /***********/
   /* equals: */
   /***********/
   @Override
   public boolean equals(Object obj) 
     {
      if (this == obj) return true;
      if (obj == null) return false;
      if (this.getClass() != obj.getClass()) return false;
       
      PrimitiveValue pv = (PrimitiveValue) obj;
      if (this.value == null) return (pv.value == null);
      return this.value.equals(pv.value);
     }
   
   public CLIPSType getCLIPSType()
     { return CLIPSType.VOID; }

   public int getCLIPSTypeValue()
     { return getCLIPSType().getType(); }
     
   public boolean isVoid()
     { return false; }
   
   public boolean isLexeme()
     { return false; }
   
   public boolean isSymbol()
     { return false; }
   
   public boolean isString()
     { return false; }
   
   public boolean isInstanceName()
     { return false; }
   
   public boolean isNumber()
     { return false; }
   
   public boolean isFloat()
     { return false; }
   
   public boolean isInteger()
     { return false; }
   
   public boolean isFactAddress()
     { return false; }

   public boolean isInstance()
     { return false; }
         
   public boolean isInstanceAddress()
     { return false; }
   
   public boolean isMultifield()
     { return false; }
         
   public boolean isExternalAddress()
     { return false; }
   
   /************/
   /* retain: */
   /************/
   public void retain()
     {
     }

   /************/
   /* release: */
   /************/
   public void release()
     {
     }
  }
