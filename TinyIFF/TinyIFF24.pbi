; source: https://www.purebasic.fr/french/viewtopic.php?p=175863#p175863
;----------------------------------------------------------
; Name:        Module TinyIFF24.pbi
; Description: A tiny module for loading 24bits IFF images.
; Author:      flype, flype44(at)gmail(dot)com
; Revision:    1.0 (2015-09-13)
;----------------------------------------------------------

DeclareModule TinyIFF24
  Declare Load(fileName.s)
  Declare Catch(*memory, size.q)
EndDeclareModule

Module TinyIFF24
  
  EnableExplicit
  
  #ID_FORM = $4D524F46
  #ID_ILBM = $4D424C49
  #ID_BMHD = $44484D42
  #ID_BODY = $59444F42
  
  Macro UINT16(a)
    ((((a)<<8)&$FF00)|(((a)>>8)&$FF))
  EndMacro
  
  Macro UINT32(a)
    ((((a)&$FF)<<24)|(((a)&$FF00)<<8)|(((a)>>8)&$FF00)|(((a)>>24)&$FF))
  EndMacro
  
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
  
  Procedure UnPackBits(*bmhd.IFF_BMHD, *packedBits.BYTES, packedSize, rowBytes)
    
    Protected i, j, k, v, unpackedSize, *unpackedBits.BYTES
    
    unpackedSize = 1 + ( *bmhd\h * rowBytes * *bmhd\nPlanes )
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
  
  Procedure Catch(*m.IFF_Header, size.q)
    
    Protected image, col, row, plane, bits, rowBytes, totalBytes
    Protected *ck.IFF_Chunk, *bh.IFF_BMHD, *bp.UBYTES, *eof, *bodyUnpacked
    
    If *m And *m\code = #ID_FORM And *m\format = #ID_ILBM
      *m\size = UINT32(*m\size)
      If *m\size > 0 And *m\size < size
        *eof = *m + size
        *ck = *m\chunk
        While *ck
          *ck\size = UINT32(*ck\size)
          If *ck\size & 1
            *ck\size + 1
          EndIf
          Select *ck\code
            Case #ID_BMHD
              *bh = *ck\bytes
              *bh\w = UINT16(*bh\w)
              *bh\h = UINT16(*bh\h)
              rowBytes = ( ( (*bh\w + 15 ) / 16 ) * 2 )
            Case #ID_BODY
              *bp = *ck\bytes
              If *bh\compression = 1
                *bodyUnpacked = UnPackBits(*bh, *ck\bytes, *ck\size, rowBytes)
                *bp = *bodyUnpacked
              EndIf
              If *bp And *bh And *bh\nPlanes = 24
                image = CreateImage(#PB_Any, *bh\w, *bh\h)
                If image
                  Protected Dim m(*bh\w)
                  Protected Dim r(*bh\w)
                  Protected Dim g(*bh\w)
                  Protected Dim b(*bh\w)
                  For col = 0 To *bh\w - 1
                    m(col) = 128 >> ( col % 8 )
                  Next
                  If StartDrawing(ImageOutput(image))
                    For row = 0 To *bh\h - 1
                      For plane = 0 To 23
                        If plane < 8
                          bits = 1 << plane
                          For col = 0 To *bh\w - 1
                            If *bp\b[col >> 3] & m(col)
                              r(col) | bits
                            EndIf
                          Next
                        ElseIf plane > 15
                          bits = 1 << ( plane - 16 )
                          For col = 0 To *bh\w - 1
                            If *bp\b[col >> 3] & m(col)
                              b(col) | bits
                            EndIf
                          Next
                        Else
                          bits = 1 << ( plane - 8 )
                          For col = 0 To *bh\w - 1
                            If *bp\b[col >> 3] & m(col)
                              g(col) | bits
                            EndIf
                          Next
                        EndIf
                        *bp + rowBytes
                      Next
                      For col = 0 To *bh\w - 1
                        Plot(col, row, RGB(r(col), g(col), b(col)))
                        r(col) = 0
                        g(col) = 0
                        b(col) = 0
                      Next
                    Next
                    StopDrawing()
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
  
  Procedure Load(fileName.s)
    
    Protected image.i, file.i, fileSize.q, *fileData
    
    file = ReadFile(#PB_Any, fileName)
    If file
      fileSize = Lof(file)
      If fileSize > 0
        *fileData = AllocateMemory(fileSize, #PB_Memory_NoClear)
        If *fileData
          If ReadData(file, *fileData, fileSize) > 0
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