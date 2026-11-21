(defparameter *scale* "@%#*+=-:. ")

(defun space-character-p (character)
  (or (find character '(#\Space #\Tab #\Newline #\Return #\Page))
      (char= character (code-char 11))))

(defun next-token (stream)
  (loop for character = (peek-char nil stream nil nil)
        while character
        do (cond
             ((space-character-p character) (read-char stream))
             ((char= character #\#) (read-line stream nil nil))
             (t (return-from next-token
                  (with-output-to-string (token)
                    (loop for value = (peek-char nil stream nil nil)
                          while (and value (not (space-character-p value))
                                     (not (char= value #\#)))
                          do (write-char (read-char stream) token))))))))

(defun next-integer (stream)
  (let ((token (next-token stream)))
    (unless (and token (> (length token) 0)
                 (every (lambda (character) (digit-char-p character 10)) token))
      (error "Expected an unsigned decimal integer"))
    (parse-integer token)))

(defun convert-image (input output)
  (unless (equal (next-token input) "P2") (error "Expected PGM P2"))
  (let ((width (next-integer input))
        (height (next-integer input))
        (maximum (next-integer input)))
    (unless (and (> width 0) (> height 0) (<= 1 maximum 65535))
      (error "Invalid dimensions or maximum brightness"))
    (dotimes (row height)
      (dotimes (column width)
        (let ((pixel (next-integer input)))
          (unless (<= pixel maximum) (error "Pixel exceeds maximum brightness"))
          (write-char (char *scale* (floor (* pixel (1- (length *scale*))) maximum)) output)))
      (terpri output))
    (when (next-token input) (error "Unexpected data after pixels"))))

(defun run (arguments)
  (unless (= (length arguments) 2)
    (error "Usage: sbcl --script main.lisp <input.pgm> <output.txt>"))
  (let* ((destination (merge-pathnames (second arguments)))
         (temporary (make-pathname :name (format nil ".pgm-~A" (gensym))
                                   :type "tmp" :defaults destination))
         (created nil))
    (unwind-protect
         (progn
           (with-open-file (input (first arguments) :direction :input :external-format :utf-8)
             (with-open-file (output temporary :direction :output :if-exists :error
                                     :if-does-not-exist :create :external-format :utf-8)
               (setf created t)
               (convert-image input output)))
           (rename-file temporary destination))
      (when (and created (probe-file temporary)) (delete-file temporary)))))

(handler-case (run (cdr sb-ext:*posix-argv*))
  (error (condition)
    (format *error-output* "Error: ~A~%" condition)
    (sb-ext:exit :code 1)))
