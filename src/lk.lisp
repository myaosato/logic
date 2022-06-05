(defpackage :logic/lk
  (:use :cl
        :logic/formula
        :logic/sequent
        :logic/goal
        :logic/axiom)
  (:export :id :cut
           :and-l1 :and-l2 :and-r
           :or-l :or-r1 :or-r2
           :not-l :not-r
           :to-l :to-r
           :wl :wr
           :cl :cr
           :pl :pr))
(in-package :logic/lk)

;; ****************************************************************
;; LK
;;
;; ref. https://ja.wikipedia.org/wiki/シークエント計算
;;
;; WIP: implemented propositional logic part only.
;; TODO
;; - ∀
;; - ∃
;; ****************************************************************

;; axiom of LK
;; ------
;; A  ⊢ A
(def-axiom id (seq)
  (and (= (length-l seq) 1)
       (= (length-r seq) 1)
       (equal (nth-l 0 seq) (nth-r 0 seq))))

;; Cut
;; Γ ⊢ A,Δ  A,Σ ⊢ Π
;; -----------------
;; Γ,Σ ⊢ Δ,Π
(defun cut (seq a n m)
  (with-splited-sequent seq (n m g s d p)
    (make-goal (make-sequent g (cons a d))
               (make-sequent (cons a s) p))))

;; And
;; A,Γ ⊢ Δ          B,Γ ⊢ Δ          Γ ⊢ A,Δ  Σ ⊢ B,Π
;; ---------(∧L1)   ---------(∧L2)   ----------------(∧R)
;; A∧B,Γ ⊢ Δ        A∧B,Γ ⊢ Δ        Γ,Σ ⊢ A∧B,Δ,Π 
(defun and-l (seq op)
  (let ((focus (nth-l 0 seq)))
    (if (is-∧ focus)
        (make-goal (make-sequent (cons (funcall op focus) (cdr (l seq)))
                                 (r seq)))
        (error ""))))

(defun and-l1 (seq)
  (and-l seq #'∧-1))

(defun and-l2 (seq)
  (and-l seq #'∧-2))

(defun and-r (seq n m)
  (let ((f (nth-r 0 seq)))
    ;; TODO (rest (r seq)) => (rest-r seq)
    (with-splited-sequent (cons (l seq) (rest (r seq))) (n (1- m) g s d p)
      (if (is-∧ f)
          (make-goal (make-sequent g (cons (∧-1 f) d))
                     (make-sequent s (cons (∧-2 f) p)))
          (error "")))))

;; Or
;; Γ ⊢ A,Δ          Γ ⊢ B,Δ          A,Γ ⊢ Δ  B,Σ ⊢ Π
;; ---------(∨R1)   ---------(∨R2)   ----------------(∨L)
;; Γ ⊢ A∨B,Δ        Γ ⊢ A∨B,Δ        A∨B,Γ,Σ ⊢ Δ,Π 
(defun or-r (seq op)
  (let ((focus (nth-r 0 seq)))
    (if (is-∨ focus)
        (make-goal (make-sequent (l seq)
                                 (cons (funcall op focus) (cdr (r seq)))))
        (error ""))))

(defun or-r1 (seq)
  (or-r seq #'∨-1))

(defun or-r2 (seq)
  (or-r seq #'∨-2))

(defun or-l (seq n m)
  (let ((f (nth-l 0 seq)))
    ;; TODO (rest (l seq)) => (rest-l seq)
    (with-splited-sequent (cons (rest (l seq)) (r seq)) ((1- n) m g s d p)
      (if (is-∨ f)
          (make-goal (make-sequent (cons (∨-1 f) g) d)
                     (make-sequent (cons (∨-2 f) s) p))
          (error "")))))

;; Not
;; Γ ⊢ A,Δ       A,Γ ⊢ Δ
;; --------(¬L)  ---------(¬R)
;; ¬A,Γ ⊢ Δ      Γ ⊢ ¬A,Δ
(defun not-l (seq)
  (let ((focus (nth-l 0 seq)))
    (if (is-¬ focus)
        (make-goal (make-sequent (cdr (l seq))
                                 (cons (¬-1 focus) (r seq))))
        (error ""))))

(defun not-r (seq)
  (let ((focus (nth-r 0 seq)))
    (if (is-¬ focus)
        (make-goal (make-sequent (cons (¬-1 focus) (l seq))
                                 (cdr (r seq))))
        (error ""))))

;; To
;; A,Γ ⊢ B,Δ      Γ ⊢ A,Δ  B,Σ ⊢ Π
;; ---------(¬R)  ----------------(¬L)  
;; Γ ⊢ A→B,Δ      A→B,Γ,Σ ⊢ Δ,Π
(defun to-r (seq)
  (let ((focus (nth-r 0 seq)))
    (if (is-→ focus)
        (make-goal (make-sequent (cons (→-1 focus) (l seq))
                                 (cons (→-2 focus) (cdr (r seq)))))
      (error ""))))

(defun to-l (seq n m)
  (let ((f (nth-l 0 seq)))
    ;; TODO (rest (l seq)) => (rest-l seq)
    (with-splited-sequent (cons (rest (l seq)) (r seq)) ((1- n) m g s d p)
      (if (is-→ f)
          (make-goal (make-sequent g (cons (→-1 f) d))
                     (make-sequent (cons (→-2 f) s) p))
          (error "")))))

;; Weakening
;; Γ ⊢ Δ         Γ ⊢ Δ
;; -------(WL)  ---------(WR)
;; A,Γ ⊢ Δ       Γ ⊢ A,Δ
(defun wl (seq)
  (if (>= (length-l seq) 1)
      (make-goal (make-sequent (cdr (l seq)) (r seq)))
      (error "")))

(defun wr (seq)
  (if (>= (length-r seq) 1)
      (make-goal (make-sequent (l seq) (cdr (r seq))))
      (error "")))

;; Contraction
;; A,A,Γ ⊢ Δ      Γ ⊢ A,A,Δ
;; ---------(CL)  ---------(CR)
;; A,Γ ⊢ Δ        Γ ⊢ A,Δ
(defun cl (seq)
  (if (>= (length-l seq) 1)
      (make-goal (make-sequent (cons (nth-l 0 seq) (l seq)) (r seq)))
      (error "")))

(defun cr (seq)
  (if (>= (length-r seq) 1)
      (make-goal (make-sequent (l seq) (cons (nth-r 0 seq) (r seq))))
      (error "")))


;; Permutation
;; Γ0,..Γm,..Γn,.. ⊢ Δ      Γ ⊢ Δ0,..Δm,..Δn,..
;; -------------------(PL)  -------------------(CR)
;; Γ0,..Γn,..Γm,.. ⊢ Δ      Γ ⊢ Δ0,..Δn,..Δm,..
(defun pl (seq n m)
  (if (> (length-l seq) (max m n))
      (let ((l (subseq (l seq) 0)))
        (rotatef (nth n l) (nth m l))
        (make-goal (make-sequent l (r seq))))
      (error "")))

(defun pr (seq n m)
  (if (> (length-r seq) (max m n))
      (let ((r (subseq (r seq) 0)))
        (rotatef (nth n r) (nth m r))
        (make-goal (make-sequent (l seq) r)))
      (error "")))

