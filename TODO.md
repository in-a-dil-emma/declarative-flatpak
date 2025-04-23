# Planned
1. option to block the boot process until all flatpaks have been installed
1. do as much as possible without the flatpak cli, using ostree cli instead
1. better ref downloads
    ```
    "flathub:(https://url.flatpakref)"
    ":(https://url.flatpak)"
    ```
1. Fix whatever is causing Issue [#29](https://github.com/GermanBread/declarative-flatpak/issues/29)
1. opt-in telemetry for "stable" branch
1. opt-out telemetry for "dev" branch
1. Move flatpak refs into the Nix store
1. How to make repo reuse faster?
    1. just mv the repo? lol
    1. try reflinks?
1. failure notification to all users in %WHEEL (or group of choice)
    1. notify-send for graphical
    1. wall for TTY
