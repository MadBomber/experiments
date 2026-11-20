(clear)                   ; Optimized Rete Evaluator Issue

(defrule rule-1
   (factoid ?x ?y&:(and ?x ?y)) ; FactPNGetVar3
   =>)

(defrule rule-2
   (factoid ?x ?y)
   (test (and ?x ?y)) ; FactJNGetVar3
   =>)

(defrule rule-3
   (factoid $? ?x ?y&:(and ?x ?y) $?) ; FactPNGetVar1
   =>)

(defrule rule-4
   (factoid $? ?x ?y $?)
   (test (and ?x ?y)) ; FactJNGetVar1
   =>)
(defglobal ?*z* = FALSE)

(defrule rule-5
   (factoid ? ?)
   (test (and ?*z* ?*z*))
   =>)
(assert (factoid FALSE FALSE))
(agenda)
(assert (factoid "FALSE" "FALSE"))
(agenda)
(clear)

(deftemplate factoid
   (slot s1)
   (slot s2))

(defrule rule-1
   (factoid (s1 ?x) (s2 ?y&:(and ?x ?y))) ; FactPNGetVar2
   =>)

(defrule rule-2
   (factoid (s1 ?x) (s2 ?y))
   (test (and ?x ?y)) ; FactJNGetVar2
   =>)
(assert (factoid (s1 FALSE) (s2 FALSE)))
(agenda)
(assert (factoid (s1 "FALSE") (s2 "FALSE")))
(agenda)
(clear)

(defclass OBJOID1
   (is-a USER)
   (slot s1)
   (slot s2))

(defclass OBJOID2
   (is-a USER)
   (multislot ms1))

(defrule rule-1
   (object 
      (is-a OBJOID1)
      (s1 ?x)
      (s2 ?y&:(and ?x ?y))) ; ObjectGetVarPNFunction1
   =>)

(defrule rule-2
   (object 
      (is-a OBJOID1)
      (s1 ?x)
      (s2 ?y))
   (test (and ?x ?y)) ; ObjectGetVarJNFunction1
   =>)

(defrule rule-3
   (object 
      (is-a OBJOID2)
      (ms1 $? ?x ?y&:(and ?x ?y))) ; ObjectGetVarPNFunction2
   =>)
   
(defrule rule-4
   (object 
      (is-a OBJOID2)
      (ms1 $? ?x ?y))
   (test (and ?x ?y)) ; ObjectGetVarJNFunction2
   =>)
(make-instance o1 of OBJOID1 (s1 FALSE) (s2 FALSE))
(make-instance o2 of OBJOID2 (ms1 FALSE FALSE))
(agenda)
(make-instance o3 of OBJOID1 (s1 "FALSE") (s2 "FALSE"))
(make-instance o4 of OBJOID2 (ms1 "FALSE" "FALSE"))
(agenda)
(clear) ; load-facts GC issue

(defglobal MAIN ?*key-id* = 0
                ?*reasmb-id* = 1)

(deffunction key-id ()
   (bind ?*key-id* (+ ?*key-id* 1))
   (bind ?*reasmb-id* 1)
   (return ?*key-id*))
   
(deftemplate key 
   (slot weight (default 1))
   (slot id (default-dynamic (key-id))))
         
(deffunction reasmb-id ()
   (bind ?rv (create$ ?*key-id* 
                      ?*reasmb-id*))
   (bind ?*reasmb-id* (+ ?*reasmb-id* 1))
   (return ?rv))

(deftemplate reasmb
   (multislot id (default-dynamic (reasmb-id))))
(load-facts buglfgc.fct)
(facts)
(clear) ; Calling redefined method body causes crash
(defmethod foo ())
(foo)
(defmethod foo () (bind ?a 1))
(foo)
(clear) ; Composite default-dynamic crash

(defclass FOO
   (is-a USER)
   (slot x (type SYMBOL) 
           (default-dynamic (sym-cat foo bar))))
           
(defclass BAR (is-a USER)
  (slot x (type SYMBOL)))

(defclass WOZ
  (is-a FOO BAR)
  (slot x (type SYMBOL)
          (source composite)))
(make-instance w of WOZ)
(send [w] print)
(clear) ; 6.42 bug
(defglobal ?*foo*  = (create$  0.0)) 

(loop-for-count 1 do
   (bind ?*foo* ?*foo*))
?*foo*
(clear)   
(defglobal ?*x* = (create$ 1 2 3))

(while TRUE do
   (bind ?*x* (rest$ ?*x*))
   (printout t ?*x* crlf)
   (if (= (length$ ?*x*) 0) 
      then (break)))
?*x*
(clear)
(defglobal ?*foo* = (create$ 0.0))

(deffunction test (?foo)
   (bind ?*foo* ?foo)
   (println ?foo)
   (bind ?*foo* (create$ 3.0))
   (println ?foo))
(test ?*foo*)
?*foo*
(clear) ; Modify/duplicate ordered fact
(assert (blah))
(modify 1 (x 3))
(duplicate 1 (y 4))
(clear) ; Missing space in error message

(deftemplate branch
   (slot to))

(deffacts story-flow
   (branch (to obey-the-order Q9)))
   
(defrule error
   =>
   (assert (branch (to obey-the-order Q9))))
(clear) ; Erroneous constraint conflict

(defrule issue
   =>
   (bind ?values "A" "B" "C" "D" "E" "F")
   (bind ?value (nth$ 1 ?values)))
(clear) ; Erroneous constraint conflict

(defrule should-be-undefined-variable-error
   =>
   (println (implode$ ?statement)))
(clear) ; ppdefmodule bug with logical name nil
(ppdefmodule bogus nil)
(clear) ; Crash when generic function call overrides message-handler only functions
(defmethod ppinstance ((?x STRING)))
(defclass FOO (is-a USER))

(defmessage-handler FOO doit()
  (ppinstance))
(make-instance [a] of FOO)
(send [a] doit)
(clear) ; member$ bug

(defrule t1
   (list a ? ? $?nr)
   =>
   (println "t1: " (member$ d ?nr)))
   
(defrule t2
   (list $?nr)
   =>
   (println "t2: " (member$ (create$ b c) ?nr)))
(assert (list a b c d))
(run)
(clear) ; Watch methods
(defmethod myecho ((?x INTEGER)))
(watch methods myecho 1)
(myecho 3)
(unwatch methods myecho 1)
(myecho 3)
(clear) ; Memory leak
(defclass Derived (is-a USER) (pattern-match non-reactive) (slot text))
(make-instance [derived] of Derived)
(defrule test =>)
(make-instance [derived] of Derived)
(clear) ; gensym* bug with make-instance
(setgen 1)
(watch instances)
(defclass POINT (is-a USER) (slot x) (slot y))
(make-instance gen2 of POINT (x 1) (y 2))
(make-instance of POINT)
(make-instance of POINT)
(unwatch instances)
(clear) ; Invalid first character for a variable
(defrule foo (bar ?+) =>)
(defrule foo => (assert (bar ?+)))
(defrule foo (bar $?+) =>)
(defrule foo => (assert (bar $?+)))
(clear)
