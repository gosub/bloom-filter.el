;;; bloom-filter.el --- An implementation of Bloom filters in elisp

;; Copyright (C) 2013 Giampaolo Guiducci

;; Author: Giampaolo Guiducci <stirner@gmail.com>
;; Version: 0.1.0
;; Keywords: bloom, filter, probabilistic, data structures

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; An implementation of Bloom filters in elisp.
;; A Bloom filter is a space efficient, probabilistic data structure
;; that is used to test if an element is a member of a set.
;; False positive are possible, false negatives are not.
;;
;; See http://en.wikipedia.org/wiki/Bloom_filter

;;; Code:

(require 'cl)

(defun make-bloom-filter (filter-size hash-funs-num)
  "Return a new, empty, bloom filter."
  (vector
   'bloom-filter
   filter-size
   hash-funs-num
   (make-bool-vector filter-size nil)))


(defun bloom-filter-p (bloom-filter)
  "Return t if argument is a bloom-filter."
  (and (vectorp bloom-filter)
       (= (length bloom-filter) 4)
       (eq 'bloom-filter (aref bloom-filter 0))))


(defun bloom-filter-size (bloom-filter)
  "Return the size of the boolean vector in the bloom filter."
  (aref bloom-filter 1))


(defun bloom-filter-hash-funs-num (bloom-filter)
  "Return the number of hash functions used to set and query
membership of an element to the set."
  (aref bloom-filter 2))


(defun bloom-filter-vector (bloom-filter)
  "Return the bare boolean vector of the bloom filter."
  (aref bloom-filter 3))


(defun bloom-filter-k-indexes (obj k n)
  "Return a list of k integers (mod n), produced 
by applying k different hash functions to the 
first argument."
  (let ((indexes (list))
	(last-hash (sxhash (prin1-to-string obj))))
    (dotimes (i k)
      (setq indexes
	    (cons last-hash indexes))
      (setq last-hash
 	    (sxhash (number-to-string last-hash))))
    (mapcar (lambda (x) (mod x n)) indexes)))


(defun bloom-filter-add (obj bloom-filter)
  "Add an element to the set (bloom-filter)."
  (let* ((n (bloom-filter-size bloom-filter))
	 (k (bloom-filter-hash-funs-num bloom-filter))
	 (bv (bloom-filter-vector bloom-filter))
	 (idxs (bloom-filter-k-indexes obj k n)))
    (dolist (idx idxs bloom-filter)
      (aset bv idx t))))


(defun bloom-filter-query (obj bloom-filter)
  "Test if an element is a member of the set (bloom-filter)."
  (let* ((n (bloom-filter-size bloom-filter))
	 (k (bloom-filter-hash-funs-num bloom-filter))
	 (bv (bloom-filter-vector bloom-filter))
	 (idxs (bloom-filter-k-indexes obj k n)))
    (every (lambda (i) (aref bv i)) idxs)))


(defun bloom-filters-map2 (fn bf1 bf2)
  "Given two bloom filters with the same size and number of
hash functions, produce a new bloom filter where each nth element
of the boolean array is (fn e1 e2), where e1 and e2 are the nth
element of the initial filters."
  (let ((n (bloom-filter-size bf1))
	(k (bloom-filter-hash-funs-num bf1)))
    (assert (= n (bloom-filter-size bf2)))
    (assert (= k (bloom-filter-hash-funs-num bf2)))
    (let* ((v1 (bloom-filter-vector bf1))
	   (v2 (bloom-filter-vector bf2))
	   (new-bf (make-bloom-filter n k))
	   (new-v (bloom-filter-vector new-bf)))
      (dotimes (i n)
	(aset new-v i (funcall fn (aref v1 i)
			       (aref v2 i))))
      new-bf)))


(defun bloom-filters-union (bf1 bf2)
  "Given two bloom filters, return a new bloom filter which
represents the union of the two sets."
  (bloom-filters-map2 
   (lambda (a b) (or a b)) bf1 bf2))


(defun bloom-filters-intersection (bf1 bf2)
  "Given two bloom filters, return a new bloom filter which
represents the intersection of the two sets."
  (bloom-filters-map2 
   (lambda (a b) (and a b)) bf1 bf2))


(defun list-to-bloom-filter (list filter-size hash-funs-num)
  "Return a new bloom-filter with the elements of the list added in."
  (let ((bf (make-bloom-filter filter-size hash-funs-num)))
    (dolist (elt list bf)
      (bloom-filter-add elt bf))))


;; ----------------------------------------------------------------
;;                          Tests


(defun bloom-filter-test-add-query ()
  (let ((bf (make-bloom-filter 512 4))
	(in (list 0 1.0 'symbol '(1 2 3) [4 5 6] "test"))
	(out (list 1 0.0 'another '(4 5 6) [1 2 3] "TEST")))
    (dolist (elt in 'nil)
      (bloom-filter-add elt bf))
    (and
     (every (lambda (x) (bloom-filter-query x bf)) in)
     (every (lambda (x) (not (bloom-filter-query x bf))) out))))

(defun bloom-filter-test-list-to-bloom ()
  (let* ((in '(0 1 2 3 4 5))
	 (out '(6 7 8 9 10 11))
	 (bf (list-to-bloom-filter in 512 4)))
    (and
     (every (lambda (x) (bloom-filter-query x bf)) in)
     (every (lambda (x) (not (bloom-filter-query x bf))) out))))


(defun bloom-filter-test-union ()
  (let* ((n 512) (k 4)
	 (set1 '(0 1 2 3 4 5 6))
	 (set2 '(7 8 9 10 11 12 13))
	 (bf1 (list-to-bloom-filter set1 n k))
	 (bf2 (list-to-bloom-filter set2 n k))
	 (union (bloom-filters-union bf1 bf2)))
    (and
     (every (lambda (x) (bloom-filter-query x union)) set1)
     (every (lambda (x) (bloom-filter-query x union)) set2))))


(defun bloom-filter-test-intersection ()
  (let* ((n 512) (k 4)
	 (set1 (list 0 1 2 3 4 5 6 7 8))
	 (set2 (list 6 7 8 9 10 11 12))
	 (interset (list 6 7 8))
	 (not-interset (list 0 1 2 3 4 5 9 10 11 12))
	 (bf1 (list-to-bloom-filter set1 n k))
	 (bf2 (list-to-bloom-filter set2 n k))
	 (intersection (bloom-filters-intersection bf1 bf2)))
    (and
     (every (lambda (x) 
	      (bloom-filter-query x intersection)) 
	    interset)
     (every (lambda (x) 
	      (not (bloom-filter-query x intersection)))
	    not-interset))))


(defun bloom-filter-run-tests ()
  (and
   (bloom-filter-test-add-query)
   (bloom-filter-test-list-to-bloom)
   (bloom-filter-test-union)
   (bloom-filter-test-intersection)))

(bloom-filter-run-tests)


(provide 'bloom-filter)

;;; bloom-filter.el ends here
