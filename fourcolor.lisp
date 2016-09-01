(ql:quickload "closure-html")
(ql:quickload "cxml-stp")
(ql:quickload "cl-ppcre")

(load "./html-utils.lisp")

(defvar *doc*)

(setf *doc* (build-doc-from-path "/home/xuyang/html-utils/fourcolor.html"))

(defmacro style-attribute-value (name style)
  `(multiple-value-bind (x attr) (cl-ppcre:scan-to-strings (concatenate 'string ,name ":([0-9]+)px") style)
     (format t "~A~%" x)
     (if attr
	 (parse-integer (elt attr 0) :junk-allowed t)
	 (equal 1 0))))

(delete-recursively *doc*
  (and (typep ch 'stp:element)
       (or (equal (stp:local-name ch) "div")
	   (equal (stp:local-name ch) "span"))
       (let* ((style (stp:attribute-value ch "style"))
	      (top (style-attribute-value "top" style)))
	 (if top (< top 241) (equal 1 0)))))


(format t "~A~%" (cxml2str *doc*))

