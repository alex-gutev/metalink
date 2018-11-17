;;;; html.lisp
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

;;;; Extract nodes from html files

(in-package :tridash.backend.js)

(defvar *runtime-library-path* "tridash.js"
  "Path to the Tridash runtime library which will be referenced,
   using a script tag, in the output HTML file.")


;;; Link Runtime Library

(defun link-runtime-library (path root-node)
  "Inserts a script tag which references the tridash runtime library
   at path PATH. ROOT-NODE is the root-node of the HTML DOM."

  (plump:make-element
   (find-head-tag root-node)
   "script"
   :attributes (alist-hash-table (acons "src" (mkstr path) nil) :test #'equalp)))


(defun find-head-tag (root-node)
  "Finds the head tag, or an appropriate tag into which a script tag
   can be inserted, in the HTML DOM with root ROOT-NODE."

  (or (find-tag "head" root-node) (find-tag "html" root-node) root-node))

(defun find-tag (tag root-node)
  "Finds a tag with name TAG in the HTML DOM with root ROOT-NODE."

  (first (plump:get-elements-by-tag-name root-node tag)))


;;; Link Generated Code

(defun link-graph (graph root-node &key path)
  "Compiles the node definitions in GRAPH to JavaScript code, which is
   inserted in a script tag. If the keyword argument :PATH is
   provided, the generated code is written to the file at PATH
   instead, and a script tag is inserted which references that file."

  (let ((head-tag (find-head-tag root-node)))
    (cond
      (path
       (output-code-to-file graph path)
       (plump:make-element
        head-tag "script"
        :attributes (alist-hash-table
                     (list
                      (cons "src" (mkstr path))
                      (cons "defer" nil))
                     :test #'equalp)))

      (t
       (plump:make-fulltext-element head-tag "script" :text (output-code-to-string graph))))))

(defun output-code-to-file (graph path)
  "Compiles the node definitions in GRAPH and outputs the code to the
   file at path PATH."

  (with-open-file (*standard-output* path :direction :output :if-exists :supersede)
    (compile-nodes :javascript graph)))

(defun output-code-to-string (graph)
  "Compiles the node definitions in GRAPH and returns a string of the
   generated code."

  (with-output-to-string (*standard-output*)
    (compile-nodes :javascript graph)))


;;;; Compiling HTML nodes

(defmethod create-node ((node html-node) &optional (code (make-code-array)))
  "Generates the node definition for a NODE which corresponds to an
   HTML element."

  ;; Create base node definition first
  (call-next-method)

  (cond
    ((gethash :input (contexts node))
     (make-input-html-node node code))

    ((gethash :object (contexts node))
     (make-output-html-node node code))))

(defun make-input-html-node (node code)
  "Generates the node definition for a node which corresponds to an
   attribute of an HTML element. The HTML element is retrieved and an
   event listener, for changes to the attribute's value, is attached."

  (let ((path (node-path node)))
    (with-slots (element-id tag-name html-attribute) node
      (when html-attribute
        (vector-push-extend
         (make-onloaded-method
          (list
           (make-get-element path element-id)

           (js-call '= (js-member path "value")
                    (js-members path "html_element" html-attribute))

           (make-event-listener node html-attribute)))
         code)))))

(defun make-output-html-node (node code)
  "Generates the node definition for a node which corresponds to an
   HTML element. The update_value method is overridden to update the
   attributes of the element."

  (let ((path (node-path node))
        (context (gethash :object (contexts node))))
    (with-slots (value-function) context
      (vector-push-extend
       (make-onloaded-method
        (list (make-get-element path (element-id node))))
       code)

      (vector-push-extend
       (js-call
        '=
        (js-member path "update_value")
        (js-lambda
         (list "value")
         (mapcar (compose (curry #'make-set-attribute node "value") #'first) (rest value-function))
         )
        )
       code)
      )))

(defun make-get-element (path id)
  "Generates code which retrieves a reference to the HTML element with
   id ID, and stores it in the html_element field of the node, which
   is reference by the expression PATH."

  (js-call '= (js-member path "html_element")
           (js-call (js-member "document" "getElementById")
                    (js-string id))))

(defun make-onloaded-method (body)
  "Generates code which executes the code BODY, after the DOM has been
   constructed."

  (js-call (js-member "document" "addEventListener")
           (js-string "DOMContentLoaded")
           (js-lambda nil body)))

(defun make-set-value (node)
  "Generates a function which sets the attribute (stored in the
   ATTRIBUTE slot) of the element corresponding to the HTML node
   NODE."

  (with-slots (attribute) node
    (js-lambda
     (list "value")
     (list
      (js-call '=
               (js-members "this" "html_element" attribute)
               "value")))))

(defun make-set-attribute (node object attribute)
  "Generates code which sets the attribute the attribute ATTRIBUTE of
   the HTML element stored in the html_element field of NODE. OBJECT
   is an expression referencing a JS object in which the value of the
   attribute (to be set) is stored in the field ATTRIBUTE."

  (let ((path (node-path node)))
    (js-call
     '=
     (js-members path "html_element" attribute)
     (js-member object attribute))))

(defun make-set-attributes (node value-function)
  (labels ((make-set-attribute (attribute)
             (destructuring-bind (key value-fn) attribute
               (let ((*get-input* (curry #'make-link-expression node))
                     (return-var (var-name)))
                 (multiple-value-bind (value-block value-expr)
                     (make-expression value-fn :return-variable return-var :tailp nil)
                   (multiple-value-call #'make-block
                     value-block
                     (use-expression
                      value-expr
                      (lambda (expr)
                        (values
                         (js-block (set-attribute-expression key expr))
                         nil))))))))

           (set-attribute-expression (attribute expr)
             (js-call '=
                      (js-members "self" "html_element" attribute)
                      expr))

           (make-block (block1 block2 expression)
             (js-block block1 block2 expression)))

    (js-lambda
     (list "values")
     (list*
      (js-var "self" "this")
      (mapcar #'make-set-attribute (rest value-function))))))


(defparameter *html-events*
  (alist-hash-table
   '((("input" "value") . "change"))
   :test #'equalp)

  "Hash table containing the \"change\" event names of HTML tag
   attributes. Each key is a list of two values: the tag name and the
   attribute name, with the corresponding value being the change event
   name. The hash-table uses the EQUALP test thus the tag names and
   attributes can be specified as case-insensitive strings.")

(defun make-event-listener (node attribute)
  "Generates code which attaches an event listener to the attribute
   ATTRIBUTE of the HTML element (stored in the html_element field of
   NODE), which updates the value of NODE."

  (let ((path (node-path node)))
    (with-slots (tag-name) node
      (awhen (gethash (list tag-name attribute) *html-events*)
        (js-call (js-members path "html_element" "addEventListener")
                 (js-string it)
                 (js-lambda
                  nil
                  (list
                   (js-call '=
                            (js-member path "value")
                            (js-member "this" attribute))
                   (js-call (js-member path "set_value")
                            (js-member path "value")))))))))
