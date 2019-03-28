# Pro Motion Amiga IFF

    Pro Motion NG 7.1.8 | PureBasic 5.70 LTS

A [Pro Motion NG] plugin to support Amiga IFF images, written in [PureBasic].

- https://github.com/tajmone/pmotion-amiga-iff

Copyright © 2019 Tristano Ajmone, [MIT License]. Based on Flype's **[Module TinyIFF]** (permission granted).


-----

**Table of Contents**

<!-- MarkdownTOC autolink="true" bracket="round" autoanchor="false" lowercase="only_ascii" uri_encoding="true" levels="1,2,3" -->

- [Project Contents](#project-contents)
- [Project Status](#project-status)
    - [About the Alpha Stage and Branch](#about-the-alpha-stage-and-branch)
- [System Requirements](#system-requirements)
    - [Compiling File I/O Plugins](#compiling-file-io-plugins)
- [License and Credits](#license-and-credits)

<!-- /MarkdownTOC -->

-----

# Project Contents

- [`/TinyIFF/`](./TinyIFF) — sources of [Module TinyIFF].
- [`pmotion_file-io.pb`][pmotion_file-io.pb] — file i/o plugin boilerplate.
- [`LICENSE`][LICENSE] — MIT License.


# Project Status

Currently the project is in early Alpha stage.

The code from the TinyIFF module needs to be readapted to fit the [`pmotion_file-io.pb`][pmotion_file-io.pb] plugin boilerplate (taken from the [pmotion-purebasic] project), and all the required plugin DLL procedures and internal code needs to be written.


## About the Alpha Stage and Branch

For the whole duration of the Alpha development stage all commits will be in the `alpha` branch, which will ultimately be squashed into `master` when the first stable release is reached.

Furthermore, the Alpha branch will/might contain the binary compiled files of the project (plugin DLL, an others) to compensate the lack of releases (which on GitHub allows attaching archives with precompiled binaries). Before squashing into `master` all binaries will be deleted and the project will ignore them from thereon.

# System Requirements

To create the PMNG plugin and compile other resources in this project, you'll need [PureBasic] v5.70 LTS x86, which is a commercial product by Fantaisie Software.

- https://www.purebasic.com

## Compiling File I/O Plugins

File I/O plugins must be compiled with the following settings in the PureBasic IDE (or the command line):

- Windows x86 (32 bit)
- DLL executable, non threadsafe.

Once you've compiled your plugin DLL, you only need to copy it into the `plugins` subfolder in the installation directory of Pro Motion. Depending on the bitness of your Windows operating system, the path of the `plugins` folder will be either:

- 32 bit OS: `%ProgramFiles%\cosmigo\Pro Motion NG\plugins\`
- 64 bit OS: `%ProgramFiles(x86)%\cosmigo\Pro Motion NG\plugins\`

Any plugins inside that folder will be automatically detected when Pro Motion is launched, and made available in the file load/save and import/export dialogs according to where the plugin functionality fits in PMNG context.
This means that during development, whenever you updated/recompile your DLL you'll have to close and restart PM.

Since PM is a 32 bit application, the plugin DLL must also be compiled as 32 bit.

# License and Credits

- [`LICENSE`][LICENSE]

This project is © 2019 by Tristano Ajmone, released under the MIT License.

The project utilizes the code from [Flype]'s **[Module TinyIFF]**, who kindly granted me permission to reuse and adapt his code without restrictions.


```
MIT License

Copyright (C) 2019 Tristano Ajmone <tajmone@gmail.com>
                   https://github.com/tajmone/pmotion-amiga-iff

Based on "Module TinyIFF", Copyright (C) 2015 by Flype (permission granted):
https://www.purebasic.fr/french/viewtopic.php?p=175687

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```


<!-----------------------------------------------------------------------------
                               REFERENCE LINKS                                
------------------------------------------------------------------------------>

[PureBasic]: https://www.purebasic.com/ "Visit PureBasic website"
[MIT License]: ./LICENSE "View MIT License file"

[pmotion-purebasic]: https://github.com/tajmone/pmotion-purebasic "Visit the Pro Motion PureBasic repository on GitHub"

<!-- project files -->

[LICENSE]: ./LICENSE "View MIT License file"
[pmotion_file-io.pb]: ./pmotion_file-io.pb "View source file"

<!-- Cosmigo & PM -->

[Pro Motion NG]: https://www.cosmigo.com/ "Visit Pro Motion NG website"

<!-- TinyIFF -->

[Flype]: https://www.purebasic.fr/english/memberlist.php?mode=viewprofile&u=414 "View Flype profile on PureBasic forum"

[Module TinyIFF]: https://www.purebasic.fr/french/viewtopic.php?p=175687 "View the TinyIFF announcement thread on PureBasic French forum"
[TinyIFF EN]: https://www.purebasic.fr/english/viewtopic.php?p=471869 "View the TinyIFF announcement thread on PureBasic English forum"
[TinyIFF FR]: https://www.purebasic.fr/french/viewtopic.php?p=175687 "View the TinyIFF announcement thread on PureBasic French forum"

<!-- EOF -->