# linux-tools
## Description
A collection of personal scripts for day-to-day Linux administration.  
Git helpers, Sylius/Symfony/PHP inspection, shell utilities, and autostart tweaks.

## Table of contents
- [Description](#description)
- [Table of contents](#table-of-contents)
- [Getting started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Technologies used](#technologies-used)
  - [Installation and run](#installation-and-run)
- [Usage](#usage)
- [Help](#help)
- [Author](#author)
- [License](#license)

## Getting started
### Prerequisites
- `Bash`
- `Python 3`
- Tested on Ubuntu/Linux.

### Technologies used
![Bash](https://img.shields.io/badge/Bash-4eab25?logo=bash&logoColor=fff)
![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=fff)

### Installation and run
1. Clone the repository.
```bash
git clone https://github.com/Franck-dev-hub/linux-tools
cd linux-tools
```

2. Import scripts using the `install.sh` file
```bash
chmod +x install.sh && ./install.sh
```

3. Create aliases (zsh)
```bash
echo "alias mkfile='~/.local/share/scripts/mkfile.sh'" >> ~/.zshrc
```

## Usage
Each script is self-contained and documented with a header comment describing its globals, arguments, and outputs
After alias creation, you just have to call your alias in cli

## Help
If you encounter issues, ensure:
- The script has execute permission (`chmod +x`).
- For `sylius` tools, that `composer` is installed and you're inside a Composer project folder.
- For additional help, refer to the source code or contact the authors.

## Author
- **[Franck S.](https://github.com/Franck-dev-hub)**

## License
This project is licensed under GNU AGPL v3.0 - see the LICENSE file for details.
