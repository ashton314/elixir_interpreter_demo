#lang racket

(define (builtin? x) (member x '(+ * / - = zero? say)))

(define (translate expr)
  (match expr
    [(? symbol? n) (format ":~a" expr)]
    [(? number? n) (format "~a" n)]
    [(? boolean? n) (format "~a" (if n 'true 'false))]
    [`(,(? builtin? op) ,e ...)
     (format "{:~a, ~a}" op (string-join (map translate e) ", "))]
    [`(if ,c ,tc ,fc)
     (format "{:if, ~a, ~a, ~a}" (translate c) (translate tc) (translate fc))]
    [`(λ (,xs ...) ,body)
     (format "{:lambda, [~a], ~a}" (string-join (map translate xs) ", ") (translate body))]
    [`(lambda (,xs ...) ,body)
     (format "{:lambda, [~a], ~a}" (string-join (map translate xs) ", ") (translate body))]
    [`(,f ,es ...)
     (format "{:app, ~a, [~a]}" (translate f) (string-join (map translate es) ", "))]))

;; Y-Combinator
(define Y (λ (f) ((λ (x) (f (λ (n) ((x x) n))))
                   (λ (x) (f (λ (n) ((x x) n)))))))

;; Factorial defined thusly
(define fact (Y (λ (f) (λ (n) (if (= n 0) 1 (* n (f (- n 1))))))))
