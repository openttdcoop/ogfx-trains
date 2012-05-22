; Version 1
; 2012-05-21
; Xotic750
; This release may be used under the terms of the license: GPLv2
; http://www.gnu.org/licenses/gpl-2.0.html

(define (batch-levels-stretch pattern)
        (let*   ((filelist (cadr (file-glob pattern 1))))
                (while (not (null? filelist))
                        (let* ( (filename (car filelist))
                                (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
                                (drawable (car (gimp-image-get-active-layer image)))
                              )
                                (gimp-levels-stretch drawable)
                                (gimp-file-save RUN-NONINTERACTIVE image drawable filename filename)
                                (gimp-image-delete image)
                        )
                        (set! filelist (cdr filelist))
                )
        )
)
