; source: https://www.purebasic.fr/french/viewtopic.php?p=175863#p175863
;==============================================================================
;== Drag and display IFF-ILBM 24 bits files on the window
;==============================================================================

IncludeFile "TinyIFF24.pbi"

EnableExplicit

Procedure load(file.s)
  
  Protected image, iw, ih, ww, wh, t1, t2
  
  t1 = ElapsedMilliseconds()
  image = TinyIFF24::Load(file)
  t2 = ElapsedMilliseconds()
  
  If image
    ww = WindowWidth(0)
    wh = WindowHeight(0)
    iw = ImageWidth(image)
    ih = ImageHeight(image)
    ResizeGadget(0, ( ww - iw ) / 2, ( wh - ih ) / 2, #PB_Ignore, #PB_Ignore)
    SetWindowTitle(0, GetFilePart(file))
    If StartDrawing(ImageOutput(image))
      FrontColor(0)
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawText(15, 15, "File: " + file)
      DrawText(15, 35, "Format: IFF ILBM 24Bits (Compressed and Interleaved)")
      DrawText(15, 55, "Dimension : " + Str(iw) + " x " + Str(ih))
      DrawText(15, 75, "Nb Pixels : " + Str(iw * ih))
      DrawText(15, 95, "Loaded in " + Str(t2 - t1) + "ms")
      StopDrawing()
    EndIf
    SetGadgetState(0, ImageID(image))
    FreeImage(image)
  EndIf
  
EndProcedure

;==============================================================================

If OpenWindow(0, 0, 0, 1430, 1010, "", #PB_Window_ScreenCentered)
  SetWindowColor(0, 0)
  ImageGadget(0, 0, 0, WindowWidth(0), WindowHeight(0), 0)
  EnableWindowDrop(0, #PB_Drop_Files, #PB_Drag_Link)
  load("MARBLES.IFF")
  Repeat
    Select WaitWindowEvent()
      Case #PB_Event_CloseWindow: Break
      Case #PB_Event_WindowDrop: load(StringField(EventDropFiles(), 1, Chr(10)))
    EndSelect
  ForEver
EndIf

;==============================================================================