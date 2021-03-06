(defpackage #:qi-setup
  (:use #:cl))
(in-package #:qi-setup)

;; Code:

(defvar +qi-directory+ (merge-pathnames ".qi/" (user-homedir-pathname)))
(defvar +qi-manifest+ (merge-pathnames ".manifest.lisp" +qi-directory+))
(defvar +qi-qache+ (merge-pathnames "cache/" +qi-directory+))
(defvar +qi-asdf+ (merge-pathnames "asdf/asdf.lisp" +qi-directory+))
(defvar +qi.asd+ (merge-pathnames "src/qi.asd" +qi-directory+))
(defvar +qi.lisp+ (merge-pathnames "src/qi.lisp" +qi-directory+))
(defvar +qi-dependencies+ (merge-pathnames "dependencies/" +qi-directory+))

(defun ensure-asdf-loaded () ;; taken from quicklisp's resolver here
  "Try several methods to make sure that a sufficiently-new ASDF is
loaded: first try (require 'asdf), then loading the ASDF FASL, then
compiling asdf.lisp to a FASL and then loading it."
  (let* ((source (merge-pathnames ".qi/asdf.lisp" (user-homedir-pathname))))
    (labels ((asdf-symbol (name)
               (let ((asdf-package (find-package '#:asdf)))
                 (when asdf-package
                   (find-symbol (string name) asdf-package))))
             (version-satisfies (version)
               (let ((vs-fun (asdf-symbol '#:version-satisfies))
                     (vfun (asdf-symbol '#:asdf-version)))
                 (when (and vs-fun vfun
                            (fboundp vs-fun)
                            (fboundp vfun))
                   (funcall vs-fun (funcall vfun) version)))))
      (block nil
        (macrolet ((try (&body asdf-loading-forms)
                     `(progn
                        (handler-bind ((warning #'muffle-warning))
                          (ignore-errors
                            ,@asdf-loading-forms))
                        (when (version-satisfies "3.0")
                          (return t)))))
          (try)
          (try (require 'asdf))
          (try (load (compile-file source :verbose nil :output-file (merge-pathnames "asdf.fasl" +qi-qache+))))
          (error "Could not load ASDF ~S or newer" "3.0"))))))

(ensure-asdf-loaded)

(defun push-new-to-registry (what)
  (setf asdf:*central-registry* (pushnew what asdf:*central-registry*)))

(let ((deps-to-load (directory (concatenate 'string (namestring +qi-dependencies+) "**"))))
  (setf asdf:*central-registry* nil)
  (push-new-to-registry +qi-directory+)
  (loop for d in deps-to-load do
       (push-new-to-registry d)))

(print asdf:*central-registry*)
(asdf:oos 'asdf:load-op 'qi)
(print "ASDF loaded - Qi loaded")
