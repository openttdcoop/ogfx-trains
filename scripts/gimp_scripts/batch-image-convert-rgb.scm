; Version 1
; 28/03/2012
; Xotic750
; This release may be used under the terms of the license: GPLv2
; http://www.gnu.org/licenses/gpl-2.0.html

(define (batch-image-convert-rgb pattern)
        (let*   ((filelist (cadr (file-glob pattern 1))))
                (while (not (null? filelist))
                        (let* ( (filename (car filelist))
                                (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
                                (drawable (car (gimp-image-get-active-layer image)))
                              )
                                (gimp-image-convert-rgb image)
                                (gimp-file-save RUN-NONINTERACTIVE image drawable filename filename)
                                (gimp-image-delete image)
                        )
                        (set! filelist (cdr filelist))
                )
        )
)

