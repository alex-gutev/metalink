;;;; lexer.lisp
;;;;
;;;; Tridash Programming Language.
;;;; Copyright (C) 2018  Alexander Gutev
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

;;;; Unit tests for lexer

(defpackage :tridash.test.lexer
  (:use :generic-cl
        :alexandria
        :anaphora
        :cl-arrows
        :iterate
        :optima
        :prove

        :tridash.parser

        :tridash.test.util)

  (:shadowing-import-from :generic-cl
                          :emptyp
                          :multiply
                          :accumulate)

  (:shadowing-import-from :prove :fail)

  (:import-from :tridash.parser

                :*line-term*
                :make-lexer
                :next-token))

(in-package :tridash.test.lexer)

(cl-interpol:enable-interpol-syntax)

(plan nil)

(defun is-tokens (string tokens)
  (with-input-from-string (in string)
    (diag (format nil "Test String: ~s" string))
    (loop
       with lexer = (make-lexer in)
       for (type tok) = (multiple-value-list (next-token lexer))
       for expected in tokens
       do (is (list type tok) expected)
       finally (ok (null type)))))

(defun is-lexer-error (string)
  (with-input-from-string (in string)
    (diag (format nil "Test String: ~s" string))
    (is-error
     (loop
        with lexer = (make-lexer in)
        while (next-token lexer))
     'error)))


(subtest "Simple Identifiers"
  (is-tokens
   #?"node-1s    +\t2node - \t third-node"
   '((:id "node-1s")
     (:id "+")
     (:id "2node")
     (:id "-")
     (:id "third-node")))

  (is-tokens
   #?"node-1s    +\t2node - \f third-node"
   '((:id "node-1s")
     (:id "+")
     (:id "2node")
     (:id "-")
     (:id "third-node"))))

(subtest "Terminate Tokens"
  (let ((*line-term* t))
    (is-tokens
     #?"node1 node2\nnode3;node4"
     '((:id "node1")
       (:id "node2")
       (:terminate #?"\n")
       (:id "node3")
       (:terminate ";")
       (:id "node4"))))

  (let ((*line-term* nil))
    (is-tokens
     #?"node1 node2\nnode3;node4"
     '((:id "node1")
       (:id "node2")
       (:id "node3")
       (:terminate ";")
       (:id "node4")))))

(subtest "Comments"
  (is-tokens "# This is a comment" nil)
  (is-tokens "  #This is a comment" nil)
  (is-tokens "## Another comment" nil)
  (is-tokens "node #followed by a comment" '((:id "node")))

  (let ((*line-term* t))
    (is-tokens
     #?"node-a # A comment\nnode-b"
     '((:id "node-a")
       (:terminate #?"\n")
       (:id "node-b"))))

  (let ((*line-term* nil))
    (is-tokens
     #?"node-a # A comment\nnode-b"
     '((:id "node-a")
       (:id "node-b")))))

(subtest "Special Characters"
  (subtest "Test Comma"
    (is-tokens
     ",a, b, c ,"
     '((:comma ",")
       (:id "a")
       (:comma ",")
       (:id "b")
       (:comma ",")
       (:id "c")
       (:comma ","))))

  (subtest "Test Parenthesis"
    (is-tokens
     "fn(a,b,((c,d)),e)"
     '((:id "fn")
       (:open-paren "(")
       (:id "a")
       (:comma ",")
       (:id "b")
       (:comma ",")
       (:open-paren "(")
       (:open-paren "(")
       (:id "c")
       (:comma ",")
       (:id "d")
       (:close-paren ")")
       (:close-paren ")")
       (:comma ",")
       (:id "e")
       (:close-paren ")"))))

  (subtest "Test Braces"
    (is-tokens
     "def{a, b({c}),}x"
     '((:id "def")
       (:open-brace "{")
       (:id "a")
       (:comma ",")
       (:id "b")
       (:open-paren "(")
       (:open-brace "{")
       (:id "c")
       (:close-brace "}")
       (:close-paren ")")
       (:comma ",")
       (:close-brace "}")
       (:id "x")))))

(subtest "Numbers"
  (is-tokens
   "{-123 + ,34.01, - (-12.8) - 7}"
   '((:open-brace "{")
     (:integer "-123")
     (:id "+")
     (:comma ",")
     (:real "34.01")
     (:comma ",")
     (:id "-")
     (:open-paren "(")
     (:real "-12.8")
     (:close-paren ")")
     (:id "-")
     (:integer "7")
     (:close-brace "}")))

  (is-tokens
   "{-123.3 + ,34, - (-12) - 7.3}"
   '((:open-brace "{")
     (:real "-123.3")
     (:id "+")
     (:comma ",")
     (:integer "34")
     (:comma ",")
     (:id "-")
     (:open-paren "(")
     (:integer "-12")
     (:close-paren ")")
     (:id "-")
     (:real "7.3")
     (:close-brace "}")))

  (is-tokens "100.98" '((:real "100.98")))

  (is-tokens
   "12d34 12d-34 0f12 0f-12 5e78 5e-78 99l01 99l-01 99l+2"
   '((:real "12d34")
     (:real "12d-34")
     (:real "0f12")
     (:real "0f-12")
     (:real "5e78")
     (:real "5e-78")
     (:real "99l01")
     (:real "99l-01")
     (:real "99l+2")))

  (is-tokens
   "1.2d34 1.2d-34 0.5e78 0.5e-78 5.6e78 5.6e-78 0.1f2 0.1f-2 9.9l01 9.9l-01 0.9l1 0.9l+1"
   '((:real "1.2d34")
     (:real "1.2d-34")
     (:real "0.5e78")
     (:real "0.5e-78")
     (:real "5.6e78")
     (:real "5.6e-78")
     (:real "0.1f2")
     (:real "0.1f-2")
     (:real "9.9l01")
     (:real "9.9l-01")
     (:real "0.9l1")
     (:real "0.9l+1")))

  (is-tokens
   "12dd34 12d34d 5e7e8 56e7e8 99l0d1 9l1l 7x8"
   '((:id "12dd34")
     (:id "12d34d")
     (:id "5e7e8")
     (:id "56e7e8")
     (:id "99l0d1")
     (:id "9l1l")
     (:id "7x8")))

  (is-lexer-error "1.2e100.3")
  (is-lexer-error "1.2+3.4")
  (is-lexer-error "1.2.3")
  (is-lexer-error "2.4e10+5"))

(subtest "Strings"
  (is-tokens " \"Hello World\" " '((:string "\"Hello World\"")))
  (is-tokens "\"Bob said \\\"Hello\\\" to Mary \"" '((:string "\"Bob said \\\"Hello\\\" to Mary \"")))
  (is-tokens "\"A \\\\\\\" regex\\\\\"" '((:string "\"A \\\\\\\" regex\\\\\"")))

  (is-tokens
   "node1\"Hello\"node2"
   '((:id "node1")
     (:string "\"Hello\"")
     (:id "node2")))

  (is-tokens
   "1\"str\"2 "
   '((:integer "1")
     (:string "\"str\"")
     (:integer "2")))

  (is-tokens
   "1.01\"str\"2.33 "
   '((:real "1.01")
     (:string "\"str\"")
     (:real "2.33")))

  (is-lexer-error "\"hello "))

(subtest "Dot Characters"
  (is-tokens
   "object.field"
   '((:id "object")
     (:id ".")
     (:id "field")))

  (is-tokens
   "object..field"
   '((:id "object")
     (:id "..")
     (:id "field")))

  (is-tokens
   ".object"
   '((:id ".")
     (:id "object")))

  (is-tokens
   "object.  "
   '((:id "object")
     (:id "."))))


(finalize)

(cl-interpol:disable-interpol-syntax)
