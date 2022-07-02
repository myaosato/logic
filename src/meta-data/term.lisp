(defpackage :claudia/meta-data/term
  (:use :cl
        :claudia/meta-data/meta-data)
  (:export :term :term-list
           :var :var-name
           :const :const-name
           :func :terms))
(in-package :claudia/meta-data/term)

;; ****************************************************************
;; meta data type
;;
;; func := name terms*
;; term := const | var | func
;;
;; ****************************************************************
(defclass term (meta-data)
  nil)
(defun term-list-p (thing)
  (and (listp thing)
       (every (lambda (x) (typep x 'term)) thing)))
(deftype term-list ()
  `(satisfies term-list-p))

;; var
(defclass var (term)
  ((name :initarg :name :reader var-name)))
(defmethod initialize-instance :after ((term var) &key)
  (setf (%free-vars term) (list term)))
(defun var (name)
  (make-instance 'var :name name))
(defmethod <- ((place var) (var var) (term term))
  (if (eq place var)
      term
      place))
(defmethod == ((a var) (b meta-data))
  (and (typep b 'var)
       (eq a b)))

;; const
(defclass const (term)
  ((name :initarg :name :reader const-name)))
(defun const (name)
  (make-instance 'const :name name))
(defmethod <- ((place const) (var var) (term term))
  place)
(defmethod == ((a const) (b meta-data))
  (and (typep b 'const)
       (eq a b)))

;; func
(defclass func (term)
  ((terms :initarg :terms :reader terms :type term-list)))
(defun func (&rest terms)
  (make-instance 'func :terms terms))
(defmethod initialize-instance :after ((term func) &key)
  (setf (%free-vars term) (reduce #'union (mapcar #'free-vars (terms term)))))
(defmethod <- ((place func) (var var) (term term))
  (apply #'func
         (mapcar (lambda (x) (<- x var term)) (terms place))))
(defmethod == ((a func) (b meta-data))
  (and (typep b 'func)
       (every #'== (terms a) (terms b))))

;; term is substitutable
(defmethod <-able ((place term) (var var) (term term))
  t)


;; ----------------------------------------

(defmethod print-object ((term term) stream)
  (declare (ignore stream))
  (error "print-object method for type ~A is not defined" (type-of term)))
(defmethod print-object ((term var) stream)
  (format stream "~A" (name term)))
(defmethod print-object ((term  const) stream)
    (format stream "~A" (name term)))
(defmethod print-object ((term func) stream)
  (format stream "(~A ~{~A~^ ~})" 'func (terms term)))
