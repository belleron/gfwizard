# Git Flow wizard
This script utilizes the git flow methodology and provides easy text based (BASH) wizard for developers.
[http://nvie.com/posts/a-successful-git-branching-model/]
* For some features PHP-CLI is required

#### Versioning
The version numbering used here and utilized by the wizard is {major}.{minor}.{hotfix}.{build}

#### The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

## Installation
1. Clone this repository to a folder included in your PATH ($HOME/bin can be fine, if not used yet)
1. Copy .gfconfig.dist to .gfconfig and change content according to your environment
1. Run ./gf-install.sh
	* It installs the submodules in use
	* Installs daily cron for the install script itself to track updates automatically
1. Restart your shell (logoff - logon / terminal close & open etc.)
1. use either the `gf` alias or `git gf` command to open the wizard

## Usage
1. Create folder for your project and cd into it
1. Run `gf` wizard and init your project
1. Follow commands / Enjoy ;)

## Change Log

### Version 2.00.00
* **Feature**: Removed all proprietry code. Set to MIT Licence

