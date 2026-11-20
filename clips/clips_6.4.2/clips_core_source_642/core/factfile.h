   /*******************************************************/
   /*      "C" Language Integrated Production System      */
   /*                                                     */
   /*             CLIPS Version 6.40  05/05/19            */
   /*                                                     */
   /*                                                     */
   /*******************************************************/

/*************************************************************/
/* Purpose:                                                  */
/*                                                           */
/* Principal Programmer(s):                                  */
/*      Brian L. Dantes                                      */
/*      Gary D. Riley                                        */
/*                                                           */
/* Contributing Programmer(s):                               */
/*                                                           */
/* Revision History:                                         */
/*                                                           */
/*      6.40: New file for save-facts and load-facts.        */
/*                                                           */
/*            Added bsave-facts and bload-facts.             */
/*                                                           */
/*************************************************************/

#ifndef _H_factfile

#pragma once

#define _H_factfile

#include "expressn.h"

#if DEFTEMPLATE_CONSTRUCT

#endif /* DEFTEMPLATE_CONSTRUCT */

   void                           FactFileCommandDefinitions(Environment *);
   void                           SaveFactsCommand(Environment *,UDFContext *,UDFValue *);
   void                           LoadFactsCommand(Environment *,UDFContext *,UDFValue *);
   long                           SaveFacts(Environment *,const char *,SaveScope);
   long                           SaveFactsDriver(Environment *,const char *,SaveScope,struct expr *);
   long                           LoadFacts(Environment *,const char *);
   long                           LoadFactsFromString(Environment *,const char *,size_t);
   void                           BinarySaveFactsCommand(Environment *,UDFContext *,UDFValue *);
   void                           BinaryLoadFactsCommand(Environment *,UDFContext *,UDFValue *);
   long                           BinarySaveFacts(Environment *,const char *,SaveScope);
   long                           BinarySaveFactsDriver(Environment *,const char *,SaveScope,Expression *);
   long                           BinaryLoadFacts(Environment *,const char *);

#endif /* _H_factfile */



