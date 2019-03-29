# Module TinyIFF

A tiny PureBasic module for loading IFF images, created by [Flype]  (2015):

- [TinyIFF thread on PureBasic English forum][TinyIFF EN]
- [TinyIFF thread on PureBasic French forum][TinyIFF FR]

Permission was granted by its author to reuse the code of **Module TinyIFF** without restrictions.

-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Folder Contents](#folder-contents)
- [TinyIFF Versions](#tinyiff-versions)
- [TinyIFF Supported Formats](#tinyiff-supported-formats)
- [Module Interface](#module-interface)
    - [`TinyIFF::Load()`](#tinyiffload)
    - [`TinyIFF::Catch()`](#tinyiffcatch)
    - [Common Parameters](#common-parameters)

<!-- /MarkdownTOC -->

-----

# Folder Contents

Module TinyIFF sources:

- [`TinyIFF_v1.1.pbi`][1.1 src]
- [`TinyIFF_v1.2.pbi`][1.2 src]
- [`TinyIFF_v1.5.pbi`][1.5 src]
- [`TinyIFF_v1.5_en.pbi`][1.5en src]
- [`TinyIFF24.pbi`][IFF24 src]

Sample image viewers using TinyIFF:

- [`DemoViewerTinyIFF.pb`][viewer src]
- [`DemoViewerTinyIFF24.pb`][viewer24 src]

Precompiled demo viewers (32-bit), for those who don't have PureBasic:

- [`LICENSE`][LICENSE]
- [`DemoViewerTinyIFF.exe`][viewer exe]
- [`DemoViewerTinyIFF24.exe`][viewer24 exe]

> __NOTE__ — The [`LICENSE`][LICENSE] file is required for the binary compiled executables, which rely on third party components used by the PureBasic compiler. Also, inclusion of precompiled binaries in the repository will only occur in the `alpha` branch, and they'll be all purged before squashing into `master`.


# TinyIFF Versions

The sourcecode of **Module TinyIFF** was published in 2015 on PureBasic forums, in both the English and French forums. It was developed using PureBasic 5.40 LTS Beta 3 (x64) Linux, but still compiles with PureBasic 5.70 LTS (x86) Windows without any problems (this being the target compiler required to create PMNG plugins).

Updated versions of the module were published in both threads, some versions being available in one forum and not the other, and viceversa, some versions being in English and others in French. So I've downloaded all of them and renamed them as follows:

| file                                       | date       | origin                          | notes                                        |
| ------------------------------------------ | :--------: | :-----------------------------: | -------------------------------------------- |
| [`TinyIFF_v1.1.pbi`][1.1 src]              | 2015-09-10 | [_link to source_][1.1 EN]      |                                              |
| [`TinyIFF_v1.2.pbi`][1.2 src]              | 2015-09-10 | [_link to source_][1.2 FR]      |                                              |
| [`TinyIFF_v1.5.pbi`][1.5 src]              | 2015-09-17 | [_link to source_][1.5 FR]      | Introduces breaking changes.                 |
| [`TinyIFF_v1.5_en.pbi`][1.5en src]         | 2015-09-17 | (customized)                    | Same as v1.5, except for English comments.   |
| [`TinyIFF24.pbi`][IFF24 src]               | 2015-09-13 | [_link to source_][IFF24 FR]    | Variant focusing on 24-bit IFF ILBM.         |
| [`DemoViewerTinyIFF.pb`][viewer src]       | 2015-09-10 | [_link to source_][viewer FR]   | Only works with TinyIFF up to v1.2           |
| [`DemoViewerTinyIFF24.pb`][viewer24 src]   | 2015-09-13 | [_link to source_][viewer24 FR] | Works with TinyIFF24.                        |

The sourcefile [`TinyIFF_v1.5_en.pbi`][1.5en src] is identical to [`TinyIFF_v1.5.pbi`][1.5 src], except that I've replaced the French comments describing the module procedures and parameters with their English version, [published by the author on the English thread of TinyIFF] for the benefit of English users.


[published by the author on the English thread of TinyIFF]: https://www.purebasic.fr/english/viewtopic.php?p=471869#p471869 "View English versions of procedures descriptions on the original English TinyIFF thread"

# TinyIFF Supported Formats

**Module TinyIFF** is compatible with the following formats:


|         |      format      |       col depth        |        notes        |
|---------|------------------|------------------------|---------------------|
| &check; | FORM ILBM        | 2—256 colors           |                     |
| &check; | FORM ILBM EHB    | 64 colors              |                     |
| &check; | FORM ILBM HAM6   | 4096 colors            |                     |
| &cross; | FORM ILBM SHAM   | 4096—9216 colors       | not yet implemented |
| &check; | FORM ILBM HAM8   | 262144—16777216 colors |                     |
| &check; | FORM ILBM 24bits | 16777216 colors        |                     |
| &check; | FORM PBM 8bits   | 2—256 colors           |                     |
| &check; | FORM PBM 24bits  | 16777216 colors        | not tested          |


# Module Interface

From [`TinyIFF_v1.5_en.pbi`][1.5en src].

```purebasic
;--------------------------------------------------------------------------------------------------
; Module:      TinyIFF.pbi
; Description: A tiny module for loading IFF-ILBM or IFF-PBM images.
; Author:      flype, flype44(at)gmail(dot)com
; Revision:    1.5 (2015-09-17)
; Compiler:    PureBasic 5.40 LTS Beta 3 (x64) Linux
;--------------------------------------------------------------------------------------------------
```

Module TinyIFF exposes two public procedures to load IFF-ILBM or IFF-PBM images:

- `TinyIFF::Load()` — to load an image from file.
- `TinyIFF::Catch()` — to load an image from memory.

Here follows a description of both procedures and their parameters.

## `TinyIFF::Load()`

Load the specified IFF-ILBM or IFF-PBM image from a file.

```purebasic
TinyIFF::Load(ImageID.l,
              FileName$,
              KeepAspect.l = #True,
              ResizeMode.l = #PB_Image_Raw)
```

Parameters:

- `ImageID` — A number to identify the loaded image. `#PB_Any` can be specified to auto-generate this number.
- `FileName$` — The name of the file to load. Can be absolute or relative to the current directory.
- `KeepAspect` — Keep the original aspect (use or not use BitmapHeader xAspect/yAspect).
- `ResizeMode` — The resize method. It can be `#PB_Image_Raw` or `#PB_Image_Smooth`.


## `TinyIFF::Catch()`

Load the specified image from the given memory area.

```purebasic
TinyIFF::Catch(ImageID.l,
               *Memory,
               MemSize.q,
               KeepAspect.l = #True,
               ResizeMode.l = #PB_Image_Raw)
```

Parameters:

- `ImageID` — A number to identify the loaded image. `#PB_Any` can be specified to auto-generate this number.
- `*Memory` — The memory address from which to load the image.
- `MemSize.q` — The size of the image in bytes. The size is mandatory to prevent from corrupted images.
- `KeepAspect` — Keep the original aspect (use or not use BitmapHeader xAspect/yAspect).
- `ResizeMode` — The resize method. It can be `#PB_Image_Raw` or `#PB_Image_Smooth`.


## Common Parameters

Description of some parameters common to both `TinyIFF::Load()` and `TinyIFF::Catch()`, and their allowed values.


- `KeepAspect.l`:
    - `#True` — Keep the original aspect (default if unspecified).
    - `#False` — Resize the image by using the BitmapHeader xAspect/yAspect.

<!--  -->

- `ResizeMode.l`:
    - `#PB_Image_Raw` — Resize the image without any interpolation.
    - `#PB_Image_Smooth` — Resize the image with smoothing (default if unspecified).



<!-----------------------------------------------------------------------------
                               REFERENCE LINKS
------------------------------------------------------------------------------>

<!-- TinyIFF -->

[Flype]: https://www.purebasic.fr/english/memberlist.php?mode=viewprofile&u=414 "View Flype profile on PureBasic forum"

[Module TinyIFF]: https://www.purebasic.fr/french/viewtopic.php?p=175687 "View the TinyIFF announcement thread on PureBasic French forum"
[TinyIFF EN]: https://www.purebasic.fr/english/viewtopic.php?p=471869 "View the TinyIFF announcement thread on PureBasic English forum"
[TinyIFF FR]: https://www.purebasic.fr/french/viewtopic.php?p=175687 "View the TinyIFF announcement thread on PureBasic French forum"


<!-- folder files -->

[1.1 EN]: https://www.purebasic.fr/english/viewtopic.php?p=471263#p471263
[1.1 src]: ./TinyIFF_v1.1.pbi
[1.2 FR]: https://www.purebasic.fr/french/viewtopic.php?p=175687#p175687
[1.2 src]: ./TinyIFF_v1.2.pbi
[1.5 FR]: https://www.purebasic.fr/french/viewtopic.php?p=176024#p176024
[1.5 src]: ./TinyIFF_v1.5.pbi
[1.5en src]: ./TinyIFF_v1.5_en.pbi
[IFF24 FR]: https://www.purebasic.fr/french/viewtopic.php?p=175863#p175863
[IFF24 src]: ./TinyIFF24.pbi
[LICENSE]: ./LICENSE
[viewer exe]: ./DemoViewerTinyIFF.exe
[viewer FR]: https://www.purebasic.fr/english/viewtopic.php?p=471264#p471264
[viewer src]: ./DemoViewerTinyIFF.pb
[viewer24 exe]: ./DemoViewerTinyIFF24.exe
[viewer24 FR]: https://www.purebasic.fr/french/viewtopic.php?p=175863#p175863
[viewer24 src]: ./DemoViewerTinyIFF24.pb

<!-- EOF -->