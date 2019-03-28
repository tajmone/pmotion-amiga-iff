; source: https://www.purebasic.fr/english/viewtopic.php?p=471263#p471263
;----------------------------------------------------------
; Name:        Module TinyIFF
; Description: A tiny module for loading IFF images.
; Author:      flype, flype44(at)gmail(dot)com
; Revision:    1.1 (2015-09-10)
;----------------------------------------------------------
; ILBM ::= "FORM" #{ "ILBM" BMHD [CMAP] [CAMG] [BODY] }
; BMHD ::= "BMHD" #{ BitMapHeader }
; CMAP ::= "CMAP" #{ (Red Green Blue)* } [0]
; CAMG ::= "CAMG" #{ LONG }
; BODY ::= "BODY" #{ UBYTE* } [0]
;----------------------------------------------------------
; http://fileformats.archiveteam.org/wiki/ILBM
; http://wiki.amigaos.net/wiki/ILBM_IFF_Interleaved_Bitmap
;----------------------------------------------------------

DeclareModule TinyIFF
  Declare.i Catch(*memory, size.q = #PB_Ignore)
  Declare.i Load(fileName.s)
EndDeclareModule

Module TinyIFF
  
  ;----------------------------------------------------------
  ; INITS
  ;----------------------------------------------------------
  
  EnableExplicit
  
  ;----------------------------------------------------------
  ; PRIVATE MACROS
  ;----------------------------------------------------------
  
  Macro MAKEID(a, b, c, d)
    ((a)|((b)<<8)|((c)<<16)|((d)<<24))
  EndMacro
  
  Macro GetUInt16BE(a)
    ((((a)<<8)&$FF00)|(((a)>>8)&$FF))
  EndMacro
  
  Macro GetUInt32BE(a)
    ((((a)&$FF)<<24)|(((a)&$FF00)<<8)|(((a)>>8)&$FF00)|(((a)>>24)&$FF))
  EndMacro
  
  ;----------------------------------------------------------
  ; PRIVATE CONSTANTS
  ;----------------------------------------------------------
  
  #ID_FORM = MAKEID('F','O','R','M') ; IFF file
  #ID_ILBM = MAKEID('I','L','B','M') ; Interleaved Bitmap (Planar)
  #ID_PBM  = MAKEID('P','B','M',' ') ; Portable Bitmap (Chunky)
  #ID_BMHD = MAKEID('B','M','H','D') ; Bitmap Header
  #ID_CMAP = MAKEID('C','M','A','P') ; ColorMap
  #ID_CAMG = MAKEID('C','A','M','G') ; ViewModes
  #ID_BODY = MAKEID('B','O','D','Y') ; Bitmap Data
  
  Enumeration BitmapHeaderCmp
    #cmpNone     ; No compression
    #cmpByteRun1 ; ByteRun1 encoding
  EndEnumeration
  
  Enumeration BitmapHeaderMsk
    #mskNone                ; Opaque rectangular image
    #mskHasMask             ; Mask plane is interleaved with the bitplanes in the BODY chunk
    #mskHasTransparentColor ; Pixels in source planes matching 'transparentColor' are "transparent"
    #mskLasso               ; Reader may construct a mask by lassoing the image
  EndEnumeration
  
  Enumeration ViewModes
    #camgLace       = $0004 ; Interlaced
    #camgEHB        = $0080 ; Extra Half Bright
    #camgHAM        = $0800 ; Hold And Modify
    #camgHiRes      = $8000 ; High Resolution
    #camgSuperHiRes = $0020 ; Super High Resolution
  EndEnumeration
  
  ;----------------------------------------------------------
  ; PRIVATE STRUCTURES
  ;----------------------------------------------------------
  
  CompilerIf Defined(BYTES, #PB_Structure) = #False
    Structure BYTES
      b.b[0]
    EndStructure
  CompilerEndIf
  
  CompilerIf Defined(UBYTES, #PB_Structure) = #False
    Structure UBYTES
      b.a[0]
    EndStructure
  CompilerEndIf
  
  Structure IFF_RGB8
    r.a
    g.a
    b.a
  EndStructure
  
  Structure IFF_CMAP
    c.IFF_RGB8[0]
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
  
  Structure IFF_Chunk
    code.l
    size.l
    bytes.UBYTES
  EndStructure
  
  Structure IFF_Header
    code.l
    size.l
    format.l
    chunk.UBYTES
  EndStructure
  
  ;----------------------------------------------------------
  ; PRIVATE PROCEDURES
  ;----------------------------------------------------------
  
  Procedure Log2(a)
    Protected b
    While a > ( 1 << b )
      b + 1
    Wend
    ProcedureReturn b
  EndProcedure
  
  Procedure FreeMem(*mem)
    If *mem
      FreeMemory(*mem)
    EndIf
  EndProcedure
  
  Procedure UnPackBitsSize(*bits.BYTES, packedSize)
    
    Protected i, j, k, n
    
    While i < packedSize
      n = *bits\b[i]
      If n >= 0
        For j = 0 To n
          k + 1
        Next
        i + j
      ElseIf n <> -128
        For j = 0 To -n
          k + 1
        Next
        i + 1
      EndIf
      i + 1
    Wend
    
    ProcedureReturn k
    
  EndProcedure
  
  Procedure UnPackBits(*bits.BYTES, packedSize)
    
    Protected i, j, k, n, *buf.BYTES, unpackedSize
    
    unpackedSize = UnPackBitsSize(*bits, packedSize)
    If unpackedSize > 0
      *buf = AllocateMemory(unpackedSize)
      If *buf <> 0
        While i < packedSize
          n = *bits\b[i]
          If n >= 0
            For j = 0 To n
              *buf\b[k] = *bits\b[i + 1 + j]
              k + 1
            Next
            i + j
          ElseIf n <> -128
            For j = 0 To -n
              *buf\b[k] = *bits\b[i + 1]
              k + 1
            Next
            i + 1
          EndIf
          i + 1
        Wend
      EndIf
    EndIf
    
    ProcedureReturn *buf
    
  EndProcedure
  
  Procedure UnInterleaveBits(*planar.UBYTES, width.w, height.w, nPlanes.b)
    
    Protected C0, C1, C2, C3, C4, C5, C6
    Protected bytesPerRow, bit, x, y, z, *chunky.UBYTES
    
    *chunky = AllocateMemory(width * height * nPlanes)
    If *chunky
      bytesPerRow = ( ( width + 15 ) >> 4 ) << 1
      C0 = nPlanes * bytesPerRow
      For y = 0 To height - 1
        C1 = y * C0
        C2 = y * width
        For z = 0 To nPlanes - 1
          C3 = 1 << z
          C4 = C1 + z * bytesPerRow
          For x = 0 To bytesPerRow - 1
            C5 = *planar\b[ C4 + x ]
            C6 = C2 + x << 3
            For bit = 0 To 7
              If C5 & ( 1 << ( 7 - bit ) )
                *chunky\b[ C6 + bit ] | C3
              EndIf
            Next
          Next
        Next
      Next
    EndIf
    
    ProcedureReturn *chunky
    
  EndProcedure
  
  Procedure ColorMapGray(*bmhd.IFF_BMHD)
    
    Protected i.l, numColors.l, *cmap.IFF_CMAP, *c.IFF_RGB8
    
    numColors = 1 << *bmhd\nPlanes
    If numColors > 0
      *cmap = AllocateMemory(numColors * SizeOf(IFF_RGB8), #PB_Memory_NoClear)
      If *cmap
        For i = 0 To numColors - 1
          *c = *cmap\c[i]
          *c\r = i * 255 / numColors
          *c\g = *c\r
          *c\b = *c\r
        Next
      EndIf
    EndIf
    
    ProcedureReturn *cmap
    
  EndProcedure
  
  Procedure ColorMapEHB(*bmhd.IFF_BMHD, *cmap.IFF_CMAP, cmapSize.l)
    
    Protected i.l, count.l, countEHB.l
    Protected *cmapEHB.IFF_CMAP, *c.IFF_RGB8, *d.IFF_RGB8
    
    count = cmapSize / SizeOf(IFF_RGB8)
    If count > 0
      If Log2(count) = *bmhd\nPlanes
        count / 2
      EndIf
      If count And count < ( 1 << *bmhd\nPlanes )
        countEHB = count * 2
        *cmapEHB = AllocateMemory(countEHB * SizeOf(IFF_RGB8), #PB_Memory_NoClear)
        If *cmap And *cmapEHB
          CopyMemory(*cmap, *cmapEHB, cmapSize)
          For i = count To countEHB - 1
            *c   = *cmap\c[i-count]
            *d   = *cmapEHB\c[i]
            *d\r = *c\r >> 1
            *d\g = *c\g >> 1
            *d\b = *c\b >> 1
          Next
        EndIf
      EndIf
    EndIf
    
    ProcedureReturn *cmapEHB
    
  EndProcedure
  
  Procedure GetPixelHAM(*cmap.IFF_CMAP, pixel, color, hbits, mbits, mask)
    
    Protected r, g, b
    
    Select pixel >> hbits
      Case 0 ; rgb
        r = *cmap\c[pixel & mask]\r
        g = *cmap\c[pixel & mask]\g
        b = *cmap\c[pixel & mask]\b
      Case 1 ; rgx
        r = Red(color)
        g = Green(color)
        b = ( pixel & mask ) << mbits
        b | ( b >> mbits )
      Case 2 ; xgb
        r = ( pixel & mask ) << mbits
        r | ( r >> mbits )
        g = Green(color)
        b = Blue(color)
      Case 3 ; rxg
        r = Red(color)
        g = ( pixel & mask ) << mbits
        g | ( g >> mbits )
        b = Blue(color)
    EndSelect
    
    ProcedureReturn RGBA(r, g, b, 255)
    
  EndProcedure
  
  Procedure DrawBitmapHAM(*bmhd.IFF_BMHD, *cmap.IFF_CMAP, *bits.UBYTES, image.i)
    
    Protected x, y, i, j, c, hbits, mbits, mask, tColor
    
    If *bmhd\nPlanes > 6
      hbits = 6
    Else
      hbits = 4
    EndIf
    
    mbits = ( 8  - hbits )
    mask  = ( 1 << hbits ) - 1
    
    tColor = RGBA(*cmap\c[*bmhd\tColor]\r,
                  *cmap\c[*bmhd\tColor]\g,
                  *cmap\c[*bmhd\tColor]\b, 0)
    
    If StartDrawing(ImageOutput(image))
      ;Box(0, 0, *bmhd\w, *bmhd\h, RGB(0, 255, 0))
      For y = 0 To *bmhd\h - 1
        c = RGB(0, 0, 0)
        For x = 0 To *bmhd\w - 1
          j = *bits\b[i]
          If ( *bmhd\masking & #mskHasTransparentColor ) And ( j = *bmhd\tColor )
            c = RGB(0, 0, 0)
            Plot(x, y, tColor)
          Else
            c = GetPixelHAM(*cmap, j, c, hbits, mbits, mask)
            Plot(x, y, c)
          EndIf
          i + 1
        Next
      Next
      StopDrawing()
    EndIf
    
  EndProcedure
  
  Procedure DrawBitmap(*bmhd.IFF_BMHD, *cmap.IFF_CMAP, *bits.UBYTES, image.i)
    
    Protected x.u, y.u, i.l, j.l, *c.IFF_RGB8
    
    If StartDrawing(ImageOutput(image))
      ;Box(0, 0, *bmhd\w, *bmhd\h, RGB(0, 255, 0))
      For y = 0 To *bmhd\h - 1
        For x = 0 To *bmhd\w - 1
          j = *bits\b[i]
          If ( *bmhd\masking & #mskHasTransparentColor ) And ( j = *bmhd\tColor )
            ; Do nothing, Transparent Color = No draw.
          Else
            *c = *cmap\c[j]
            Plot(x, y, RGB(*c\r, *c\g, *c\b))
          EndIf
          i + 1
        Next
      Next
      StopDrawing()
    EndIf
    
  EndProcedure
  
  ;----------------------------------------------------------
  ; PUBLIC PROCEDURES
  ;----------------------------------------------------------
  
  Procedure.i Catch(*mem.IFF_Header, size.q = #PB_Ignore)
    
    Protected image.i, cmapSize.l, xRes.d, yRes.d
    Protected *chunk.IFF_Chunk, *bmhd.IFF_BMHD
    Protected *body, *bodyUnpacked, *bodyUninterleaved
    Protected *eof, *cmap, *cmapEHB, *cmapGray, *camg.Long
    
    If *mem And *mem\code = #ID_FORM And ( *mem\format = #ID_ILBM Or *mem\format = #ID_PBM )
      *mem\size = GetUInt32BE(*mem\size)
      If *mem\size > 0 And *mem\size < size
        *chunk = *mem\chunk
        *eof = *mem + size
        While *chunk
          *chunk\size = GetUInt32BE(*chunk\size)
          If *chunk\size & 1
            *chunk\size + 1
          EndIf
          Select *chunk\code
            Case #ID_BMHD
              *bmhd = *chunk\bytes
              *bmhd\w = GetUInt16BE(*bmhd\w)
              *bmhd\h = GetUInt16BE(*bmhd\h)
              *bmhd\tColor = GetUInt16BE(*bmhd\tColor)
              If *bmhd\masking & #mskNone
                *bmhd\tColor = 0
              EndIf
              If *bmhd\masking & #mskHasMask
                *bmhd\nPlanes + 1
                *bmhd\tColor = 0
              EndIf
            Case #ID_CMAP
              *cmap = *chunk\bytes
              cmapSize = *chunk\size
            Case #ID_CAMG
              *camg = *chunk\bytes
              *camg\l = GetUInt32BE(*camg\l)
            Case #ID_BODY
              Select *mem\format
                Case #ID_ILBM
                  Select *bmhd\compression
                    Case #cmpNone
                      *bodyUninterleaved = UnInterleaveBits(*chunk\bytes, *bmhd\w, *bmhd\h, *bmhd\nPlanes)
                      If *bodyUninterleaved
                        *body = *bodyUninterleaved
                      EndIf
                    Case #cmpByteRun1
                      *bodyUnpacked = UnPackBits(*chunk\bytes, *chunk\size)
                      If *bodyUnpacked
                        *bodyUninterleaved = UnInterleaveBits(*bodyUnpacked, *bmhd\w, *bmhd\h, *bmhd\nPlanes)
                        If *bodyUninterleaved
                          *body = *bodyUninterleaved
                        EndIf
                      EndIf
                  EndSelect
                Case #ID_PBM
                  Select *bmhd\compression
                    Case #cmpNone
                      *body = *chunk\bytes
                    Case #cmpByteRun1
                      *bodyUnpacked = UnPackBits(*chunk\bytes, *chunk\size)
                      If *bodyUnpacked
                        *body = *bodyUnpacked
                      EndIf
                  EndSelect
              EndSelect
              If *camg And *camg\l & #camgEHB
                *cmapEHB = ColorMapEHB(*bmhd, *cmap, cmapSize)
                If *cmapEHB
                  *cmap = *cmapEHB
                EndIf
              EndIf
              If *cmap = #Null
                *cmapGray = ColorMapGray(*bmhd)
                If *cmapGray
                  *cmap = *cmapGray
                EndIf
              EndIf
              If *body And *cmap And *bmhd And *bmhd\w > 0 And *bmhd\h > 0
                image = CreateImage(#PB_Any, *bmhd\w, *bmhd\h, 24, RGB(0, 255, 0))
                If *bmhd\xAspect = 0 Or *bmhd\yAspect = 0
                  *bmhd\xAspect = 10
                  *bmhd\yAspect = 11
                EndIf
                xRes = 1.0 + ( *bmhd\xAspect / *bmhd\yAspect )
                yRes = 1.0 + ( *bmhd\yAspect / *bmhd\xAspect )
                If *camg And *camg\l & #camgHAM
                  DrawBitmapHAM(*bmhd, *cmap, *body, image)
                Else
                  DrawBitmap(*bmhd, *cmap, *body, image)
                EndIf
                ;If *camg And *camg\l & #camgLace
                ;  yRes / 2.0
                ;EndIf
                ResizeImage(image, *bmhd\w * xRes, *bmhd\h * yRes, #PB_Image_Raw)
              EndIf
              FreeMem(*cmapEHB)
              FreeMem(*cmapGray)
              FreeMem(*bodyUninterleaved)
              FreeMem(*bodyUnpacked)
              Break
          EndSelect
          If *chunk < *eof
            *chunk + 8 + *chunk\size
          Else
            *chunk = 0
          EndIf
        Wend
      EndIf
    EndIf
    
    ProcedureReturn image
    
  EndProcedure
  
  Procedure.i Load(fileName.s)
    
    Protected image.i, file.i, fileSize.q, *fileData
    
    file = ReadFile(#PB_Any, fileName)
    If file
      fileSize = Lof(file)
      If fileSize > 0
        *fileData = AllocateMemory(fileSize, #PB_Memory_NoClear)
        If *fileData
          If ReadData(file, *fileData, fileSize)
            image = Catch(*fileData, fileSize)
          EndIf
          FreeMemory(*fileData)
        EndIf
      EndIf
      CloseFile(file)
    EndIf
    
    ProcedureReturn image
    
  EndProcedure
  
EndModule