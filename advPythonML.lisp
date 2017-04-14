#! /usr/bin/sbcl --script

(load "~/quicklisp/setup.lisp")

(ql:quickload "closure-html")
(ql:quickload "cxml-stp")
(ql:quickload "cl-ppcre")
(ql:quickload "external-program")

(load "./html-utils.lisp")

(defmacro style-attribute-value (name style)
  `(multiple-value-bind (x attr) (cl-ppcre:scan-to-strings (concatenate 'string ,name ":([0-9]+)px") style)
     (format t "~A~%" x)
     (if attr
	 (parse-integer (elt attr 0) :junk-allowed t)
	 nil)))

(defvar *input-pdfs* (rest sb-ext:*posix-argv*))

(defvar *doc*)

;(defvar *pages* (list 1 2 3 5 6 11 12 13 14))
;(defvar *pages-more* (loop for i from 15 to 276 collect i))
;(nconc *pages* *pages-more*)
;(defvar *pages* (loop for i from 14 to 25 collect i))
(defvar *pages* (list 1 2 3 4 5 6 7 8 9 10))

;(dotimes (i 10)
(dolist (i *pages* )
  (external-program:run "pdf2txt" `("-Y" "loose" "-t" "html" "-p"
					    ,(format nil "~d" i)
					    "-o"
					    ,(format nil "p_~d.html" i)
					    ,(first *input-pdfs*)))


  (setf *doc* (build-doc-from-path (format nil "p_~d.html" i)))

  (let ((*in-bottom* nil))
   (delete-recursively *doc*
    (and (typep ch 'stp:element)
	 (or (equal (stp:local-name ch) "div")
	     (equal (stp:local-name ch) "span"))
	 (let* ((style (stp:attribute-value ch "style"))
		(top (style-attribute-value "top" style))
		;(height (style-attribute-value "height" style))
		)
             (format t "delete recursive : in-bottom: ~A~%" *in-bottom*)
  	     (if *in-bottom* 
 			(format t "true in bottom")
 			(format t "not true in bottom"))
             (when top
                 (if (>= top 714)
                    (setf *in-bottom* t)))
	     (if top
	         (or (< top 160) (>= top 714))
		 nil)))))


;trans font-size 17px to header 2
;change the tag name according to the style
  (stp:do-recursively (n *doc*)
    (when  (and (typep n 'stp:element)
        	(equal (stp:local-name n) "span"))
      (let ((style (stp:attribute-value n "style")))
        (when style
	   (Cond
	      ((equal (style-attribute-value "font-size" style) 27) 
                  (setf (stp:local-name n) "h1"))
       	      ((equal (style-attribute-value "font-size" style) 19)
                  (setf (stp:local-name n) "h2"))
              ((search "Italic" style) 
                  (setf (stp:local-name n) "em"))
              ((search "Bold" style)
                  (setf (stp:local-name n) "strong"))
              ((search "CourierStd" style)
                  (setf (stp:local-name n) "code")))))))

;; change the <div><code>...</code></div>  to <pre><code>
;; if the div has only one child , and the child tag is <code>

  (stp:do-recursively (n *doc*)
    (when  (and (typep n 'stp:element)
        	(equal (stp:local-name n) "div")
                (equal 1 (stp:number-of-children n))
	        (equal (stp:local-name (stp:first-child n)) "code"))
         (setf (stp:local-name n) "pre")))

  (with-open-file (stream (format nil "./p_~dout.html" i) :direction :output :if-exists :supersede)
    (format stream "~A~%" (cxml2str *doc*)))

					;convert it to md
  (external-program:run "pandoc" `("-f" "html" "-t" "markdown" "-o"
					,(format nil "./p_~d.md" i)
					,(format nil "./p_~dout.html" i))) 
  (format t "ready to use the filter")
  (external-program:run "pandoc" `("-f" "markdown"
        				"-t" "markdown"
        				"--filter" "/home/xuyang/AdvPythonML/stripspan.py"
        				"-o" ,(format nil "./filtered_p~d.md" i)
        				,(format nil "./p_~d.md" i)))

  
  )

; merge the files
(format t "##################################################################")

(with-open-file (stream "./merge.sh" :direction :output :if-exists :supersede)
  (format stream "rm -rfv ./final.md~%")
  (format stream "touch ./final.md~%")
  (dolist (i *pages*)
    (format stream "echo \"\" >> final.md~%")
    (format stream "echo \"//page ~d\" >> final.md~%" i)
    (format stream "echo \"\" >> final.md~%")
    (format stream "cat ./filtered_p~d.md >> final.md~%" i)
    ))
    


