#  TODO NorthLib

Things that should be done soon

## Important before next release

- PdfModel :: PdfDisplayOptions :: Overview :: totalRowSpacing need calc for iPad Layout
- ZoomedImageView :: handleDoubleTap changed check behaviour in Article Image Galery
- SpeechSynthesizer :: TTS: What happen if no german available?  Line 32 German Voice!
- SpeechSynthesizer :: CommandCenter Pause not recognized in App UI may regiter for notifications
- PdfOverviewCollectionVC :: memory leak for cell menu check!

## Less-Important keep in mind for future releases

- Make methods that may fail use throw (eg. File.*)
- Failures from LowLevel should throw str_error()
- Make File methods async in addition to blocking (where it makes sense)
- Improve documentation and add 
  [DocC](https://developer.apple.com/documentation/docc) 
  files to the repository (and link to it from README.md).
