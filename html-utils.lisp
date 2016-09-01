(ql:quickload "closure-html")
(ql:quickload "cxml-stp")

(defun build-doc-from-path (path)
   (chtml:parse (pathname path) (stp:make-builder)))

(defun build-doc-from-str (str)
  (chtml:parse str (stp:make-builder)))

(defun cxml2str (doc)
  (stp:serialize doc (cxml:make-string-sink)))

(defmacro delete-recursively (doc &body body)
  "doc is created by stp:make-builder, body should return a T/F
ch can be used in the body. it is a cxml node, following is a sample


which delete all the <a> tags

(delete-recursively *doc*
  (and (typep ch 'stp:element)
       (equal (stp:local-name ch) \"a\")))

"
  `(stp:do-recursively (n ,doc)
      (when (typep n 'stp:element)
	(stp:delete-child-if #'(lambda (ch) ,@body)
			     n))))


