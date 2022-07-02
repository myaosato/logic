(defpackage :claudia/meta-data/interface
  (:use :cl
        :claudia/meta-data/meta-data
        :claudia/meta-data/term
        :claudia/meta-data/formula
        :claudia/meta-data/parser)
  (:export :meta-data
           :== :<- :<-able :free-p
           :term :term-list
           :var :var-name
           :const :const-name
           :func :func-terms
           :formula :formula-list
           :∧ :∧-1 :∧-2
           :∨ :∨-1 :∨-2
           :¬ :¬-1
           :→ :→-1 :→-2
           :∀ :∀-var :∀-formula
           :∃ :∃-var :∃-formula
           :prop :prop-name
           :predicate :predicate-terms
           :terms
           :formulas))
(in-package :claudia/meta-data/interface)
