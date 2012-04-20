; Version 1
; 28/03/2012
; Xotic750
; This release may be used under the terms of the license: GPLv2
; http://www.gnu.org/licenses/gpl-2.0.html

(define (batch-image-join valx valy valox valoy file1 file2 file3)
        (let* ( (image (car (gimp-image-new valx valy RGB))) (image1 0) (image2 0) (layer 0) (drawable 0))
		(set! layer (car (gimp-layer-new image valx valy RGBA-IMAGE "layer" 100 NORMAL-MODE)))
		(set! image1 (car (gimp-file-load-layer RUN-NONINTERACTIVE image file1)))
		(gimp-image-add-layer image image1 -1)
		(set! drawable (car (gimp-image-merge-visible-layers image EXPAND-AS-NECESSARY)))
		(set! image2 (car (gimp-file-load-layer RUN-NONINTERACTIVE image file2)))
		(gimp-image-add-layer image image2 -1)
		(gimp-layer-translate image2 valox valoy)
		(set! drawable (car (gimp-image-merge-visible-layers image EXPAND-AS-NECESSARY)))
		(gimp-file-save RUN-NONINTERACTIVE image drawable file3 file3)
		(gimp-image-delete image)
	)
)

