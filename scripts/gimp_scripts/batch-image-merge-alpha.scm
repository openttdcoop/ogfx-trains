; Version 1
; 2012-04-02
; Xotic750
; This release may be used under the terms of the license: GPLv2
; http://www.gnu.org/licenses/gpl-2.0.html

(define (batch-image-merge-alpha file1 file2)
        (let* ( (image 0) (image2 0) (drawable 0))
		(set! image (car (gimp-file-load RUN-NONINTERACTIVE file1 file1)))
		(set! image2 (car (gimp-file-load-layer RUN-NONINTERACTIVE image file2)))
		(gimp-image-add-layer image image2 -1)
		(set! drawable (car (gimp-image-merge-visible-layers image EXPAND-AS-NECESSARY)))
		(gimp-file-save RUN-NONINTERACTIVE image drawable file1 file1)
		(gimp-image-delete image)
	)
)

