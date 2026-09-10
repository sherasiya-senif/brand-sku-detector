# google_mlkit_text_recognition references optional script recognizers
# (Chinese, Devanagari, Japanese, Korean) that this app does not bundle — it
# only uses the Latin model. Suppress R8 "Missing class" errors for them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
