; Таблица Hook, с их помощью можно управлять и навешивать новые плагины

; Свободная память - отсчитывается сверху
FreeBlock           dw 0

; Desktop
; ----------------------------------------------------------------------

Desktop.Repaint     dw desktop.Repaint

; VGALib
; ----------------------------------------------------------------------

SetDefaultVideoMode dw VGALib.Set640x480
SetPixel            dw VGALib.SetPixel
GetPixel            dw VGALib.GetPixel
FillRectangle       dw VGALib.FillRectangle
AssignColor         dw VGALib.AssignColor
