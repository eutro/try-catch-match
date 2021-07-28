#lang scribble/manual

@(require scribble/example (for-label racket/base racket/match try-catch-match))

@title{try-catch-match}
@author{Benedek Szilvasy}

@(define ev (make-base-eval '(require try-catch-match)))

@defmodule[try-catch-match]{A try-catch-finally macro that binds with match.}

@defform[#:literals [catch finally]
         (try body ...+ catch-clause ... maybe-finally-clause)
         #:grammar ([catch-clause (catch pat body ...+)]
                    [maybe-finally-clause (code:line)
                                          (finally body ...+)])]
@racket[try] to evaluate @racket[body] expressions, returning the last one on success.

If an exception is @racket[raise]d, then attempt to @racket[match] one of the @racket[pat]s
in the @racket[catch] clauses, returning the result of its @racket[body].
If none of them match, the exception is re-raised.

If there is a @racket[finally] clause present, it will be executed when exiting the body,
through a normal return, uncaught exception or a continuation.

@defsubform[(catch pat body ...+)]
A @racket[catch] clause, executes and returns @racket[body] if @racket[pat] matches a raised exception.

@defsubform[(finally body ...+)]
Evaluated before @racket[try] returns.

@(examples
  #:eval ev
  (try
   (raise "raised string")
   (catch (? string? e)
     (display "Caught: " (current-error-port))
     (displayln e (current-error-port))))

  (try
   (cons 1)
   (catch (or (? exn? (app exn-message msg))
              (app ~a msg))
     msg))

  (displayln
   (call/cc
    (lambda (cc)
      (try
       (cc "Escaped")
       (finally
        (displayln "Escaping")))))))

@defform[(try-with ([id val] ...) body ...+)]

Like @racket[let], bind @racket[id]s to @racket[val]s in @racket[body].
@racket[val]s are evaluated with @racket[current-custodian] set to a
new custodian created with @racket[make-custodian]. When the expression returns,
the custodian is shutdown with @racket[custodian-shutdown-all] in a @racket[finally] clause.

@(examples
  #:eval ev
  (custodian-box-value
   (try-with ([b (make-custodian-box (current-custodian) 'x)])
     (displayln (custodian-box-value b))
     b)))

@defform[(try-with* ([id val] ...) body ...+)]

Like @racket[try-with], but the binding of each @racket[id] is made available
in subsequent @racket[val]s, as in @racket[let*].
All @racket[val]s are evaluated with the same custodian.
