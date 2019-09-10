#|
 This file is a part of Plump
 (c) 2014 Shirakumo http://tymoon.eu (shinmera@tymoon.eu)
 Author: Nicolas Hafner <shinmera@tymoon.eu>
|#

(in-package #:org.shirakumo.plump.parser)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defvar *whitespace* '(#\Space #\Newline #\Tab #\Return #\Linefeed #\Page)))
(defvar *root*)
(defvar *tagstack* ())

(define-matcher whitespace (find *whitespace*))
(define-matcher name (or (in #\a #\z) (in #\? #\Z) (in #\- #\:) (any #\\ #\_ #\! #\# #\[ #\])))
(define-matcher tag-end (or (and (is #\/) (next (is #\>))) (is #\>)))

(defun skip-whitespace ()
  (loop while (find (peek) *whitespace*)
        do (advance)))

(defun read-name ()
  (consume-until (make-matcher (or (not :name) :tag-end))))

(defun read-text ()
  (make-text-node
   *root*
   (decode-entities
    (consume-until (make-matcher (and (is #\<) (next :name)))))))

;; Robustify against strings inside containing >
(defun read-tag-contents ()
  (decode-entities
   (consume-until (make-matcher :tag-end))))

(defun read-children ()
  (let* ((close-tag (concatenate 'string "</" (tag-name *root*)))
         (*tagstack* (cons close-tag *tagstack*)))
    (catch close-tag
      (loop while (peek)
            do (or (read-tag) (read-text))))))

(defun read-attribute-value ()
  (decode-entities
   (let ((first (peek)))
     (case first
       (#\" (prog2 (advance)
                (consume-until (make-matcher (is #\")))
              (advance)))
       (#\' (prog2 (advance)
                (consume-until (make-matcher (is #\')))
              (advance)))
       (T (consume-until (make-matcher (or :whitespace :tag-end))))))))

(defun read-attribute-name ()
  (consume-until (make-matcher (or (is #\=) :whitespace :tag-end))))

(defun attribute-location ()
  "Returns the location of the current attribute. The return value is
   a CONS where the first element is the string storing the HTML file
   and the second element is the index, within the string, of the
   first character of the attribute."

  (cons
   *string*
   (case (peek)
     ((#\" #\') (1+ *index*))
     (otherwise *index*))))

(defun read-attribute ()
  (let ((name (read-attribute-name))
        (value "")
        (pos (cons *string* *index*)))
    (skip-whitespace)
    (let ((next (consume)))
      (cond
        ((and next (char= next #\=))
         (skip-whitespace)
         (setf pos (attribute-location))
         (setf value (read-attribute-value)))
        ((not next)
         (cons name NIL))
        (T
         (unread))))
    (list name value pos)))

(defun read-attributes ()
  (loop with table = (make-attribute-map)
     with locations = (make-attribute-map)
     for char = (peek)
     do (case char
          ((#\/ #\> NIL)
           (return (values table locations)))
          (#.*whitespace*
           (advance))
          (T
           (destructuring-bind (name value pos) (read-attribute)
             (setf (gethash name table) value)
             (setf (gethash name locations) pos))))))

(defun read-standard-tag (name)
  (let* ((closing (consume)))

    (multiple-value-bind (attrs attr-locations)
        (if (member closing *whitespace* :test #'eql)
            (multiple-value-prog1 (read-attributes)
              (setf closing (consume)))
            (values
             (make-attribute-map)
             (make-attribute-map)))

      (case closing
        (#\/
         (advance)
         (make-element *root* name
                       :attributes attrs
                       :attr-locations attr-locations))
        (#\>
         (let ((*root* (make-element *root* name
                                     :attributes attrs
                                     :attr-locations attr-locations)))
           (read-children)
           *root*))))))

(defun read-tag ()
  (if (and (char= #\< (or (consume) #\ ))
           (funcall (make-matcher :name)))
      (let ((name (read-name)))
        (or (do-tag-parsers (test func (read-standard-tag name))
              (when (funcall (the function test) name)
                (return (funcall (the function func) name))))
            (progn ;; It seems we can't parse this tag for some reason,
              ;; read it as a text node instead. In order to avoid the
              ;; auto-breaking of the text node on < and a subsequently
              ;; resulting infinite-loop, don't unwind fully and instead
              ;; prepend the < manually.
              (unread-n (length name))
              (let ((text (read-text)))
                (setf (text text) (concatenate 'string "<" (text text)))
                text))))
      (progn (unread) NIL)))

(defun read-root (&optional (root (make-root)))
  (let ((*root* root))
    (loop while (peek)
          do (or (read-tag) (read-text)))
    *root*))

(defun slurp-stream (stream)
  (declare (stream stream))
  (with-output-to-string (string)
    (let ((buffer (make-array 4096 :element-type 'character)))
      (loop for bytes = (read-sequence buffer stream)
            do (write-sequence buffer string :start 0 :end bytes)
            while (= bytes 4096)))))

(defgeneric parse (input &key root)
  (:method ((input string) &key root)
    (let ((input (typecase input
                   (simple-string input)
                   (string (copy-seq input)))))
      (with-lexer-environment (input)
        (if root
            (read-root root)
            (read-root)))))
  (:method ((input pathname) &key root)
    (with-open-file (stream input :direction :input)
      (parse stream :root root)))
  (:method ((input stream) &key root)
    (parse (slurp-stream input) :root root)))
