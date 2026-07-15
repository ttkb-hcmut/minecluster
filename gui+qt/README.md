## Build

Start a nix shell session in this subdirectory.

## Build manually

It's possible to step out of our nix shell build program, you can follow the steps yourself by investigating the nix shell whose source is [`./shell.nix`](./shell.nix).

Notes:
 - `lablqml` requires `moc`, the Meta-Object Compiler program of Qt, which comes from the `qtbase` package.
 - `lablqml` requires `Qt5Quick` which comes from the `qt5-quickcontrols2-devel` package.
