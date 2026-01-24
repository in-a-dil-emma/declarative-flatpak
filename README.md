# Declarative flatpaks

Declaratively manage Flatpak installations in NixOS and your $HOME

> [!CAUTION]
> Expect at least a 2x storage usage increase.
> This module *attempts* to optimize storage space use through reflinks, these require a filesystem capable of Copy-on-Write.

> [!IMPORTANT]
> The home-manager module assumes that flatpak is usable on your system.
> If this is not the case, do not bug report.

> [!IMPORTANT]
> The setup script performs changes in a transaction.
> Errors cause the transaction to fail immediately.
> Only successful transactions get applied.
> Therefore, it may take a while until your changes take effect!

Also try https://github.com/gmodena/nix-flatpak

## Setup

### Inputs

<details open>
<summary>
Flakes
</summary>

`flake.nix`
```nix
{
  inputs = {
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/latest";
  };
}
```

</details>

<details open>
<summary>
npins
</summary>

console
```console
$ npins add github --name flatpaks in-a-dil-emma declarative-flatpak
```

</details>

### Import in NixOS

<details open>
<summary>
Flakes
</summary>

`configuration.nix`
```nix
{ flatpaks, ... }: {
  imports = [
    flatpaks.nixosModules.default
  ];
}
```

</details>

<details open>
<summary>
npins
</summary>

`configuration.nix`
```nix
{ flatpaks, ... }: {
  imports = [
    (flatpaks + "/nixos")
  ];
}
```

</details>

### Import in Home Manager (standalone or as a NixOS module)

<details open>
<summary>
Flakes
</summary>

`home.nix`
```nix
{ flatpaks, ... }: {
  imports = [
    flatpaks.homeModules.default
  ];
}
```

</details>

<details>
<summary>
npins
</summary>

`home.nix`
```nix
{ flatpaks, ... }: {
  imports = [
    (flatpaks + "/home-manager")
  ];
}
```

</details>

## Versioning

Releases are done through git tags.

## Configuring

<details>
<summary>services → <b>flatpak</b></summary>

| OPTION                   | TYPE           | DEFAULT                                                                  |
|--------------------------|----------------|--------------------------------------------------------------------------|
| enable                   | boolean        | false                                                                    |
| preRemotesCommand        | string or null | null                                                                     |
| preInstallCommand        | string or null | null                                                                     |
| preSwitchCommand         | string or null | null                                                                     |
| UNCHECKEDfinalizeCommand | string or null | null                                                                     |
| flatpakDir               | path or null   | NixOS: `/var/lib/flatpak` ; <br>Home-Manager: `${XDG_DATA_HOME}/flatpak` |
| forceRunOnActivation     | boolean        | false                                                                    |
| onCalendar               | systemd time   | weekly                                                                   |

> [!CAUTION]
> `UNCHECKEDfinalizeCommand` will not cause the transaction to fail.
> This hook should only be used for commands you don't care about failing.

</details>

<details>
<summary>... → packages → <b><ins>list element</ins></b></summary>

<ins>list element</ins> is a string, matching one of the following patterns:

- `{remote}:{type}/{ref}/[{arch}]/{branch}[:{commit}]`
- `{remote}:{path}.flatpakref`
- `:{path}.flatpak`

Expressions in `[angle brackets]` may be omitted.
Expressions in `{curly brackets}` must be substituted.

| KEY    | SUBSTITUTION DESCRIPTION                              |
|--------|-------------------------------------------------------|
| remote | The remote to fetch from.                             |
| type   | Ref type. Either `app` or `runtime`.                  |
| ref    | Ref ID used by flatpak.                               |
| arch   | System architecture, in flatpak's format.             |
| branch | Ref release branch.                                   |
| commit | Update to commit. Must be exactly 64 characters long. |
| path   | A path that exists.                                   |

</details>

<details>
<summary>... → remotes → <b><ins>key-value pair</ins></b></summary>

| KEY  | VALUE |
|------|-------|
| Name | URL   |

</details>

<details>
<summary>... → overrides → <b><ins>key-value pair</ins></b></summary>

| KEY      | VALUE                                                                                  |
|----------|----------------------------------------------------------------------------------------|
| Filename | See https://docs.flatpak.org/en/latest/flatpak-command-reference.html#flatpak-metadata |

</details>

<details>
<summary>Example configuration.</summary>

```nix
{
  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "flathub-beta" = "https://dl.flathub.org/beta-repo/flathub-beta.flatpakrepo";
    };
    packages = [
      "flathub:app/org.kde.index//stable"
      "flathub-beta:app/org.kde.kdenlive/x86_64/stable"
      ":${./foobar.flatpak}"
      "flathub:/root/testflatpak.flatpakref"
    ];
    overrides = {
      # note: "global" is a flatpak thing
      # if you ever ran "flatpak override" without specifying a ref you will know
      "global".Context = {
        filesystems = [
          "home"
        ];
        sockets = [
          "!x11"
          "!fallback-x11"
        ];
      };
      "org.mozilla.Firefox" = {
        Environment = {
          "MOZ_ENABLE_WAYLAND" = 1;
        };
        Context.sockets = [
          "!wayland"
          "!fallback-x11"
          "x11"
        ];
      };
    };
  };
}
```

</details>

Please consult [the module options](module/options.nix) for more information.

