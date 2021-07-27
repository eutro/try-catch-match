#lang racket/base

(provide try catch finally)

(require racket/match (for-syntax syntax/parse racket/base))

(begin-for-syntax
  (define ((invalid-expr name) stx)
    (raise-syntax-error name "invalid in expression context" stx)))

(define-syntax catch (invalid-expr 'catch))
(define-syntax finally (invalid-expr 'finally))

(begin-for-syntax
  (define-syntax-class catch-clause
    #:description "catch clause"
    #:literals [catch]
    (pattern (catch binding:expr body:expr ...+)))

  (define-syntax-class finally-clause
    #:description "finally clause"
    #:literals [finally]
    (pattern (finally body:expr ...+)))

  (define-syntax-class body-expr
    #:literals [catch finally]
    (pattern (~and :expr
                   (~not (~or (finally . _)
                              (catch . _)))))))

(define-syntax (try stx)
  (syntax-parse stx
    [(_ body:body-expr ...+)
     #'(let () body ...)]
    [(_ body:body-expr ...+
        catch:catch-clause ...
        finally:finally-clause)
     #'(call-with-continuation-barrier
        (lambda ()
         (dynamic-wind
           void
           (lambda ()
             (try body ... catch ...))
           (lambda ()
             finally.body ...))))]
    [(_ body:body-expr ...+
        catch:catch-clause ...)
     #'(with-handlers
         ([void
           (lambda (e)
             (match e
               [catch.binding catch.body ...] ...
               [_ (raise e)]))])
         body ...)]))
