(defun make-bb-from-string (b)
  (declare (optimize speed (safety 0)) 
           (type string b))
  (the (unsigned-byte 64) (parse-integer b :radix 2)))

(defun make-bb-string-from-vector (v)
  (declare (type (simple-array (mod 2) (8 8)) v))
  (let ((ret ""))
    (dotimes (x 8)
      (dotimes (y 8)
        (setq ret (concatenate 'string ret 
                               (write-to-string (aref v x y))))))
    ret))

(defun make-bb (contents)
  (make-bb-from-string 
   (make-bb-string-from-vector
    (make-array '(8 8) :element-type '(mod 2) 
		:initial-contents contents))))

(defun transpose (x) (apply #'mapcar (cons #'list x)))
(defun inverse (x) (mapcar (lambda (y) (mapcar (lambda (z) (- 1 z)) y)) x))

(defconstant full-rank (list 1 1 1 1 1 1 1 1))
(defconstant empty-rank (list 0 0 0 0 0 0 0 0))


(defmacro make-precomputed-table (size name list)
  `(declaim (type (simple-array (unsigned-byte 64) (,size)) ,name))
  `(defconstant ,name
                (make-array ,size :element-type '(unsigned-byte 64)
                            :initial-contents (mapcar #'make-bb ,list))))


(defun 1-at (n)
  (let ((line empty-rank))
    (loop
       for cell on line
       for i from 0
       when (< i n) collect (car cell)
       else collect 1
       and nconc (rest cell)
       and do (loop-finish))))



(defconstant clear-rank-list
  (let ((rank-list '()))
    (dotimes (rank 8)
      (let ((this-list (make-list 8 :initial-element full-rank)))
	(setf (nth rank this-list) empty-rank)
	(push this-list rank-list)))
    rank-list))

(make-precomputed-table 8 clear-rank clear-rank-list)


(defconstant clear-file-list
            (mapcar #'transpose clear-rank-list))

(make-precomputed-table 8 clear-file clear-file-list)

(print clear-file-list)
(print (mapcar #'make-bb clear-file-list))

(defconstant mask-rank-list
             (mapcar #'inverse clear-rank-list))

(make-precomputed-table 8 mask-rank mask-rank-list)

(defconstant mask-file-list
             (mapcar #'transpose mask-rank-list))

(make-precomputed-table 8 mask-file mask-file-list)

(defun on-board (move-list)
  (remove-if (lambda (m) 
		   (let ((i (car m)) (j (cadr m)))
		     (or (> i 7) (< i 0)
			 (> j 7) (< j 0))))
		 move-list))

(defun position-list-to-board-list (p)
  (let ((board))
    (loop for i from 0 to 7 do
	 (let ((row))
	   (loop for j from 0 to 7 do
		(if (member (list i j) p :test #'equal)
		    (push 1 row)
		    (push 0 row)))
	   (push row board)))
    (nreverse board)))

(defun gen-move-list (func)
  (let ((moves))
    (loop for i from 0 to 7 do
	 (loop for j from 0 to 7 do
	      (push (funcall func i j) moves)))
    moves))
  

(defun gen-king-moves (i j)
  (on-board  `((,(+ i 1) ,(+ j 1))
	       (,(+ i 1) ,j)
	       (,(+ i 1) ,(- j 1))
	       (,(- i 1) ,(+ j 1))
	       (,(- i 1) ,j)
	       (,(- i 1) ,(- j 1))
	       (,i ,(+ j 1))
	       (,i ,(- j 1)))))

(defconstant king-moves-list
  (gen-move-list #'gen-king-moves))

(defun gen-knight-moves (i j)
  (on-board `((,(+ i 2) ,(+ j 1))
	      (,(+ i 1) ,(+ j 2))
	      (,(+ i 2) ,(- j 1))
	      (,(+ i 1) ,(- j 2))
	      (,(- i 2) ,(+ j 1))
	      (,(- i 1) ,(+ j 2))
	      (,(- i 2) ,(- j 1))
	      (,(- i 1) ,(- j 2)))))

(defun gen-pawn-diagonal-up (i j)
  (on-board `((,(+ i 1) ,(- j 1))
	      (,(+ i 1) ,(+ j 1)))))

(defun gen-pawn-diagonal-down (i j)
  (on-board `((,(- i 1) ,(- j 1))
	      (,(- i 1) ,(+ j 1)))))

(defun get-pawn-up (i j)
  (if (= i 1)
      (on-board `((,(+ i 2) ,j)
		  (,(+ i 1) ,j)))
      (on-board `((,(+ i 1) ,j)))))

(defun get-pawn-down (i j)
  (if (= i 6)
      (on-board `((,(- i 2) ,j)
		  (,(- i 1) ,j)))
      (on-board `((,(- i 1) ,j)))))

(defconstant knight-moves-list
  (gen-move-list #'gen-knight-moves))   

(make-precomputed-table 
 64 king-positions (mapcar #'position-list-to-board-list king-moves-list))

(defun position-list (bb)
  (declare (optimize speed)
	   (type (unsigned-byte 64) bb))
  (let ((position-list))
    (loop while (> bb 0) do
	 (let ((index (- (integer-length bb) 1)))
	   (push index position-list)
	   (setf bb (logxor bb (ash 1 index)))))
    position-list))

(print (mapcar #'position-list-to-board-list king-moves-list))
(print (mapcar #'make-bb (mapcar #'position-list-to-board-list king-moves-list)))
(print (mapcar #'position-list
	       (mapcar #'make-bb (mapcar #'position-list-to-board-list king-moves-list))))
(print (integer-length 4))
(print (logxor 4 (ash 1 (- (integer-length 4) 1))))
(print (position-list (make-bb (list 
				empty-rank
				empty-rank
				empty-rank
				empty-rank
				empty-rank
				empty-rank
				empty-rank
				(list 1 0 0 0 0 0 0 1)))))
