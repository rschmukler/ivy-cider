;;; ivy-cider.el -- Ivy Interface to cider

;; Copyright (C) 2020 Ryan Schmukler

;; Author: Ryan Schmukler <ryan@teknql.com>
;; Package-Requires: ((emacs "24.4") (cider "0.16") (ivy "0.12.0") (ivy-rich "0.1.6") (seq "2.20")
;;                    (all-the-icons "3.2.0"))
;; Keywords: cider, clojure, ivy, languages
;; URL: https://github.com/rschmukler/ivy-cider
;; Version: 0.0.1

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

;; For more about Ivy, see: https://github.com/abo-abo/swiper
;; For more about CIDER, see: https://github.com/clojure-emacs/cider

;;; Code:


(require 'ivy)
(require 'ivy-rich)
(require 'cider)
(require 'seq)
(require 'all-the-icons)

(defvar ivy-cider--active-apropos
  nil
  "Variable holding the current apropos results.")

(defun ivy-cider--rich-apropos-short-name (c)
  "Return the name of the apropos candidate C within the namespace."
  (car (last (split-string c "/"))))

(defun ivy-cider--rich-apropos-namespace (c)
  "Return the namespace of the apropos candidate C."
  (let ((parts (split-string c "/")))
    (if (equal 2 (length parts))
      (car parts)
      "")))

(defun ivy-cider--rich-apropos-doc (c)
  "Return the associated documentation of the apropos candidate C."
  (nrepl-dict-get
   (cdr (assoc c ivy-cider--active-apropos))
   "doc" ""))

(defun ivy-cider--rich-apropos-type (c)
  "Return the type of the apropos candidate C."
  (nrepl-dict-get
   (cdr (assoc c ivy-cider--active-apropos))
   "type"
   ""))

(defun ivy-cider--rich-apropos-type-icon (c)
  "Return an all-the-icon icon for apropos candidate C."
  (pcase (ivy-cider--rich-apropos-type c)
    ("function" (all-the-icons-material "code" :face 'all-the-icons-red))
    ("macro" (all-the-icons-material "build" :face 'all-the-icons-blue))
    ("variable" (all-the-icons-material "edit" :face 'all-the-icons-green))
    ("special-form" (all-the-icons-material "extension" :face 'all-the-icons-orange))))

(plist-put
 ivy-rich-display-transformers-list
 'ivy-cider-apropos
 '(:columns
   (((lambda (_) " ") (:width 1))
    (ivy-cider--rich-apropos-type-icon (:width 2 :align right))
    (ivy-cider--rich-apropos-short-name (:width 0.15))
    (ivy-cider--rich-apropos-doc (:width 0.55 :face font-lock-doc-face))
    (ivy-cider--rich-apropos-namespace (:width 0.11 :align right)))))

;;;###autoload
(defun ivy-cider-apropos (&optional ns)
  "Open an ivy prompt to search for all loaded vars.

  Optionally takes a NS string which can be used to filter candidates."
  (interactive)
  (let* ((results (cider-sync-request:apropos ""))
         (candidates (mapcar
                      (lambda (x) (nrepl-dict-get x "name"))
                      results))
         (filtered-candidates (if ns
                                  (seq-filter
                                   (lambda (x)
                                     (equal ns (ivy-cider--rich-apropos-namespace x)))
                                   candidates)
                                candidates))
         (active-apropos (mapcar
                          (lambda (x)
                            (cons (nrepl-dict-get x "name")
                                  x))
                          results))
         (ivy-cider--active-apropos active-apropos))
    (ivy-read "Apropos: " filtered-candidates
              :caller 'ivy-cider-apropos
              :action 'cider-doc-lookup)))

;;;###autoload
(defun ivy-cider-browse-ns ()
  "Open an ivy prompt to search for namespaces within the project."
  (interactive)
  (cider-ensure-connected)
  (ivy-read "Browse namespace: " (cider-sync-request:ns-list)
            :action 'ivy-cider-apropos))

(when ivy-rich-mode
  (ivy-rich-mode -1)
  (ivy-rich-mode 1))

(provide 'ivy-cider)
;;; ivy-cider.el ends here
