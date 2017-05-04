(include "framework")
;-  Identification and Changes

(define (stopit #!rest args) (void))

(define (cnc a) (class-name-of (class-of a)))
(define (nm? a) (if (isa? a <agent>) (slot-ref a 'name) a))

(define DONT-FILTER-TARGET-VARIABLES #t)


"In the logging code, a 'page' is notionally a pass through the target
agent list.  The page-preamble may open a file and write some
preliminary stuff, or it may just assume that the file is open already
and do nothing at all.  Similarly the page-epilogue does things like
close pages and emit 'showpage' for postscript stuff.
"

(define map:linewidth 0.2) ;; useful width as a default
(define map:lightwidth 0.1) ;; useful light weight width for extra info


(define introspection-priority 10000)


(define (*is-class? targetclass #!rest plural)
  ;; this odd way of specifying arguments  ensures at last one arg
  (let ((targets (cons targetclass plural))) 
	 (lambda (x)
		(if (eq? x 'inspect)
			 ;;(dnl* "targetclass =" targetclass ": plural =" plural ": targets =" targets)
			 (list targets)
			 (apply orf (map (lambda (target) (isa? x target)) targets)))
		)))


"Examples might be
    (*is-class? <fish>)
    (*is-class? <fish> <mollusc> <amphipod> <monkey>)
"

(define (*has-slot? slot)
  (let ((slot slot))
	 (lambda (x) 
		(if (list? slot)
			 (apply orf (map (lambda (y) (has-slot? x y)) slot))
			 (has-slot? x slot)))))


(define (*has-slot-value? slot v)
  (let ((slot slot)
		  (v v))
	 (cond
	  ((procedure? v) ;; v is a predicate function
		(lambda (x) (if (not (has-slot? x slot))
							 #f
							 (v x))))
	  ((list? v)
		(lambda (x) (if (not (has-slot? x slot))
							 #f
							 (eqv? v x))))
	
	  (#t 	 (lambda (x) (if (not (has-slot? x slot))
									  #f
									  (eq? v x)))))))
"Examples might be 
   (*has-slot-value 'age (lambda (age) (and (<= 7 age) (<= age 20))))
   (*has-slot-value 'reproductive-state '(adolescent adult post-breeding))
   (*has-slot-value 'water-stressed #t)

If the agent does not possess the slot, it cannot have the indicated property
and so it is excluded.
"


(define (*is-taxon? targettaxa #!rest cmp)
	 (lambda (x)
		(let* ((c (if (null? cmp) '() (car cmp)))
				 (cmpop (cond
						  ((null? c) string=?)
						  ((eq? c 'ci) string-ci-?)
						  ((eq? c 'wild) wildmatch)
						  ((eq? c 'wild-ci) wildmatch-ci)
						  (#t eqv?))))
		(if (list? targettaxa)
			 (apply orf (map (lambda (y) (cmpop y (slot-ref x 'taxon))) targettaxa))
			 (cmpop targettaxa (slot-ref x 'taxon))))))

;;Examples might be
;;    (*is-taxon? "Thunnus*" 'wild)
;;    (*is-taxon? "Red VW-microbus" 'ci)
;;	   (*is-taxon? (list "grocer" "haberdasher" "butcher" "wheelwright"))


(define (introspection-filename filename filetype filename-timescale #!optional time)
  (let ((field-width 12)) ;; this may need to be increased 
	 (if (string? filename)
		  (if time
				(string-append filename "-" (pno (inexact->exact (/ time filename-timesscale)) 12) "." filetype) 
				(string-append filename "." filetype))
		  #f)))



;; Logger agents (things that inherit from introspection, really) have
;; a high priority; as a consequence they get sorted to the front of a
;; timestep
;; (agent-initialisation-method <log-introspection> (args)
;;  (no-default-variables)
;;  (set-state-variables
;;   self (list 'type 'logger
;; 				 'priority introspection-priority ;; also set in <introspection>
;; 				 'jiggle 0 'introspection-targets '()  ;; also set in <introspection>
;; 				 'timestep-epsilon 1e-6 'file #f ;; also set in <introspection>
;; 				 'filename #f 'filetype #f
;; 				 'format 'text 'missing-val "NoData"
;; 				 'show-field-name #f 'preamble-state '()
;; 				 'dont-log '(ready-for-prep
;; 								 ;; agent things
;; 								 agent-body-ran 
;; 								 agent-epsilon local-projection inv-local-projection counter 
;; 								 migration-test state-flags
;; 								 dont-log timestep-schedule kernel
								 
;; 								 ;; log agent things
;; 								 introspection-targets
;; 								 timestep-epsilon 

;; 								 dims ;; thing things

;; 								 ;; environment things
;; 								 default-value minv maxv 

;; 								 ;; ecoservice things
;; 								 plateau-interval growth-rate 

;; 								 ;; landscape things
;; 								 service-list service-update-map
;; 								 update-equations terrain-function
;; 								 dump-times scale 
;; 								 log-services-from-patch
;; 								 log-patches-from-habitat

;; 								 ;; animal things
;; 								 domain-attraction food-attraction 
;; 								 near-food-attraction searchspeed
;; 								 wanderspeed foragespeed	
;; 								 movementspeed foodlist homelist
;; 								 breedlist habitat

;; 				 'variables-may-be-set #t
;; 				 ))
;;  (initialise-parent) ;; call "parents" last to make the
;;  ;; initialisation list work
;;  (set-state-variables self args)
;;  )

(model-body% <log-introspection>
		(kdebug '(log-* introspection-trace)
				  "[" (my 'name) ":" (class-name-of self) "]"
				  "Introspection: model-body")

		(if (uninitialised? (my 'report-time-table))
					 (begin
						;;a(warning-log (dnl* "A" (class-name-of (class-of self)) " had trouble setting up its report-time-table."))
						(slot-set! self 'report-time-table (make-table))))

				(let ((sched (my 'timestep-schedule))
						)

				  (if (kdebug? 'introspection-trace)
						(pp (dumpslots self)))

				  (set! dt (if (and (pair? sched) (< (car sched) (+ t dt)))
									(- (car sched) t)
									dt))

				  (kdebug '(log-* introspection-trace)
							"      list:     " (map taxon (my-list self)))
				  (kdebug '(log-* introspection-trace)
							"      schedule: "
							(list-head (my 'timestep-schedule) 3)
							(if (> (length (my 'timestep-schedule)) 3)
								 '... ""))
				  
				  (set-my! 'variables-may-be-set #f)
				  (emit-page self)

				  ;;(skip-parent-body)
				  (call-next-parent-body) ;; parent body sets the time step used
				  dt
				  ))


(model-method (<log-introspection>) (my-list self)
				  (let ((mit (my 'introspection-targets))
						  (Q (agent-kcall self 'runqueue))) ;; This is how an agent would usually call the kernel 

					 (sortless-unique
					  (letrec ((loop (lambda (mitr mlist)
											 (cond
											  ((null? mitr) mlist)
											  ((isa? (car mitr) <agent>) (loop (cdr mitr) (cons (car mitr) mlist)))
											  ((class? (car mitr)) (loop (cdr mitr) (append (filter (*is-class? (car mitr)) Q) mlist)))
											  ((string? (car mitr)) (loop (cdr mitr) (append (filter (*is-taxon? (car mitr)) Q) mlist)))
											  ((symbol? (car mitr)) (loop (cdr mitr) (append (filter (*has-slot? (car mitr)) Q) mlist)))
											  ((procedure? (car mitr)) (loop (cdr mitr) (append (filter procedure Q) mlist)))
											  (#t (error "args to my-list must be agents, strings, symbols classes or procedures" (car mlist)))))
										  ))
						 (loop mit '())))
					 ))

(model-method (<log-introspection> <number> <number>) (agent-prep self start end)
				  (agent-prep-parent self start end) ;; parents should prep first
				  )

(model-method <log-introspection> (agent-shutdown self #!rest args)
				  (let ((file (my 'file)))
					 (if (and (my 'file)
								 (output-port? (my 'file))
								 (not (memq (my 'file)
												(list (current-output-port)
														(current-error-port)))))
						  (close-output-port file))
					 (set-my! 'file #f)
					 (agent-shutdown-parent)
					 ))

(model-method (<log-introspection> <list>) (set-variables! self lst)
				  (if (and (my 'variables-may-be-set) (list? lst))
						(set-my! 'variables lst)
						(abort "cannot extend variables after it starts running")
						))

(model-method (<log-introspection> <list>) (extend-variables! self lst)
				  (if (and (my 'variables-may-be-set) (list? lst))
						(set-my! 'variables (unique* (append (my 'variables) lst)))
						(abort "cannot extend variables after it starts running")
						))

(model-method (<log-introspection> <agent> <number>) (emit-and-record-if-absent self agent t)
				  (let* ((tbl (my 'report-time-table))
							(rec (table-ref tbl agent #f))
							)
					 (if (kdebug? 'logger-redundancy-check)
						  (begin
							 (dnl "LOGGER TIME CHECK: record for " (name agent) ":" (slot-ref agent 'subjective-time) " returns " rec)
							 (dnl* "   logger is currently examining the time" t)
							 ))


					 (if (or (not rec) (and (number? t) (< rec t)))
						  	(begin
							  (table-set! tbl agent t)
							  #t)
							#f)))
								
(model-method (<log-introspection>) (emit-page self)
				  (kdebug '(log-* introspection-trace)
							"[" (my 'name) ":" (class-name-of self) "]"
							"Introspection: emit-page")
				  (kdebug '(log-*) (my-list self))				  
				  (let ((format (my 'format)))
;					 (dnl* "ERR: in model-method:<log-introspection> (emit-page self)" (cnc self))
;					 (dnl* "     format" format "... heading into preamble")
					 (page-preamble self self format) ;; for snapshots,
																 ;; this will be
																 ;; "opening", for
																 ;; logfiles, it will
																 ;; only open the
																 ;; first time

;					 (dnl* "ERR: about to dispatch to targets: " (map cnc (my-list self)))
					 (let ((proc (lambda (ila)
										(kdebug '(log-* introspection-trace) " ==> processing "
												 (cnc ila) " "  (procedure? ila))
										(log-data ila self format (my 'variables))
										(kdebug '(log-* introspection-trace) " <== PROCESSED "
												 (cnc ila) " "  (procedure? ila))
										#f
										)))
						(for-each proc (my-list self))
						)
;					 (dnl* "ERR: about to run epilogue")
					 (page-epilogue self self (slot-ref self 'format))
;					 (dnl* "ERR: leaving emit page")
					 
					 )
				  )


;---- snapshot methods -- <snapshot>s open a new file each time they run model-body

;; (agent-initialisation-method <snapshot> (args) (no-default-variables)
;; 				  (initialise-parent) ;; call "parents" last to make the
;; 											 ;; initialisation list work
;; 				  (set-state-variables self (list 'type snapshot 'lastfile #f
;; 												 'currentfile #f))
;; 				  (set-state-variables self args)
;; 				  )

(model-method <snapshot> (page-preamble self logger format)
				  (kdebug '(introspection snapshot)"[" (my 'name) ":"
							(class-name-of self) "]" "<snapshot> is preparing to dump")
				  (let ((filename (my 'filename))
						  (filetype (my 'filetype))
						  (file (my 'file))
						  (t (my 'subjective-time))
						  )

					 (cond ;; Check for error conditions
					  ((not (or (and (not filename) (not (string? filename))) (string? filename)))
						(error (string-append (my 'name)" has a filename which "
													 "is neither false, nor a string.")))

					  ((not (or (and (not filetype) (not (string? filename))) (string? filetype)))
						(error (string-append (my 'name) " has a filetype which "
													 "is neither false, nor a string.")))

					  ((not (number? t))
						(error (string-append (my 'name) " has a subjective time "
													 "which is not a number.")))
					  )

					 (kdebug '(introspection logfile) "[" (my 'name) ":"
							  (class-name-of self) "]" "is opening a log file" "(" filename ")")

					 ;; Open a new file
					 (cond
					  ((not file)
						(let ((fn (introspection-filename (my 'filename)
																	 (my 'filetype)
 																	 (my 'filename-timescale) t))) ;; t is time
						  (kdebug '(introspection snapshot) "[" (my 'name) ":"
									(class-name-of self) "]" "opening" fn)
						  (set-my! 'lastfile (my 'currentfile))
						  (set-my! 'currentfile fn)
						  (if (or (not (string? fn) (not fn) (zero? (string-length fn))))
								(set! file (current-output-port))
								(set! file (open-output-file fn)))
						  ))
					  ((memq file (list (current-output-port) (current-error-port)))
						;; do nothing really
						(kdebug '(introspection snapshot) "[" (my 'name) ":"
								 (class-name-of self) "]"
								 "is writing to stdout or stderr")
						#!void
						)
					  (else 
						(kdebug '(introspection  snapshot) "[" (my 'name) ":"
								 (class-name-of self) "]" " "
								 "has hit page-preamble with a file that is still open."
								 "\nThis is an error.\nClosing the file ("
								 (my 'lastfile) ") and continuing.")
						(close-output-port file)
						(set-my! 'file #f)
						(let ((fn (introspection-filename (my 'filename)
																	 (my 'filetype) t)))
						  (set-my! 'lastfile (my 'currentfile))
						  (set-my! 'currentfile fn)
						  (if (or (not fn) (and (string? fn) (zero? (string-length fn))))
								(set! file (current-output-port))
								(set! file (open-output-file fn)))
						  )
						)
					  )
					 
					 (set-my! 'file file)

					 (kdebug '(introspection logfile) "[" (my 'name) ":"
							  (class-name-of self) "]" "opened" file)
					 )
				  )

(model-method <snapshot> (page-epilogue self logger format)
				  (let ((file (my 'file)))
					 (if (and file (not (memq file (list (current-output-port)
																	 (current-error-port)))))
						  (begin
							 (kdebug '(introspection snapshot) "[" (my 'name) ":"
									  (class-name-of self) "]"
									  "is closing the output port")
							 (close-output-port file)
							 (set-my! 'file #f)))))


;(use-parent-body <snapshot>)

(define (colour-mapping C)
  (case C
	 ((#t) 0.0)
	 ((#f) 1.0)
	 ((red) '(1.0 0.0 0.0))
	 ((darkred) '(0.5 0.0 0.0))
	 ((lightred) '(1.0 0.5 0.5))
	 ((green) '(0.0 1.0 0.0))
	 ((darkgreen) '(0.0 0.5 0.0))
	 ((lightgreen) '(0.5 1.0 0.5))
	 ((blue) '(0.0 0.0 1.0))
	 ((darkblue) '(0.0 0.0 0.5))
	 ((lightblue) '(0.5 0.5 1.0))
	 ((grey gray) '(0.5 0.5 0.5))
	 ((lightgrey lightgray) '(0.82 0.82 0.82))
	 ((midgrey midgray) '(0.75 0.75 0.75))
	 ((darkgrey darkgray) '(0.3 0.3 0.3))
	 ((black) '(0.0 0.0 0.0))
	 ((white) '(1.0 1.0 1.0))
	 (else
	  (cond
		((and (number? C) (inexact? C) (<= 0.0 C) (<= C 0.1))
		 (make-list 3 C))

		((and (number? C) (integer? C) (<= 0 C) (<= C 255))
		 (map (lambda (v) (/ v 255.0)) (make-list 3 C)))

		((and (list? C) (= (length C) 3) (apply andf map (lambda (v) (and (number? v) (<= 0 v) (<= v 1.0))) C))
		 C)

		((and (list? C) (= (length C) 3) (apply andf map (lambda (v) (and (integer? v) (<= 0 v) (<= v 255))) C))
		 (map (lambda (v) (/ v 255.0)) C))
		(#t (error "Bad colour" C))))))
		 



;---- log-map methods (inherits from <snapshot>)
 
(model-method (<log-map> <list> <number> <boolean>) ;; colours can be #t/#f simple names, in [0.-1.], [0,255], or rgb as fp or int
				  (log-map-circle self ms:location radius mark-centre colour)
				  (let* ((location (model->local self ms:location))
							(radius (car (make-list (length location) radius)))
							(col (colour-mapping colour))
							(ps (my 'file))
							)
					 (if mark-centre
						  (begin
							 (ps 'comment (string-append "log-map-circle at " (object->string ms:location) " " (number->string radius) " r."))
							 (ps-circle ps (* 0.01 radius) location map:lightwidth col)
							 ;(ps-circle ps (* 0.05 radius) location map:lightwidth col)
							 (ps-circle ps (* 0.3 radius) location map:lightwidth col)
							 (ps-circle ps (* 0.5 radius) location map:lightwidth col)
							 (ps-circle ps (* 0.7 radius) location map:lightwidth col)
							 ;(ps-circle ps (* 0.95 radius) location map:lightwidth col)
							 ))
					 
					 (ps-circle ps (* 0.7 radius) location map:linewidth 0)))

(model-method (<log-map> <list> <number> <boolean>) ;; colours can be #t/#f simple names, in [0.-1.], [0,255], or rgb as fp or int
				  (log-map-polygon self ms:perimeter mark-centre colour)
				  (let* ((perimeter (map (lambda (x) (model->local self x) ms:location)))
							(col (colour-mapping colour))
							(ps (my 'file))
							)

					 (ps 'comment (string-append "log-map-polygon " (object->string perimeter)))
					 (plot-polygon ps map:linewidth col 1 perimeter)))


;(use-parent-body <log-map>)

(model-method (<log-map> <log-introspection> <symbol>) (page-preamble self logger format)
				  ;; This *must* replace it's parent from <snapshot> since
				  ;; it doesn't work with a traditional port
				  (kdebug '(log-* log-map) (name self) "[" (my 'name) ":"
							(class-name-of self) "]" "in page-preamble")
				  (let ((filename (my 'filename))
						  (filetype (my 'filetype))
						  (file (my 'file))
						  (t (my 'subjective-time))
						  )

					 (cond
					  ((eqv? format 'png)
						(error "<log-map> only supports postscript at the moment"))
					  ((eqv? format 'svg)
						(error "<log-map> only supports postscript at the moment"))
					  ((eqv? format 'gif)
						(error "<log-movie> isn't implemented yet"))
					  ((eqv? format 'mpg)
						(error "<log-movie> isn't implemented yet"))
						
					  ((not (member format '(ps))) ;; svg png
						(error "Currently <log-map> only supports postscript." format))
					  
					  ((not (or (not filename) (string? filename)))
						(error (string-append (my 'name) " has a filename which is "
													 "neither false, nor a string.")))

					  ((not (or (not filetype) (string? filetype)))
						(error (string-append (my 'name) " has a filetype which is "
													 "neither false, nor a string.")))

					  ((not (number? t))
						(error (string-append (my 'name) " has a subjective time "
													 "which is not a number.")))
					  )

					 ;; Open a new file
					 (cond
					  ((not (output-port? file))
						(kdebug '(introspection log-map) "[" (my 'name) ":"
								 (class-name-of self) "]" "<log-map>" "is preparing to dump")
						
						(let ((fn (introspection-filename (my 'filename)
																	 (my 'filetype) t)))
						  (set-my! 'lastfile (my 'currentfile))
						  (set-my! 'currentfile fn)
						  (if (not fn)
								(void)
								(if (and (string? fn) (zero? (string-length fn)))
									 (abort "Oh. Bother.")
									 (set! file (make-ps fn '(Helvetica)))))
						  )
						(kdebug '(introspection log-map) "[" (my 'name) ":"
								 (class-name-of self) "]" "returning from preamble")
						)
					  ((memq file (list (current-output-port) (current-error-port)))
						;; do nothing really
						(kdebug '(introspection log-map) "[" (my 'name) ":"
								 (class-name-of self) "]" "has nothing to do")
						#!void
						)
					  (else 
						(kdebug '(introspection log-map) "[" (my 'name) ":"
								 (class-name-of self) "]"
								 " Good, we've hit page-preamble with a file "
								 "that is still open.\nClosing the file (" 
								 (my 'lastfile) ") and opening a new one.")
						(if (output-port? file)
							 (close-output-port file))
						(set-my! 'file #f)
						(let ((fn (introspection-filename (my 'filename)
																	 (my 'filetype) t)))
						  (set-my! 'lastfile (my 'currentfile))
						  (set-my! 'currentfile fn)
						  (if (or (not fn) (string? fn) (zero? (string-length fn)))
								(abort "Oh. Bother.")
								(set! file (make-ps fn '(Helvetica))))
						  )
						)
					  )
					 (set-my! 'file file)))

(model-method (<log-map> <log-introspection> <symbol>) (page-epilogue self logger format)
				  ;; This *must* replace it's parent from <snapshot> since
				  ;; it doesn't work with a traditional port
				  (kdebug '(log-* log-map) (name self) "[" (my 'name) ":"
							(class-name-of self) "]" "has page-epilogue")
				  (let ((file (my 'file))
						  (name (my 'currentfile)))
					 (if file
						  (begin
							 (file 'close)
							 (set-my! 'file #f)))
					 )
				  )


;; This logs to an open file
(model-method (<log-map> <log-introspection> <symbol>) (log-data self logger format targets)
				  (kdebug 'log-horrible-screaming 'log-map (cnc self) (cnc logger) (cnc format) (cnc targets))
				  (lambda (target)	
					 (kdebug '(log-* log-map) (name self) "[" (my 'name)
							  ":" (class-name-of self) "]" "in log-data"
							  (class-name-of target) (slot-ref target 'name))

					 (let* ((name (slot-ref target 'name))
							  (p (slot-ref self 'local-projection))
							  ;; to spit out a ps file we need to project the 
							  ;; modelspace data into the PS domain
							  (ps (slot-ref self 'file))
							  )
						(ps 'comment "logging data for " name "****************")
						(ps 'moveto (list (p '(20 20))))
						(ps 'setgray 0.0)
						(ps 'Helvetica 14)
						(ps 'show (string-append (slot-ref self 'name)))
						(ps 'comment "finished logging data for " name)
						)))

;---- logfile methods -- <logfile>s open a single file and use that till they finish running

(model-method <logfile> (page-preamble self logger format)
				  (kdebug '(introspection logfile) "[" (my 'name) ":"
							(class-name-of self) "]" "<logfile> is preparing to dump, file is currently" (my 'filename) (my 'file))

				  (let ((filename (my 'filename))
						  (file (my 'file))
						  )
					 
					 (kdebug 'logfile-issues "In: logfile preamble filename " filename "and file" file)

					 (if (or (uninitialised? filename) (not (or (not filename) (string? filename))))
						  (error (string-append (my 'name) " has a filename which is "
														"neither false, nor a string.")))
					 ;; Open a new file
					 (if (or (uninitialised? file) (not file))
						  (begin
							 (kdebug '(introspection logfile) "[" (my 'name) ":"
									  (class-name-of self) "]" "is opening a log file" "(" filename ")")
							 (if (kdebug? '(introspection logfile))
								  (if (or (not filename) (not (string? filename)) (zero? (string-length filename)))
										(dnl* "opening current output port" (not filename) (string? filename) (zero? (string-length filename)))
										(dnl* "opening " filename)))
								  
							 (if (or (not filename) (not (string? filename)) (zero? (string-length filename)))
								  (set! file (current-output-port))
								  (set! file (open-output-file filename))
							 )
							 (kdebug '(introspection logfile) "[" (my 'name) ":"
									  (class-name-of self) "]" "opened" file)
							 )
						  )
					 (kdebug 'logfile-issues "Mid: logfile preamble filename " (my 'filename) "and file" (my 'file)"/"file)
					 (set-my!'file file)
					 (kdebug 'logfile-issues "Out: logfile preamble filename " (my 'filename) "and file" (my 'file)"/"file)
					 )
				  )

(model-method <logfile> (page-epilogue self logger format)
				  (kdebug 'logfile-issues "In: logfile epilogue filename " (my 'filename) "and file" (my 'file))
				  (kdebug '(introspection logfile) "[" (my 'name) ":"
							(class-name-of self) "]" "has finished a dump")
				  (kdebug 'logfile-issues "Out: logfile epilogue filename " (my 'filename) "and file" (my 'file))
				  #!void)



;---- log-data methods (inherits from <logfile>)

;(use-parent-body <log-data>)

(model-method (<log-data> <number> <number>) (agent-prep self start end)
				  ;; This opens the output file on initialisation.
				  (agent-prep-parent self start end) ;; parents should prep first
				  (kdebug '(log-* log-data) (name self) "[" (my 'name) ":"
							(class-name-of self) "]" "in agent-prep")
				  
				  (let ((filename (my 'filename))
						  (filetype (my 'filetype)))
					 (if (string? (my 'filename))
						  (begin
							 (kdebug '(log-* log-data) (name self) "[" (my 'name)
									  ":" (class-name-of self) "]" "opening "
									  (introspection-filename filename
																	  (if filetype filetype "")))
							 (set-my! 'file
										 (open-output-file
										  (introspection-filename filename
																		  (if filetype
																				filetype
																				""))))
							 (current-output-port))
						  (begin
							 (kdebug '(log-* log-data) (name self) "[" (my 'name) ":"
									  (class-name-of self) "]"
									  "using stdout as the output file " )
							 (set-my! 'file (current-output-port))
							 )
						  )
					 )
				  (if (null? (my 'variables))
						(let ((vars (reverse
										 (unique*
										  (reverse
											(append
											 '(name subjective-time)
											 (apply append
													  (map extra-variable-list
															 (my-list self)))))))))
						  (slot-set! self 'variables vars)))
				  )


(model-method <log-data> (agent-shutdown self #!rest args)
				  (kdebug '(log-* log-data) (name self) "[" (my 'name) ":"
							(class-name-of self) "]" "in agent-shutdown")
				  (if (and (my 'file) (output-port? (my 'file))
							  (not (memq (my 'file)
											 (list (current-output-port)
													 (current-error-port)))))
						(begin
						  (close-output-port (my 'file))
						  (set-my! 'file #f) ;; leave it the way it should be left
						  ))
				  (agent-shutdown-parent) ;; Parents should shutdown last
				  )

(model-method (<log-data> <log-introspection> <symbol>) (page-preamble self logger format)
				  (kdebug 'log-issues "In: log-data preamble filename " (my 'filename) "and file" (my 'file))

				  (page-preamble-parent) ;; opens the file

				  (kdebug 'log-issues "In: log-data, after logfile preamble filename " (my 'filename) "and file" (my 'file))

				  (kdebug 'log-init "Logfile is" (my 'filename)
							"(output-port?" (my 'file) ") =" (output-port? (my 'file)))
				  (if (not (output-port? (my 'file)))
						(abort "Serious problems getting an output port for "
								 (my 'name)))

				  (let ((il (my-list self))
						  (file (my 'file))
						  (show-field-name (my 'show-field-name))
						  (missing-val (my 'missing-val))
						  )
					 (case format
						((ps)
						 #f)
						(else
						 (if (not (member 'header (my 'preamble-state)))
							  (begin
								 (if (and (pair? il)
											 (null? (cdr il))) ;; agent name
																	 ;; comes first
													             ;; since it is
																	 ;; easy to prune
																	 ;; the first line
									  (begin
										 (display (string-append "# " (name (car il))) file)
										 (newline file)))
							  
								 (let ((header 
										  (if missing-val
												(my 'variables)
												(let loop ((all-vars '())
															  (entities il))
												  (if (null? entities)
														(intersection
														 (uniq
														  (map
															string->symbol
															(sort (map symbol->string
																		  all-vars)
																	string<?)))
														 (my 'variables))
														(loop
														 (append
														  (map car
																 (class-slots-of (car entities)))
														  (extra-variable-list (car entities))
														  all-vars) (cdr entities))))
												)
										  ))
									(display "# " file)
									(for-each
									 (lambda (x) (display " " file) (display x file))
									 header)
									(newline file))
								 (set-my! 'preamble-state
											 (cons 'header (my 'preamble-state)))
								 )
							  )
						 )
						)
					 )
				  
				  (kdebug 'logfile-issues "Out: log-data, after logfile preamble filename " (my 'filename) "and file" (my 'file))
				  
				  )
						
(model-method (<log-data> <log-introspection> <symbol> <list>) (log-data self logger format target-variables)
				  ;; (error "(-: Oops, really ought to never get here. :-)")
				  (kdebug '(log-* log-data) (name self) "[" (my 'name) ":"
							(class-name-of self) "]" "in log-data")
				  (let ((file (my 'file))
						  (show-field-name (my 'show-field-name))
						  (subjects (my-list self))
						  (target-variables (my 'variables))
						  (missing-val (my 'missing-val))
						  )
					 (for-each (lambda (subject) 
									 (display "**" file)
									 (for-each ;; field in the variable list
									  (lambda (field)
										 (if show-field-name
											  (begin
												 (display " " file)
												 (display field file)))

										 (cond
										  ((member field
													  (map car
															 (class-slots-of subject)))
											(kdebug '(log-* log-data logging-debug)
													 "     Dumping " field "="
													 (if (has-slot? self t)
														  (slot-ref self t)
														  "missing!"))
												 
											(display " " file)
											(display (slot-ref subject field) file)
											)
										  ((member field (extra-variable-list subject))
											(display " " file)
											(display (extra-variable subject field) file)
											)
										  (missing-val
											(display " " file)
											(display missing-val file)))
										 )
									  (if DONT-FILTER-TARGET-VARIABLES
											target-variables
											(filter (not-member (my 'dont-log)) target-variables)))
									 (newline file)
									 )
								  subjects)
					 )
				  )


(model-method (<log-data> <log-introspection> <symbol>) (page-epilogue self logger format)
				  (kdebug '(log-* log-data) (name self) "[" (my 'name) ":"
							(class-name-of self) "]" "in page-epilogue")
				  (let ((ml (my-list self)))
					 (if (and (pair? ml)
								 (pair? (cdr ml)))
						  (or #t (newline (my 'file))))
					 ;; We don't want a blank line between each record!
					 ;; -- change #t to #f to get lines between "pages"
					 )
				  )


;-  The End 


;; Local Variables:
;; mode: scheme
;; outline-regexp: ";-+"
;; comment-column:0
;; comment-start: ";; "
;; comment-end:"" 
;; End:
