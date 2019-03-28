; source: https://www.purebasic.fr/english/viewtopic.php?p=471264#p471264

IncludeFile "TinyIFF_v1.2.pbi"

EnableExplicit

;==============================================================================

Procedure load(file.s)
  
  Protected image, iw, ih, ww, wh
  
  image = TinyIFF::Load(file)
  
  If image
    ww = WindowWidth(0)
    wh = WindowHeight(0)
    iw = ImageWidth(image)
    ih = ImageHeight(image)
    ResizeGadget(0, ( ww - iw ) / 2, ( wh - ih ) / 2, #PB_Ignore, #PB_Ignore)
    SetWindowTitle(0, GetFilePart(file))
    SetGadgetState(0, ImageID(image))
    FreeImage(image)
  EndIf
  
EndProcedure

;==============================================================================

If OpenWindow(0, 0, 0, 1280, 1024, "", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
  
  SetWindowColor(0, RGB(0, 0, 0))
  ImageGadget(0, 0, 0, WindowWidth(0), WindowHeight(0), 0)
  EnableWindowDrop(0, #PB_Drop_Files, #PB_Drag_Link)
  
  load("Suny_Bobby.iff") ; <<<<<<<<<<< changer le nom de fichier !!!
  
  Repeat
    Select WaitWindowEvent()
      Case #PB_Event_CloseWindow
        Break
      Case #PB_Event_WindowDrop
        load(StringField(EventDropFiles(), 1, Chr(10)))
    EndSelect
  ForEver
  
EndIf

;==============================================================================