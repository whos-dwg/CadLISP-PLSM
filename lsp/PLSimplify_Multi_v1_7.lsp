;;; PLSimplify_Multi_v1_7.lsp
;;; Command: PLSM
;;; Multi-select LWPOLYLINE simplifier
;;; 0 for Minimum vertex distance disables the "close-point" pass.

(vl-load-com)

(if (not *PLSM-MinDist*) (setq *PLSM-MinDist* 0.0))
(if (not *PLSM-LineTol*) (setq *PLSM-LineTol* 2.0))

(defun PLSM:PX (p) (car p))
(defun PLSM:PY (p) (cdr p))

(defun PLSM:LastItem (lst)
  (if lst
    (progn
      (while (cdr lst) (setq lst (cdr lst)))
      (car lst))
  )
)

(defun PLSM:Drop (lst n)
  (while (and lst (> n 0))
    (setq lst (cdr lst) n (1- n)))
  lst
)

(defun PLSM:ButLast (lst / out)
  (setq out nil)
  (while (and lst (cdr lst))
    (setq out (cons (car lst) out)
          lst (cdr lst)))
  (reverse out)
)

(defun PLSM:Take (lst n / out)
  (setq out nil)
  (while (and lst (> n 0))
    (setq out (cons (car lst) out)
          lst (cdr lst)
          n (1- n)))
  (reverse out)
)

(defun PLSM:Dist (a b / dx dy)
  (setq dx (- (PLSM:PX a) (PLSM:PX b))
        dy (- (PLSM:PY a) (PLSM:PY b)))
  (sqrt (+ (* dx dx) (* dy dy)))
)

(defun PLSM:PointSegDist (p a b / abx aby apx apy len2 u qx qy dx dy)
  (setq abx (- (PLSM:PX b) (PLSM:PX a))
        aby (- (PLSM:PY b) (PLSM:PY a))
        apx (- (PLSM:PX p) (PLSM:PX a))
        apy (- (PLSM:PY p) (PLSM:PY a))
        len2 (+ (* abx abx) (* aby aby)))
  (if (< len2 1e-20)
    (PLSM:Dist p a)
    (progn
      (setq u (/ (+ (* apx abx) (* apy aby)) len2))
      (cond ((< u 0.0) (setq u 0.0))
            ((> u 1.0) (setq u 1.0)))
      (setq qx (+ (PLSM:PX a) (* u abx))
            qy (+ (PLSM:PY a) (* u aby))
            dx (- (PLSM:PX p) qx)
            dy (- (PLSM:PY p) qy))
      (sqrt (+ (* dx dx) (* dy dy)))
    )
  )
)

(defun PLSM:GetPts (en / ed item pts)
  (setq ed (entget en) pts nil)
  (foreach item ed
    (if (= (car item) 10)
      (setq pts
        (cons
          (cons (float (cadr item)) (float (caddr item)))
          pts))))
  (reverse pts)
)

(defun PLSM:HasArc (en / item hit)
  (setq hit nil)
  (foreach item (entget en)
    (if (and (= (car item) 42)
             (numberp (cdr item))
             (> (abs (cdr item)) 1e-12))
      (setq hit T)))
  hit
)

(defun PLSM:IsClosed (en / flag)
  (setq flag (cdr (assoc 70 (entget en))))
  (= 1 (logand 1 flag))
)

(defun PLSM:RemoveClose (pts tol / out lastp endpoint p)
  (if (or (<= tol 0.0) (<= (length pts) 2))
    pts
    (progn
      (setq out (list (car pts))
            lastp (car pts)
            endpoint (PLSM:LastItem pts))
      (foreach p (cdr (PLSM:ButLast pts))
        (if (>= (PLSM:Dist p lastp) tol)
          (progn
            (setq out (append out (list p)))
            (setq lastp p))))
      (if (< (PLSM:Dist (PLSM:LastItem out) endpoint) tol)
        (if (> (length out) 1)
          (append (PLSM:ButLast out) (list endpoint))
          (list (car out) endpoint))
        (append out (list endpoint)))
    )
  )
)

(defun PLSM:RDP (pts tol / first lastpt maxd maxi idx p d left right mids)
  (if (<= (length pts) 2)
    pts
    (progn
      (setq first (car pts)
            lastpt (PLSM:LastItem pts)
            maxd -1.0
            maxi nil
            idx 1
            mids (cdr (PLSM:ButLast pts)))
      (foreach p mids
        (setq d (PLSM:PointSegDist p first lastpt))
        (if (> d maxd)
          (setq maxd d maxi idx))
        (setq idx (1+ idx)))
      (if (and maxi (> maxd tol))
        (progn
          (setq left (PLSM:Take pts (1+ maxi))
                right (PLSM:Drop pts maxi))
          (append
            (PLSM:ButLast (PLSM:RDP left tol))
            (PLSM:RDP right tol)))
        (list first lastpt))
    )
  )
)

(defun PLSM:MakeNew (old pts / ed data code item new)
  (setq ed (entget old)
        data (list '(0 . "LWPOLYLINE") '(100 . "AcDbEntity")))
  (foreach code '(8 6 62 48 370 420 440)
    (if (assoc code ed)
      (setq data (append data (list (assoc code ed))))))
  (setq data
    (append data
      (list '(100 . "AcDbPolyline")
            (cons 90 (length pts))
            (cons 70 0))))
  (foreach code '(43 38 39 210)
    (if (assoc code ed)
      (setq data (append data (list (assoc code ed))))))
  (foreach item pts
    (setq data
      (append data
        (list (list 10 (PLSM:PX item) (PLSM:PY item))))))
  (setq new (entmakex data))
  (if new
    (progn (entdel old) new)
    nil)
)

(defun PLSM:ProcessOne (en minDist lineTol / pts p1 p2 before after new)
  (cond
    ((PLSM:IsClosed en) (list 'closed))
    ((PLSM:HasArc en) (list 'arc))
    (T
      (setq pts (PLSM:GetPts en)
            before (length pts))
      (if (< before 3)
        (list 'simple before before)
        (progn
          (setq p1 (PLSM:RemoveClose pts minDist)
                p2 (PLSM:RDP p1 lineTol)
                after (length p2))
          (if (< after before)
            (progn
              (setq new (PLSM:MakeNew en p2))
              (if new
                (list 'changed before after)
                (list 'error before before)))
            (list 'tolerance before after))
        )
      )
    )
  )
)

(defun c:PLSM (/ *error* doc ss i en result minD tol
                 selected changed simple overTol skipClosed skipArc errors
                 beforeTotal afterTotal removedTotal)

  (vl-load-com)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))

  (defun *error* (msg)
    (vl-catch-all-apply 'vla-EndUndoMark (list doc))
    (if (and msg
             (/= msg "Function cancelled")
             (/= msg "quit / exit abort"))
      (princ (strcat "\nPLSM Error: " msg)))
    (princ))

  ;; Allow 0, reject negative values.
  (initget 4)
  (setq minD
    (getdist
      (strcat
        "\nMinimum vertex distance [0=Off] <"
        (rtos *PLSM-MinDist* 2 3)
        ">: ")))
  (if minD (setq *PLSM-MinDist* minD))

  (initget 6)
  (setq tol
    (getdist
      (strcat
        "\nMaximum line deviation <"
        (rtos *PLSM-LineTol* 2 3)
        ">: ")))
  (if tol (setq *PLSM-LineTol* tol))

  (prompt "\nSelect LWPOLYLINE(s) to simplify: ")
  (setq ss (ssget '((0 . "LWPOLYLINE"))))

  (if ss
    (progn
      (setq selected (sslength ss)
            changed 0
            simple 0
            overTol 0
            skipClosed 0
            skipArc 0
            errors 0
            beforeTotal 0
            afterTotal 0
            i 0)

      (vla-StartUndoMark doc)

      (repeat selected
        (setq en (ssname ss i)
              result (PLSM:ProcessOne en *PLSM-MinDist* *PLSM-LineTol*))
        (cond
          ((= (car result) 'changed)
           (setq changed (1+ changed)
                 beforeTotal (+ beforeTotal (cadr result))
                 afterTotal (+ afterTotal (caddr result))))
          ((= (car result) 'simple)
           (setq simple (1+ simple)
                 beforeTotal (+ beforeTotal (cadr result))
                 afterTotal (+ afterTotal (caddr result))))
          ((= (car result) 'tolerance)
           (setq overTol (1+ overTol)
                 beforeTotal (+ beforeTotal (cadr result))
                 afterTotal (+ afterTotal (caddr result))))
          ((= (car result) 'closed)
           (setq skipClosed (1+ skipClosed)))
          ((= (car result) 'arc)
           (setq skipArc (1+ skipArc)))
          (T
           (setq errors (1+ errors))))
        (setq i (1+ i)))

      (vla-EndUndoMark doc)
      (setq removedTotal (- beforeTotal afterTotal))

      (princ "\nDone.")
      (princ (strcat "\nSelected: " (itoa selected)))
      (princ (strcat "\nSimplified: " (itoa changed)))
      (princ (strcat "\nAlready simple: " (itoa simple)))
      (princ (strcat "\nNo reduction at current tolerance: " (itoa overTol)))
      (princ (strcat "\nSkipped closed: " (itoa skipClosed)))
      (princ (strcat "\nSkipped arc/bulge: " (itoa skipArc)))
      (princ (strcat "\nErrors: " (itoa errors)))
      (if (> (+ changed simple overTol) 0)
        (progn
          (princ
            (strcat
              "\nVertices: "
              (itoa beforeTotal)
              " -> "
              (itoa afterTotal)))
          (princ
            (strcat
              "\nRemoved vertices: "
              (itoa removedTotal)))))
    )
    (princ "\nNothing selected."))

  (princ)
)

(princ "\nPLSimplify Multi v1.7 loaded. Command: PLSM")
(princ)
