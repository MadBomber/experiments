package net.sf.clipsrules.jni;

public class InstanceAddressValue extends PrimitiveValue
  {
   private Environment owner;
   
   /*************************/
   /* InstanceAddressValue: */
   /*************************/
   public InstanceAddressValue(
     long value,
     Environment env)
     {
      super(value);     
      owner = env;
     }

   /*************/
   /* getValue: */
   /*************/
   @Override
   public Long getValue()
     {
      return (Long) super.getValue();
     }

   @Override
   public CLIPSType getCLIPSType()
     { return CLIPSType.INSTANCE_ADDRESS; }

   /*******************/
   /* getEnvironment: */
   /*******************/
   public Environment getEnvironment()
     { return owner; }
     
   /***********************/
   /* getInstanceAddress: */
   /***********************/     
   public long getInstanceAddress()
     { return getValue().longValue(); }

   /*****************/
   /* getSlotValue: */
   /*****************/     
   public PrimitiveValue getSlotValue(
     String slotName)
     { return Environment.directGetSlot(this,slotName); }

   /********************/
   /* getInstanceName: */
   /********************/     
   public String getInstanceName()
     { return Environment.getInstanceName(this); }
     
   /*************/
   /* toString: */
   /*************/
   @Override
   public String toString()
     {        
      return "<Instance-" + getInstanceName() + ">";
     }

   /***********/
   /* retain: */
   /***********/
   @Override
   public void retain()
     {
      owner.retainInstance(this);
     }

   /************/
   /* release: */
   /************/
   @Override
   public void release()
     {
      owner.releaseInstance(this);
     }
   
   @Override
   public boolean isInstanceAddress()
     { return true; }

  }
