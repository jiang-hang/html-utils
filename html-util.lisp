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

(defvar *doc*)

;(setf *doc* (build-doc-from-str "<p>hello <em>world</em></p><a href=http://a.com>link</a>"))
(setf *doc* (build-doc-from-path "/home/xuyang/fourcolor.html"))

(defvar *str* (stp:serialize *doc* (cxml:make-string-sink)))

(delete-recursively *doc*
  (and (typep ch 'stp:element)
       (equal (stp:local-name ch) "a")))

;(format t "~A~%" *doc*)
(format t "~A~%" (cxml2str *doc*))

