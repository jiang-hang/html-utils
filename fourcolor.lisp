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
	 (equal 1 0))))

(defvar *input-pdfs* (rest sb-ext:*posix-argv*))

(defvar *doc*)

(defvar *pages* (list 1 2 3 5 6 11 12 13 14))
(defvar *pages-more* (loop for i from 15 to 276 collect i))
(nconc *pages* *pages-more*)

;(dotimes (i 10)
(dolist (i *pages* )
  (external-program:run "pdf2txt.py" `("-Y" "loose" "-t" "html" "-p"
					    ,(format nil "~d" i)
					    "-o"
					    ,(format nil "p_~d.html" i)
					    ,(first *input-pdfs*)))


  (setf *doc* (build-doc-from-path (format nil "p_~d.html" i)))


  (delete-recursively *doc*
    (and (typep ch 'stp:element)
	 (or (equal (stp:local-name ch) "div")
	     (equal (stp:local-name ch) "span"))
	 (let* ((style (stp:attribute-value ch "style"))
		(top (style-attribute-value "top" style))
		(height (style-attribute-value "height" style))
		)
	   (if (and top height) ; both top and height are defined
	       (and (< top 241) (< height 300))
	       (if top
		   (or (equal top 50) (equal top 0)) ; remove the top and bottom page no
		   (equal 1 0))))))


					;trans font-size 17px to header 2
					;
  (stp:do-recursively (n *doc*)
    (when  (and (typep n 'stp:element)
		(equal (stp:local-name n) "span"))
      (let ((style (stp:attribute-value n "style")))
	(when (and style
		   (equal (style-attribute-value "font-size" style) 17))
	  (setf (stp:local-name n) "h2")))))



  (with-open-file (stream (format nil "./p_~dout.html" i) :direction :output :if-exists :supersede)
    (format stream "~A~%" (cxml2str *doc*)))

					;convert it to md
  (external-program:run "pandoc" `("-f" "html" "-t" "markdown" "-o"
					,(format nil "./p_~d.md" i)
					,(format nil "./p_~dout.html" i))) 
  (format t "ready to use the filter")
  (external-program:run "pandoc" `("-f" "markdown"
					"-t" "markdown"
					"--filter" "/home/xuyang/meteorTrans/stripspan.py"
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
    


