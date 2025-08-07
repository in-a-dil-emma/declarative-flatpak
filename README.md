# Declarative flatpaks

## Setup

### Inputs

<details open>
<summary>
Flakes
</summary>

```nix
{
  inputs = {
    flatpaks.url = "github:in-a-dil-emma/declarative-flatpak/stable-v3";
  };
}
```

</details>

<details>
<summary>
npins
</summary>

```console
$ npins add github --name flatpaks in-a-dil-emma declarative-flatpak -b stable-v3
```

</details>

### Import in NixOS

<details open>
<summary>
Flakes
</summary>

```nix
{ flatpaks, ... }: {
  imports = [
    flatpaks.nixosModule
  ];
}
```

</details>

<details>
<summary>
npins
</summary>

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

```nix
{ flatpaks, ... }: {
  imports = [
    flatpaks.homeModule
  ];
}
```

</details>

<details>
<summary>
npins
</summary>

```nix
{ flatpaks, ... }: {
  imports = [
    (flatpaks + "/home-manager")
  ];
}
```

</details>

## Versioning

<details open>

You will get notified in time when a stable branch gets obsoleted.

| BRANCH    | DESCRIPTION                                         | REPORT BUGS? |
|-----------|-----------------------------------------------------|--------------|
| stable-v1 | First working release.                              | NO           |
| stable-v2 | Added pseudo-generations.                           | NO           |
| stable-v3 | v2, but more resilient, faster and space efficient. | YES          |
| dev       | Development branch.                                 | YES          |

</details>

## Configuring

<details>
<summary>services → <b>flatpak</b></summary>

| OPTION                         | TYPE           | DEFAULT |
|--------------------------------|----------------|---------|
| enable                         | boolean        | false   |
| preRemotesCommand              | string or null | null    |
| preInstallCommand              | string or null | null    |
| preSwitchCommand               | string or null | null    |
| UNCHECKEDpostEverythingCommand | string or null | null    |
| flatpakDir                     | path or null   | depends |
| forceRunOnActivation           | boolean        | false   |
| onCalendar                     | systemd time   | weekly  |

</details>

<details>
<summary>... → packages → <b><ins>list element</ins></b></summary>

<ins>list element</ins> is a string, matching one of the following patterns:

- `{remote}:{type}/{ref}[/{arch}]/{branch}[:{commit}]`
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

| KEY      |
|----------|
| Filename |

VALUE:

| OPTION      | TYPE            | DESCRIPTION                              |
|-------------|-----------------|------------------------------------------|
| filesystems | list of strings | paths prefixed with ! will deny access   |
| sockets     | list of strings | sockets prefixed with ! will deny access |
| environment | key-value pair  |                                          |

</details>

<details>
<summary>Special case: services → flatpak → <b>flatpakDir</b></summary>

| MODULE TYPE  | DEFAULT                    |
|--------------|----------------------------|
| NixOS        | /var/lib/flatpak           |
| Home Manager | ${XDG\_DATA\_HOME}/flatpak |

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
      global = {
        filesystems = [
          "home"
        ];
        sockets = [
          "!x11"
          "!fallback-x11"
        ];
      };
      "org.mozilla.Firefox" = {
        environment = {
          "MOZ_ENABLE_WAYLAND" = 1;
        };
        sockets = [
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

---

> [!NOTE]
> Your setup must be able to hold the size of your flatpak installation at least twice.
