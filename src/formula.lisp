(defpackage :claudia/formula
  (:use :cl
        :claudia/term
        :claudia/pprint)
  (:export :formula :formula-list
           :∧ :∧-1 :∧-2
           :∨ :∨-1 :∨-2
           :¬ :¬-1
           :→ :→-1 :→-2
           :prop
           :predicate :def-predicate :constructor
           :substitute))
(in-package :claudia/formula)

;; ****************************************************************
;; meta data type
;;
;; const := const-val | func const*
;; term := const | var | func term*
;; atomic := prop | predicate term*
;; formula := formula ∧ formula | formula ∨ formula | ¬ formula | atomic
;;
;; ****************************************************************
(defclass formula nil
  ((free-vars :initarg :free-vars :initform nil :accessor %free-vars :reader free-vars)))
(defmethod print-object ((formula formula) stream)
  (declare (ignore stream))
  (error "print-object method for type ~A is not defined" (type-of formula)))
(defmacro def-print-formula ((formula class) control-string &rest format-arguments)
  (let ((stream (gensym "STREAM")))
    `(defmethod print-object ((,formula ,class) ,stream)
       (format ,stream ,control-string ,@format-arguments))))
(defmethod pprint-formula ((formula formula) stream)
  (declare (ignore stream))
  (error "pprint-formula method for type ~A is not defined" (type-of formula)))
(def-claudia-print (formula) (formula stream)
  (pprint-formula formula stream))
(defun formula-list-p (thing)
  (and (listp thing)
       (every (lambda (x) (typep x 'formula)) thing)))
(deftype formula-list ()
  `(satisfies formula-list-p))
(defmethod substitute ((place formula) var term)
  (error "substitute method for type ~A is not defined" (type-of place)))

;; ∧
(defclass ∧ (formula)
  ((∧-1 :initarg :∧-1 :reader ∧-1 :type formula)
   (∧-2 :initarg :∧-2 :reader ∧-2 :type formula)))
(defun ∧ (f1 f2)
  (make-instance '∧ :∧-1 f1 :∧-2 f2))
(def-print-formula (formula ∧) "(~A ~A ~A)" '∧ (∧-1 formula) (∧-2 formula))
(defmethod pprint-formula ((formula ∧) stream)
  (format stream "(~A ∧ ~A)" (pprint-formula (∧-1 formula) nil) (pprint-formula (∧-2 formula) nil)))
(defmethod initialize-instance :after ((formula ∧) &key)
  (setf (%free-vars formula) (union (free-vars (∧-1 formula)) (free-vars (∧-2 formula)))))
(defmethod substitute ((place ∧) (var var) (term term))
  (∧ (substitute (∧-1 place) var term) (substitute (∧-2 place) var term)))

;; ∨
(defclass ∨ (formula)
  ((∨-1 :initarg :∨-1 :reader ∨-1 :type formula)
   (∨-2 :initarg :∨-2 :reader ∨-2 :type formula)))
(defun ∨ (f1 f2)
  (make-instance '∨ :∨-1 f1 :∨-2 f2))
(def-print-formula (formula ∨) "(~A ~A ~A)" '∨ (∨-1 formula) (∨-2 formula))
(defmethod pprint-formula ((formula ∨) stream)
  (format stream "(~A ∨ ~A)" (pprint-formula (∨-1 formula) nil) (pprint-formula (∨-2 formula) nil)))
(defmethod initialize-instance :after ((formula ∨) &key)
  (setf (%free-vars formula) (union (free-vars (∨-1 formula)) (free-vars (∨-2 formula)))))
(defmethod substitute ((place ∨) (var var) (term term))
  (∨ (substitute (∨-1 place) var term) (substitute (∨-2 place) var term)))

;; ¬
(defclass ¬ (formula)
  ((¬-1 :initarg :¬-1 :reader ¬-1 :type formula)))
(defun ¬ (f)
  (make-instance '¬ :¬-1 f))
(def-print-formula (formula ¬) "(~A ~A)" '¬ (¬-1 formula))
(defmethod pprint-formula ((formula ¬) stream)
  (format stream "¬~A" (pprint-formula (¬-1 formula) nil)))
(defmethod initialize-instance :after ((formula ¬) &key)
  (setf (%free-vars formula) (free-vars (¬-1 formula))))

;; →
(defclass → (formula)
  ((→-1 :initarg :→-1 :reader →-1 :type formula)
   (→-2 :initarg :→-2 :reader →-2 :type formula)))
(defun → (f1 f2)
  (make-instance '→ :→-1 f1 :→-2 f2))
(def-print-formula (formula →) "(~A ~A ~A)" '→ (→-1 formula) (→-2 formula))
(defmethod pprint-formula ((formula →) stream)
  (format stream "(~A → ~A)" (pprint-formula (→-1 formula) nil) (pprint-formula (→-2 formula) nil)))
(defmethod initialize-instance :after ((formula →) &key)
  (setf (%free-vars formula) (union (free-vars (→-1 formula)) (free-vars (→-2 formula)))))
(defmethod substitute ((place →) (var var) (term term))
  (→ (substitute (→-1 place) var term) (substitute (→-2 place) var term)))


;;;; atomic
(defclass atomic (formula) nil)

;; prop
(defclass prop (atomic)
  ((name :initarg :name :reader name)))
(defun prop (name)
  (make-instance 'prop :name name))
(def-print-formula (formula prop) "#<Prop: ~A>" (name formula))
(defmethod pprint-formula ((formula prop) stream)
  (format stream "~A" (name formula)))
(defmethod substitute ((place prop) (var var) (term term))
  place)

;; predicate
(defclass predicate (atomic)
  ((name :initarg :name :reader name)
   (terms :initarg :terms :reader terms :type (vector term *))
   (constructor :initarg :constructor :reader constructor)))
(defmacro def-predicate (name arity)
  (declare (type symbol name))
  (let ((c (gensym "CONSTRUCTOR-")))
    `(labels ((,c (name constructor &rest terms)
                (make-instance 'predicate
                               :name name
                               :terms (coerce terms '(vector term ,arity))
                               :constructor constructor)))
       (defun ,name (&rest terms) (apply #',c ',name #',c terms)))))
(def-print-formula (formula predicate) "(~A ~{~A~^ ~})" (name formula) (coerce (terms formula) 'list))
(defmethod pprint-formula ((formula predicate) stream)
  (format stream "~A(~{~:W~^ ~})" (name formula) (coerce (terms formula) 'list)))
(defmethod initialize-instance :after ((formula predicate) &key)
  (setf (%free-vars formula) (reduce #'union (mapcar #'free-vars (coerce (terms formula) 'list)))))
(defmethod substitute ((place predicate) (var var) (term term))
  (apply (constructor place)
         (mapcar (lambda (x) (substitute x var term)) (terms place))))
