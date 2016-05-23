;-  Identification and Changes

; Tree ring code.

;	History:
;

;-  Copyright 

;-  Discussion 

"This implements the arithmetic operations on the ring of trees."
"Implemented assuming chibi-scheme/R7RS or a similar implementation."

;-  Configuration stuff 

;-  Included files 


(import (srfi 95))


(load "maths.scm") ;; Includes utils.scm
(load "sort.scm")

;-  Variables/constants both public and static

;--    Static data

;--    Public data 

;-  Code 



;-- Polynomials
;---

"Polynomials are represented as

   ((a_0 (lbl_1 a_1)) ... (lbl_n a_n))

where lbl_i is of the form ((s_1 . p_1) ... (s_j . p_j)), s_j is a
symbol and p_j is the exponent associated with the symbol.
"
(define tr-debugging #t)

(define (ddnl . args)
  (if tr-debugging
		(apply dnl args)))


(define testpoly '(7 (42 (a . 1) (b . 3)) (16 (a . 5) (c . 1)) (1 (a . 1) (b . 1) (c . 1))))
					  

(define (label? l)
  (ddnl "label " l)
  (ddnl (car l))
  (cond
	((not (pair? l)) #t)
	((and
	  (number? (car l))
	  (apply fand (map symbol? (map car (cdr l))))
	  (apply fand (map integer? (map cdr (cdr l))))
	  (apply fand (map positive? (map cdr (cdr l))))
	  )
	 #t)
	(#f #f)
	)
  )

(define (polynomial-term? pt)
  (ddnl "polynomial-term? " pt)
  (or (number? pt) (label? pt)))

  
(define (polynomial? p)
  (ddnl "polynomial? " p)
  (and (number? (car p))
		 (let ((n (length (filter number? p)))) (or (member n '(0 1))))
		 (apply fand (map polynomial-term? (cdr p)))))



(define (node? n)
  (and (number? (car n))
		 (polynomial? (cadr n))
		 (or (null? n) (apply fand (map node? (caddr n))))))


;; A node is of the form (weight polynomial extension-set)

(define emptytree '())
(define zerotree (list 0 0 emptytree))



;;; (define (depth t)
;;;   (cond
;;; 	(not (tree? t) #f)
;;; 	((or (null? t) (equal? t '(0 0 emptytree)))
;;; 	 0)
;;; 	(



;-  The End 


;;; Local Variables:
;;; mode: scheme
;;; outline-regexp: ";-+"
;;; comment-column:0
;;; comment-start: ";;; "
;;; comment-end:"" 
;;; End:
