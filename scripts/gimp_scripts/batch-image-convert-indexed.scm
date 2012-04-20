; Version 1
; 28/03/2012
; Xotic750
; This release may be used under the terms of the license: GPLv2
; http://www.gnu.org/licenses/gpl-2.0.html

(define (batch-image-convert-indexed pattern palette)
        (let*   ((filelist (cadr (file-glob pattern 1))))
                (while (not (null? filelist))
                        (let* ( (filename (car filelist))
                                (image (car (gimp-file-load RUN-NONINTERACTIVE filename filename)))
                                (drawable (car (gimp-image-get-active-layer image)))
                              )
                                (gimp-image-convert-indexed image 0 4 256 FALSE FALSE palette)
                                (gimp-file-save RUN-NONINTERACTIVE image drawable filename filename)
                                (gimp-image-delete image)
                        )
                        (set! filelist (cdr filelist))
                )
        )
)

