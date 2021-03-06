;;;; package.lisp
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

(defpackage :tridash.backend.wasm
  (:use :generic-cl
        :alexandria
        :anaphora
        :named-readtables
        :optima
        :optima.ppcre
        :iterate
        :cl-ppcre
        :cl-arrows

        :babel
        :babel-encodings
        :wasm-encoder

        :tridash.util
        :tridash.parser
        :tridash.interface
        :tridash.frontend
        :tridash.frontend.strictness
        :tridash.builder.html

        :tridash.backend.js.ast)

  (:import-from :tridash.frontend
                :*core-meta-nodes*
                :*node-true*
                :*node-false*)

  (:import-from :tridash.frontend.strictness
                :strict-arguments
                :strict-outer-operands)

  (:import-from :tridash.backend.js
                :output-code
                :*print-indented*
                :parse-boolean)

  (:shadowing-import-from :generic-cl
                          :emptyp
                          :multiply
                          :accumulate)

  (:shadowing-import-from :generic-cl.util
                          :repeat)

  (:import-from :let-over-lambda
                :mkstr
                :symb
                :lol-syntax)

  (:import-from :agutil
                :update-let
                :nlet)

  (:import-from :flexi-streams
                :with-output-to-sequence)

  (:documentation "WebAssembly Backend."))
