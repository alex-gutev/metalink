;;;; tridash.asd
;;;;
;;;; Tridash Programming Language.
;;;; Copyright (C) 2018-2019  Alexander Gutev
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

(asdf:defsystem #:tridash
  :description "Tridash Programming Language"
  :author "Alexander Gutev"
  :license "GPL v3"
  :components ((:module
                "plump"

                :components
                ((:file "package")
                 (:file "entities")
                 (:file "lexer")
                 (:file "tag-dispatcher")
                 (:file "dom")
                 (:file "parser")
                 (:file "processing")
                 (:file "special-tags")))

               (:module
                "src"

                :components
                ((:module "util"
                          :serial t
                          :components ((:file "package")
                                       (:file "cut")
                                       (:file "macros")))
                 (:file "package")
                 (:file "interface")
                 (:file "lexer")
                 (:file "parser")
                 (:file "operators")
                 (:file "expressions")
                 (:file "builder-interface")
                 (:file "node")
                 (:file "meta-node")
                 (:file "module")
                 (:file "module-table")
                 (:file "conditions")
                 (:file "outer-nodes")
                 (:file "strictness")
                 (:file "builder")
                 (:file "macros")
                 (:file "macro-runtime")
                 (:file "coalescer")
                 (:file "prog-builder")
                 (:file "main")

                 (:module "builders/html"
                          :serial t
                          :components ((:file "package")
                                       (:file "builder")
                                       (:file "script-parser")))

                 (:module "backends/javascript"
                          :serial t
                          :components ((:file "package")
                                       (:file "ast")
                                       (:file "print")
                                       (:file "symbols")
                                       (:file "backend")
                                       (:file "functions")
                                       (:file "html")))

                 (:module "backends/wasm"
                          :serial t
                          :components ((:file "package")
                                       (:file "expressions")
                                       (:file "builtin")
                                       (:file "backend")
                                       (:file "html"))))))

  :depends-on (:anaphora
               :iterate
               :alexandria
               :cl-arrows
               :split-sequence
               :named-readtables
               :let-over-lambda
               :optima
               :optima.ppcre
               :cl-ppcre
               :ppath
               :parse-number
	       :cl-yaclyaml
               :cl-fad
               :unix-opts
               :trivial-gray-streams
               :flexi-streams
               :babel

               :generic-cl
               :generic-cl.util
               :wasm-encoder

               ;; Plump dependencies
               :array-utils)

  :in-order-to ((asdf:test-op (asdf:test-op :tridash/test)))

  :build-operation "program-op"
  :build-pathname "tridashc"
  :entry-point "TRIDASH::MAIN")

(asdf:defsystem #:tridash/test
  :description "Units tests for the Tridash."
  :author "Alexander Gutev"
  :license "GPL v3"
  :depends-on (:tridash
               :prove
               :prove-asdf

               :cl-interpol)
  :defsystem-depends-on (:prove-asdf)
  :components ((:module
                "test"

                :components
                ((:file "util")
                 (:test-file "lexer")
                 (:test-file "parser")
                 (:test-file "builder")
                 (:test-file "strictness")
                 (:test-file "macros")

                 (:module
                  "builders/html"

                  :components
                  ((:test-file "builder")))

                 (:module
                  "backends/javascript"

                  :components
                  ((:test-file "backend")))

                 (:module
                  "backends/wasm"

                  :components
                  ((:test-file "backend"))))))

  :perform (asdf:test-op :after (op c)
                         (let ((*print-circle* t))
                           (funcall (intern #.(string :run) :prove) c :reporter :fiveam))))
