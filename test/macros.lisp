;;;; macros.lisp
;;;;
;;;; Tridash Programming Language.
;;;; Copyright (C) 2019  Alexander Gutev
;;;;
;;;; This program is free software: you can redistribute it and/or modify
;;;; it under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; (at your option) any later version.
;;;;
;;;; This program is distributed in the hope that it will be useful,
;;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;;; GNU General Public License for more details.
;;;;
;;;; You should have received a copy of the GNU General Public License
;;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;;; User-Defined Macro Tests

(defpackage :tridash.test.macros
  (:use :generic-cl
        :alexandria
        :anaphora
        :cl-arrows
        :iterate
        :optima
        :prove
        :named-readtables

        :tridash.parser
        :tridash.frontend

        :tridash.test.util
        :tridash.test.builder)

  (:shadowing-import-from :generic-cl
                          :emptyp
                          :multiply
                          :accumulate)

  (:shadowing-import-from :prove :fail)

  (:import-from :lol
                :defmacro!
                :lol-syntax)

  (:import-from :tridash.frontend
                :tridash->cl-function
                :+fail-catch-tag+
                :call-tridash-meta-node))

(in-package :tridash.test.macros)

(in-readtable lol-syntax)

(defun functor (operator &rest arguments)
  "Creates a `FUNCTOR-EXPRESSION' with operator OPERATOR and arguments
   ARGUMENTS."

  (functor-expression operator arguments))

(defun expression= (got expected)
  "Checks that the CL expression GOT is equal to EXPECTED. Symbols in
   EXPECTED, beginning with $, are replaced with the symbol in GOT
   corresponding to the first occurrence."

  (let ((aliases (make-hash-map)))
    (flet ((equal? (got expected)
             (match* (got expected)
               (((type symbol) (type symbol))
                (= got
                   (if (starts-with #\$ (symbol-name expected))
                       (ensure-get expected aliases got)
                       expected)))

               ((_ _)
                (= got expected)))))

      (tree-equal got expected :test #'equal?))))

(defmacro with-external-meta-nodes ((&rest names) &body body)
  "Creates `EXTERNAL-META-NODE's with names NAMES and binds to
   variables with the same identifiers as the names upcased."

  `(let ,(map #`(,(intern (string-upcase a1)) (make-instance 'external-meta-node :name (id-symbol ,a1))) names)
     ,@body))

(defmacro mock-meta-node ((&rest operands) expression)
  "Creates a `META-NODE' which takes operands OPERANDS and has a value
   function consisting of EXPRESSION. OPERANDS is a list of symbols
   naming the dependency nodes. EXPRESSION is evaluated in an
   environment where each symbol in OPERANDS is bound to the
   `NODE-LINK' object corresponding to the operand, and the symbol
   SELF is bound to the `META-NODE' object."

  `(let ((self (make-instance 'meta-node :name 'test-meta-node :operands ',operands))
         ,@(map #`(,a1 (node-link (make-instance 'node :name ',a1))) operands))

     (setf (value-function (context self nil))
           ,expression)

     self))

(defmacro test-compile-meta-node ((&rest operands) expression args body)
  "Creates and compiles a `META-NODE' to a CL LAMBDA expression and
   checks that it has arguments ARGS and body BODY, by EXPRESSION=.

   OPERANDS and EXPRESSION correspond to the OPERANDS and EXPRESSION
   arguments of MOCK-META-NODE.

   ARGS (not evaluated) is the expected lambda-list of the function.

   BODY is the expected body expression within the BLOCK, TAGBODY,
   RETURN expression. The symbol $recur, occurring in BODY is
   substituted with the TAGBODY tag for tail-recursive self
   calls. BODY is evaluated in an environment in which the symbol SELF
   is bound to the `META-NODE' object."

  `(let ((self (mock-meta-node ,operands ,expression)))
     (is (tridash->cl-function self)
         `(lambda ,',args
            (block nil
              (tagbody $recur
                 (return ,,body))))
         :test #'expression=)))


(plan 3)

(subtest "Tridash to CL Compilation"
  (subtest "Functor Expressions"
    (with-external-meta-nodes ("if" "<" "-")
      (test-compile-meta-node

       (a b)
       (functor if (functor < a b) (functor - b a) (functor - a b))

       ($a $b)
       '(if (< $a $b) (- $b $a) (- $a $b)))))

  (subtest "If Expressions"
    (with-external-meta-nodes ("<" "-")
      (test-compile-meta-node

       (a b)
       (if-expression (functor < a b) (functor - b a) (functor - a b))

       ($a $b)
       '(if (< $a $b) (- $b $a) (- $a $b)))))

  (subtest "Object Expressions"
    (with-external-meta-nodes ("+" "-")
      (test-compile-meta-node

       (x y)
       (object-expression
        `((sum ,(functor + x y))
          (diff ,(functor - x y))))

       ($x $y)
       '(alist-hash-map
         (list
          (cons 'sum (+ $x $y))
          (cons 'diff (- $x $y)))))))

  (subtest "Member Expressions"
    (test-compile-meta-node

     (object)
     (member-expression
      (member-expression object 'key1) 'key2)

     ($obj)
     '(get 'key2 (get 'key1 $obj))))

  (subtest "Catch Expressions"
    (with-external-meta-nodes ("/" "*")
      (test-compile-meta-node

       (a b)
       (catch-expression
        (functor / a b)
        (functor * a b))

       ($a $b)
       `(let (($result (catch ',+fail-catch-tag+ (/ $a $b))))
          (if (eq $result ',+fail-catch-tag+)
              (* $a $b)
              $result)))))

  (subtest "Fail Expressions"
    (test-compile-meta-node
     ()
     (fail-expression)

     ()
     `(throw ',+fail-catch-tag+ ',+fail-catch-tag+)))

  (subtest "Expression Groups"
    (with-external-meta-nodes ("+")
      (test-compile-meta-node

       (a)
       (expression-group
        (functor + a 1))

       ($a)
       `(+ $a 1))))

  (subtest "Calling Other Meta-Nodes"
    (with-external-meta-nodes ("-")
      (let ((meta-node (make-instance 'meta-node :name 'test)))
        (test-compile-meta-node

         (a)
         (functor meta-node (functor - a))

         ($a)
         `(call-tridash-meta-node ,meta-node (list (- $a)))))))

  (subtest "Literals"
    (with-external-meta-nodes ("and")
      (test-compile-meta-node

       ()
       (functor and "hello" 1 2.3 'symbol)

       ()
       '(and "hello" 1 2.3 'symbol))))

  (subtest "Primitive Functions"
    (with-external-meta-nodes
        ("+" "-" "*" "/"
             "<" "<=" ">" ">=" "=" "!="
             "and" "or" "not"
             "int?" "real?" "string?")

      (subtest "Arithmetic"
        (test-compile-meta-node

         (a b c d)
         (functor
          /
          (functor * (functor + a b) (functor - c d))
          (functor - d))

         ($a $b $c $d)
         '(/
           (* (+ $a $b) (- $c $d))
           (- $d))))

      (subtest "Comparison and Logical"
        (test-compile-meta-node

         (x y)
         (functor
          not

          (functor
           or

           (functor and (functor < x y) (functor = y x))
           (functor <= x 10)
           (functor > 1 y)
           (functor >= 8 y)
           (functor != x y)))

         ($x $y)
         '(not
           (or
            (and (< $x $y) (= $y $x))
            (<= $x 10)
            (> 1 $y)
            (>= 8 $y)
            (/= $x $y)))))

      (subtest "Type Checks"
        (test-compile-meta-node

         (x y z)
         (functor
          or

          (functor int? x)
          (functor real? y)
          (functor string? z))

         ($x $y $z)
         '(or
           (integerp $x)
           (floatp $y)
           (stringp $z))))))

  (subtest "Tail Recursion"
    (subtest "If Expressions"
      (with-external-meta-nodes ("-" "*" "<")
        (test-compile-meta-node

         (n acc)
         (if-expression (functor < n 2)
                        acc
                        (functor self (functor - n 1) (functor * n acc)))

         ($n $acc)
         '(if (< $n 2)
           $acc
           (progn
             (psetf $n (- $n 1)
                    $acc (* $n $acc))
             (go $recur))))))

    (subtest "If Functor"
      (with-external-meta-nodes ("if" "-" "*" "<")
        (test-compile-meta-node

         (n acc)
         (functor if
                  (functor < n 2)
                  acc
                  (functor self (functor - n 1) (functor * n acc)))

         ($n $acc)
         '(if (< $n 2)
           $acc
           (progn
             (psetf $n (- $n 1)
                    $acc (* $n $acc))
             (go $recur))))))

    (subtest "Expression Groups"
      (with-external-meta-nodes ("if" "-" "*" "<")
        (test-compile-meta-node

         (n acc)
         (functor if
                  (functor < n 2)
                  acc
                  (expression-group
                   (functor self (functor - n 1) (functor * n acc))))

         ($n $acc)
         '(if (< $n 2)
           $acc
           (progn
             (psetf $n (- $n 1)
                    $acc (* $n $acc))
             (go $recur))))))

    (subtest "And/Or Functors"
      (with-external-meta-nodes ("and" "or" "=" "-")
        (subtest "Or"
          (test-compile-meta-node

           (n)
           (functor or (functor = n 0) (functor self (functor - n 1)))

           ($n)
           '(or (= $n 0)
             (progn
               (psetf $n (- $n 1))
               (go $recur)))))

        (subtest "And"
          (test-compile-meta-node

           (n)
           (functor and (functor = n 0) (functor self (functor - n 1)))

           ($n)
           '(and (= $n 0)
             (progn
               (psetf $n (- $n 1))
               (go $recur)))))))

    (subtest "Catch Expressions"
      (with-external-meta-nodes ("-" "+")
        (test-compile-meta-node

         (n)
         (catch-expression (functor self (functor + n 1))
                           (functor self (functor - n 1)))

         ($n)
         `(let (($result (catch '$fail (call-tridash-meta-node ,self (list (+ $n 1))))))
            (if (eq $result '$fail)
                (progn
                  (psetf $n (- $n 1))
                  (go $recur))
                $result)))))

    (subtest "Non-Tail Calls"
      (subtest "Function Arguments"
        (with-external-meta-nodes ("+" "*")
          (test-compile-meta-node

           (n)
           (functor +
                    (functor self (functor * n 2))
                    (functor self (functor * n 3)))

           ($n)
           `(+ (call-tridash-meta-node ,self (list (* $n 2)))
               (call-tridash-meta-node ,self (list (* $n 3)))))))

      (subtest "If-Expression Condition"
        (test-compile-meta-node

         (n)
         (if-expression (functor self n) 1 2)

         ($n)
         `(if (call-tridash-meta-node ,self (list $n)) 1 2)))

      (subtest "If Functor Condition"
        (with-external-meta-nodes ("if")
          (test-compile-meta-node

           (n)
           (functor if (functor self n) 1 2)

           ($n)
           `(if (call-tridash-meta-node ,self (list $n)) 1 2))))

      (subtest "And Functor Argument"
        (with-external-meta-nodes ("and")
          (test-compile-meta-node

           (n)
           (functor and (functor self n) 1)

           ($n)
           `(and (call-tridash-meta-node ,self (list $n)) 1))))

      (subtest "Or Functor Argument"
        (with-external-meta-nodes ("or")
          (test-compile-meta-node

           (n)
           (functor or (functor self n) 1)

           ($n)
           `(or (call-tridash-meta-node ,self (list $n)) 1))))

      (subtest "Object Expression"
        (test-compile-meta-node

         (n)
         (object-expression (list (list 'a (functor self n))))

         ($n)
         `(alist-hash-map
           (list (cons 'a (call-tridash-meta-node ,self (list $n)))))))

      (subtest "Member Expression"
        (test-compile-meta-node

         (object)
         (member-expression (functor self object) 'x)

         ($obj)
         `(get 'x (call-tridash-meta-node ,self (list $obj)))))))

  (subtest "Errors"
    (with-external-meta-nodes ("not-a-function")
      (is-error
       (tridash->cl-function
        (mock-meta-node
         (arg)
         (functor not-a-function arg)))

       'error))))

(subtest "Calling Tridash Meta-Nodes from CL"
  (subtest "Single Expression Functions"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"
             "min(x,y) : case(x < y : x, y)")

      (with-nodes ((min "min")) modules
        (is (call-tridash-meta-node min '(2 10)) 2)
        (is (call-tridash-meta-node min '(10 2)) 2)
        (is (call-tridash-meta-node min '(-5.3 7.6)) -5.3)
        (is (call-tridash-meta-node min '(1 1)) 1))))

  (subtest "Multiple Nodes with CATCH-FAIL Expressions"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"
             "min(x,y) : { x < y -> (x -> :context(self,c)); y -> :context(self,c) }")

      (with-nodes ((min "min")) modules
        (is (call-tridash-meta-node min '(2 10)) 2)
        (is (call-tridash-meta-node min '(10 2)) 2)
        (is (call-tridash-meta-node min '(-5.3 7.6)) -5.3)
        (is (call-tridash-meta-node min '(1 1)) 1))))

  (subtest "Recursive Meta-Nodes"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"
             "fact(n) : { case(n < 2 : 1, n * fact(n - 1)) }")

      (with-nodes ((fact "fact")) modules
        (is (call-tridash-meta-node fact '(3)) 6)
        (is (call-tridash-meta-node fact '(5)) 120)
        (is (call-tridash-meta-node fact '(0)) 1))))

  (subtest "Tail-Recursive Meta-Nodes"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"
             "fact(n) : { iter(n,acc) : case(n < 2 : acc, iter(n - 1, n * acc)); iter(n, 1) }")

      (with-nodes ((fact "fact")) modules
        (is (call-tridash-meta-node fact '(3)) 6)
        (is (call-tridash-meta-node fact '(5)) 120)
        (is (call-tridash-meta-node fact '(0)) 1)))
    ())

  (subtest "Calling Other Meta-Nodes"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"
             "1-(n) : n - 1"
             "1+(n) : n + 1"
             "f(a, b) : 1-(a) * 1+(b)")

      (with-nodes ((f "f")) modules
        (is (call-tridash-meta-node f '(1 5)) 0)
        (is (call-tridash-meta-node f '(10 4)) 45)
        (is (call-tridash-meta-node f '(4 10)) 33)))))

(subtest "Actual Macros"
  (subtest "Compile-Time Computations"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"

             "square(x) : x * x"
             ":attribute(square, macro, 1)"

             "a * square(3) -> b")

      (test-not-nodes modules
                      '((":in" "core" "*") "a" ("square" 3))
                      '("square" 3))

      (with-nodes ((a "a") (a*9 ((":in" "core" "*") "a" 9))
                   (b "b")
                   (* "*"))
          modules

        (has-value-function (a) a*9 `(,* ,a 9))
        (test-simple-binding a*9 b))))

  (subtest "Generating Expressions"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"

             "square(x) : list(:quote(*), x, x)"
             ":attribute(square, macro, 1)"

             "square(a) -> b")

      (test-not-nodes modules '("square" "a"))

      (with-nodes ((a "a") (b "b")
                   (a*a ((":in" "core" "*") "a" "a"))
                   (* "*"))
          modules

        (has-value-function (a) a*a `(,* ,a ,a))
        (test-simple-binding a*a b))))

  (subtest "Macros in Macros"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"

             "'(x) : list(:quote(:quote), x)"
             ":attribute(', macro, 1)"

             "square(x) : list('(*), x, x)"
             ":attribute(square, macro, 1)"

             "square(a) -> b")

      (test-not-nodes modules '("square" "a"))

      (with-nodes ((a "a") (b "b")
                   (a*a ((":in" "core" "*") "a" "a"))
                   (* "*"))
          modules

        (has-value-function (a) a*a `(,* ,a ,a))
        (test-simple-binding a*a b))))

  (subtest "Macros with Multiple Arguments"
    (with-module-table modules
      (build-source-file #p"./modules/core.trd" modules)
      (build ":import(core)"

             "'(x) : list(:quote(:quote), x)"
             ":attribute(', macro, 1)"

             "!-(a, b) : list('(if), a, b)"
             ":attribute(!-, macro, 1)"
             ":op(!-, 25, left)"

             "a !- b -> out")

      (test-not-nodes '("!-" "a" "b"))

      (with-nodes ((a "a") (b "b") (out "out")
                   (a!-b ((":in" "core" "if") "a" "b"))
                   (if "if"))
          modules

        (has-value-function (a b) a!-b `(,if ,a ,b))
        (test-simple-binding a!-b out)))))

(finalize)
