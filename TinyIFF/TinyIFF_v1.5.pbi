﻿; source: https://www.purebasic.fr/french/viewtopic.php?p=176024#p176024
;--------------------------------------------------------------------------------------------------
; Module:      TinyIFF.pbi
; Description: Module pour charger des images IFF-ILBM ou IFF-PBM.
; Auteur:      flype, flype44(at)gmail(dot)com
; Révision:    1.5 (2015-09-17)
; Compilateur: PureBasic 5.40 LTS Beta 3 (x64) Linux
;--------------------------------------------------------------------------------------------------

DeclareModule TinyIFF
  
  ; @TinyIFF::Load()
  ; Charge une image à partir de l'emplacement disque spécifié.
  ; #ImageID   : Le numéro d'identification de l'image à charger. 
  ; FileName$  : Le chemin et le nom du fichier à charger. 
  ; KeepAspect : Garde l'aspect original de l'image (Tient compte de xAspect/yAspect).
  ; ResizeMode : Mode de redimensionnement de l'image (avec ou sans interpolation).
  Declare Load(ImageID.l, FileName$, KeepAspect.l = #True, ResizeMode.l = #PB_Image_Raw)
  
  ; @TinyIFF::Catch()
  ; Charge une image à partir de l'emplacement mémoire spécifié.
  ; #ImageID   : Le numéro d'identification de l'image à charger. 
  ; *Memory    : Adresse de l'emplacement mémoire.
  ; MemSize.q  : Taille de l'emplacement mémoire (en octets).
  ; KeepAspect : Garde l'aspect original de l'image (Tient compte de xAspect/yAspect).
  ; ResizeMode : Mode de redimensionnement de l'image (avec ou sans interpolation).
  Declare Catch(ImageID.l, *Memory, MemSize.q, KeepAspect.l = #True, ResizeMode.l = #PB_Image_Raw)
  
  ; @Parameter KeepAspect
  ; #True  : Garde l'aspect original de l'image (défaut).
  ; #False : Redimensionne l'image en tenant compte de xAspect/yAspect.
  
  ; @Parameter ResizeMode
  ; #PB_Image_Raw    : Redimensionne l'image avec interpolation (défaut).
  ; #PB_Image_Smooth : Redimensionne l'image sans interpolation.
  
EndDeclareModule

;--------------------------------------------------------------------------------------------------

Module TinyIFF
  
  ;------------------------------------------------------------------------------------------------
  
  EnableExplicit
  
  ;------------------------------------------------------------------------------------------------
  
  Macro UINT16(a)
    ((((a)<<8)&$FF00)|(((a)>>8)&$FF))
  EndMacro
  
  Macro UINT32(a)
    ((((a)&$FF)<<24)|(((a)&$FF00)<<8)|(((a)>>8)&$FF00)|(((a)>>24)&$FF))
  EndMacro
  
  Macro MAKEID(a, b, c, d)
    ((a)|((b)<<8)|((c)<<16)|((d)<<24))
  EndMacro
  
  ;------------------------------------------------------------------------------------------------
  
  Enumeration ChunkIDs
    #ID_FORM = MAKEID('F','O','R','M') ; IFF file
    #ID_ILBM = MAKEID('I','L','B','M') ; Interleaved Bitmap (Planar)
    #ID_PBM  = MAKEID('P','B','M',' ') ; Portable Bitmap (Chunky)
    #ID_BMHD = MAKEID('B','M','H','D') ; Bitmap Header
    #ID_CMAP = MAKEID('C','M','A','P') ; Color Map
    #ID_CAMG = MAKEID('C','A','M','G') ; View Modes
    #ID_BODY = MAKEID('B','O','D','Y') ; Bitmap Data
  EndEnumeration
  
  Enumeration ViewModes
    #camgLace       = $0004 ; Interlaced
    #camgEHB        = $0080 ; Extra Half Bright
    #camgHAM        = $0800 ; Hold And Modify
    #camgHiRes      = $8000 ; High Resolution
    #camgSuperHiRes = $0020 ; Super High Resolution
  EndEnumeration
  
  Enumeration BitmapHeaderCmp
    #cmpNone     ; No compression
    #cmpByteRun1 ; ByteRun1 encoding
  EndEnumeration
  
  ;------------------------------------------------------------------------------------------------
  
  Structure BYTES
    b.b[0]
  EndStructure
  
  Structure UBYTES
    b.a[0]
  EndStructure
  
  Structure IFF_RGB8
    r.a
    g.a
    b.a
  EndStructure
  
  Structure IFF_BMHD
    w.u           ; UWORD
    h.u           ; UWORD
    x.w           ; WORD
    y.w           ; WORD
    nPlanes.a     ; UBYTE
    masking.a     ; UBYTE
    compression.a ; UBYTE
    pad.a         ; UBYTE
    tColor.u      ; UWORD
    xAspect.a     ; UBYTE
    yAspect.a     ; UBYTE
    pageWidth.w   ; WORD
    pageHeight.w  ; WORD
  EndStructure
  
  Structure IFF_CMAP
    c.IFF_RGB8[0]
  EndStructure
  
  Structure IFF_Chunk
    id.l
    size.l
    bytes.UBYTES
  EndStructure
  
  Structure IFF_Header
    id.l
    size.l
    name.l
    chunk.UBYTES
  EndStructure
  
  ;------------------------------------------------------------------------------------------------
  
  Procedure UnPackBits(*bh.IFF_BMHD, *packedBits.BYTES, packedSize, rowBytes)
    Protected i, j, k, v, unpackedSize, *unpackedBits.BYTES
    unpackedSize = 1 + ( *bh\h * rowBytes * *bh\nPlanes )
    If unpackedSize
      *unpackedBits = AllocateMemory(unpackedSize)
      If *unpackedBits
        While i < packedSize
          v = *packedBits\b[i]
          If v >= 0
            For j = 0 To v
              *unpackedBits\b[k] = *packedBits\b[i + 1 + j]
              k + 1
            Next
            i + j
          ElseIf v <> -128
            For j = 0 To -v
              *unpackedBits\b[k] = *packedBits\b[i + 1]
              k + 1
            Next
            i + 1
          EndIf
          i + 1
        Wend
      EndIf
    EndIf
    ProcedureReturn *unpackedBits
  EndProcedure
  
  ;------------------------------------------------------------------------------------------------
  
  Procedure Catch_PBM_8(*bh.IFF_BMHD, *bp.UBYTES, Array cmap.l(1))
    Protected x, y, i
    For y = 0 To *bh\h - 1
      For x = 0 To *bh\w - 1
        Plot(x, y, cmap(*bp\b[i]))
        i + 1
      Next
    Next
  EndProcedure
  
  Procedure Catch_PBM_24(*bh.IFF_BMHD, *bp.UBYTES)
    Protected x, y, i
    For y = 0 To *bh\h - 1
      For x = 0 To *bh\w - 1
        Plot(x, y, RGB(*bp\b[i], *bp\b[i+1], *bp\b[i+2]))
        i + 3
      Next
    Next
  EndProcedure
  
  ;------------------------------------------------------------------------------------------------
  
  Procedure Catch_ILBM_8(*bh.IFF_BMHD, *bp.UBYTES, rowBytes.w, camg.l, cmapSize.l, Array cmap.l(1))
    Protected i, x, y, c, p, plane, mbits, mask, hbits, Dim pixels(*bh\w)
    If camg & #camgHAM
      hbits = 4
      If *bh\nPlanes > 6 : hbits + 2 : EndIf
      mbits = 8 - hbits
      mask = ( 1 << hbits ) - 1
    EndIf
    If camg & #camgEHB
      For i = 0 To ( cmapSize / 3 ) - 1
        cmap(i+32) = RGB(Red(cmap(i)) >> 1, Green(cmap(i)) >> 1, Blue(cmap(i)) >> 1)
      Next
    EndIf
    For y = 0 To *bh\h - 1
      For plane = 0 To *bh\nPlanes - 1
        For x = 0 To *bh\w - 1
          If *bp\b[x >> 3] & ( 128 >> ( x % 8 ) )
            pixels(x) | ( 1 << plane )
          EndIf
        Next
        *bp + rowBytes
      Next
      For x = 0 To *bh\w - 1
        If camg & #camgHAM
          p = pixels(x)
          Select p >> hbits
            Case 0: c = cmap(p & mask)
            Case 1: c = RGB(Red(c), Green(c), ( p & mask ) << mbits)
            Case 2: c = RGB(( p & mask ) << mbits, Green(c), Blue(c))
            Case 3: c = RGB(Red(c), ( p & mask ) << mbits, Blue(c))
          EndSelect
        Else
          c = cmap(pixels(x))
        EndIf
        Plot(x, y, c)
        pixels(x) = 0
      Next
      c = 0
    Next
  EndProcedure
  
  Procedure Catch_ILBM_24(*bh.IFF_BMHD, *bp.UBYTES, rowBytes.l)
    Protected x, y, w, h, p, plane, p0, p1, p2
    Protected Dim m(*bh\w), Dim r(*bh\w), Dim g(*bh\w), Dim b(*bh\w)
    w = *bh\w - 1 : h = *bh\h - 1 : p = *bh\nPlanes - 1
    For x = 0 To w : m(x) = 128 >> ( x % 8 ) : Next
    For y = 0 To h
      For plane = 0 To p
        p0 = 1 <<   plane
        p1 = 1 << ( plane -  8 )
        p2 = 1 << ( plane - 16 )
        If plane < 8
          For x = 0 To w
            If *bp\b[x >> 3] & m(x) : r(x) | p0 : EndIf
          Next
        ElseIf plane > 15
          For x = 0 To w
            If *bp\b[x >> 3] & m(x) : b(x) | p2 : EndIf
          Next
        Else
          For x = 0 To w
            If *bp\b[x >> 3] & m(x) : g(x) | p1 : EndIf
          Next
        EndIf
        *bp + rowBytes
      Next
      For x = 0 To w
        Plot(x, y, RGB(r(x), g(x), b(x)))
        r(x) = 0 : g(x) = 0 : b(x) = 0
      Next
    Next
  EndProcedure
  
  ;------------------------------------------------------------------------------------------------
  
  Procedure Catch(ImageID.l, *m.IFF_Header, MemSize.q, KeepAspect.l = #True, ResizeMode.l = #PB_Image_Raw)
    Protected i.l, image.i, rowBytes.w, camg.l, cmapSize.l, *imageOutput, *bp, *eof, *bodyUnpacked
    Protected *ck.IFF_Chunk, *bh.IFF_BMHD, *cmap.IFF_CMAP, Dim cmap.l(256)
    If *m And *m\id = #ID_FORM And ( *m\name = #ID_ILBM Or *m\name = #ID_PBM )
      *m\size = UINT32(*m\size)
      If *m\size > 0 And *m\size < MemSize
        *eof = *m + MemSize
        *ck = *m\chunk
        While *ck
          *ck\size = UINT32(*ck\size)
          If *ck\size & 1
            *ck\size + 1
          EndIf
          Select *ck\id
            Case #ID_BMHD
              *bh = *ck\bytes
              *bh\w = UINT16(*bh\w)
              *bh\h = UINT16(*bh\h)
              rowBytes = ( ( ( *bh\w + 15 ) >> 4 ) << 1 )
            Case #ID_CAMG
              camg = UINT32(PeekL(*ck\bytes))
              Debug "camg = %" + RSet(Bin(camg, #PB_Long), 32, "0")
            Case #ID_CMAP
              *cmap = *ck\bytes
              cmapSize = *ck\size
              For i = 0 To ( cmapSize / 3 ) - 1
                cmap(i) = RGB(*cmap\c[i]\r, *cmap\c[i]\g, *cmap\c[i]\b)
              Next
            Case #ID_BODY
              *bp = *ck\bytes
              If *bh\compression = #cmpByteRun1
                *bodyUnpacked = UnPackBits(*bh, *ck\bytes, *ck\size, rowBytes)
                *bp = *bodyUnpacked
              EndIf
              If *bp And *bh
                image = CreateImage(ImageID, *bh\w, *bh\h, 24, RGB(0, 0, 0))
                If image
                  If ImageID = #PB_Any
                    *imageOutput = ImageOutput(image)
                  Else
                    *imageOutput = ImageOutput(ImageID)
                  EndIf
                  If StartDrawing(*imageOutput)
                    Select *m\name
                      Case #ID_ILBM
                        If *bh\nPlanes = 24
                          Catch_ILBM_24(*bh, *bp, rowBytes)
                        Else
                          Catch_ILBM_8(*bh, *bp, rowBytes, camg, cmapSize, cmap())
                        EndIf
                      Case #ID_PBM
                        If *bh\nPlanes = 24
                          Catch_PBM_24(*bh, *bp)
                        Else
                          Catch_PBM_8(*bh, *bp, cmap())
                        EndIf
                    EndSelect
                    StopDrawing()
                  EndIf
                EndIf
                If KeepAspect = #False
                  If *bh\xAspect = 0 Or *bh\yAspect = 0
                    *bh\xAspect = 10 : *bh\yAspect = 11
                  EndIf
                  Protected xRes.d = 1.0 + ( *bh\xAspect / *bh\yAspect )
                  Protected yRes.d = 1.0 + ( *bh\yAspect / *bh\xAspect )
                  If ImageID = #PB_Any
                    ResizeImage(image, *bh\w * xRes, *bh\h * yRes, ResizeMode)
                  Else
                    ResizeImage(ImageID, *bh\w * xRes, *bh\h * yRes, ResizeMode)
                  EndIf
                EndIf
              EndIf
              If *bodyUnpacked
                FreeMemory(*bodyUnpacked)
              EndIf
              Break
          EndSelect
          If *ck < *eof
            *ck + 8 + *ck\size
          Else
            *ck = 0
          EndIf
        Wend
      EndIf
    EndIf
    ProcedureReturn image
  EndProcedure
  
  Procedure Load(ImageID.l, FileName$, KeepAspect.l = #True, ResizeMode.l = #PB_Image_Raw)
    Protected image.i, file.i, fileSize.q, *fileData
    file = ReadFile(#PB_Any, FileName$)
    If file
      fileSize = Lof(file)
      If fileSize > 0
        *fileData = AllocateMemory(fileSize, #PB_Memory_NoClear)
        If *fileData
          If ReadData(file, *fileData, fileSize) > 0
            image = Catch(ImageID, *fileData, fileSize, KeepAspect, ResizeMode)
          EndIf
          FreeMemory(*fileData)
        EndIf
      EndIf
      CloseFile(file)
    EndIf
    ProcedureReturn image
  EndProcedure
  
EndModule

;--------------------------------------------------------------------------------------------------