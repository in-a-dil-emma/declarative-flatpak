{ config, pkgs, lib, ... }:

let
  inherit (pkgs) curl coreutils util-linux gnugrep flatpak gawk rsync ostree systemd findutils gnused diffutils writeShellScript writeText;
  inherit (builtins) concatStringsSep map filter toJSON match attrValues mapAttrs attrNames;
  inherit (lib) makeBinPath optionalString;

  inherit (import ../lib/regexes.nix) fcommit fref ffile fremote ftype farch fbranch;

  cfg = config.services.flatpak;
  is-hm = config ? home && lib ? hm;
  filecfg = writeText "flatpak-gen-config" (toJSON {
    inherit (cfg) overrides packages remotes flatpakDir preRemotesCommand preInstallCommand preSwitchCommand UNCHECKEDpostEverythingCommand;
  });
  system-user-switch = if is-hm then "--user" else "--system";
  script = {
    config-diff = optionalString (!cfg.forceRunOnActivation) ''
      if [ -e "$DATA_DIR/config" ] && cmp -s ${filecfg} "$DATA_DIR/config"; then
        echo "Configs do not differ, therefore I won't do anything. You may change this default behaviour"
        exit 0
      fi
    '';
    setup = ''
      set -vx
      set -eu
      shopt -s extglob nullglob

      PATH="${makeBinPath [ curl coreutils util-linux gnugrep flatpak gawk rsync ostree systemd findutils gnused diffutils ]}"

      LANG=C
      MODULE_DIR_INFIX=".module"
      CURR_BOOTID=$(journalctl --list-boots --no-pager | grep -E '^ +0' | awk '{print$2}') || \
        CURR_BOOTID=1

      CURRENT_FLATPAK_DIR="${cfg.internal.targetDir}"
      ${optionalString (cfg.flatpakDir != null) ''
      CURRENT_FLATPAK_DIR="${cfg.flatpakDir}"
      ''}

      DATA_DIR="$CURRENT_FLATPAK_DIR/$MODULE_DIR_INFIX"

      NEW_FLATPAK_INSTALL="$DATA_DIR/new"

      export FLATPAK_USER_DIR="$NEW_FLATPAK_INSTALL"
      export FLATPAK_SYSTEM_DIR="$NEW_FLATPAK_INSTALL"

      TRASH_DIR="$DATA_DIR/trash/$CURR_BOOTID/$(uuidgen)"

      trap 'touch "$DATA_DIR"/repo-dirty' ERR
    '';
    dirs = ''
      rm -rf "$DATA_DIR"/repo-save
      rm -rf "$DATA_DIR"/install-data

      # we can try recycling the in-progress repo
      if [ -d "$NEW_FLATPAK_INSTALL"/repo ]; then
        echo "Found in-progress state, we can recycle it"
        mv "$NEW_FLATPAK_INSTALL"/repo "$DATA_DIR"/repo-save
      fi

      rm -rf "$NEW_FLATPAK_INSTALL"

      systemd-run ${system-user-switch} rm -rf "$DATA_DIR"/trash/!("$CURR_BOOTID")
      mkdir -pm 755 "$DATA_DIR"
      mkdir -pm 755 "$NEW_FLATPAK_INSTALL"
      mkdir -pm 755 "$CURRENT_FLATPAK_DIR"
      mkdir -pm 755 "$TRASH_DIR"

      mkdir -p "$DATA_DIR"/install-data
      mkdir -p "$NEW_FLATPAK_INSTALL"/overrides
    '';
    recycle-repo = ''
      if [ -e "$DATA_DIR"/repo-dirty ]; then
        echo "Service did not shut down clean. NOT recycling previous runs"
        rm -f "$DATA_DIR"/repo-dirty
      else
        touch "$DATA_DIR"/repo-dirty
        if [ -d "$DATA_DIR"/repo-save ]; then
          mv "$DATA_DIR"/repo-save "$NEW_FLATPAK_INSTALL"/repo
        elif [ -d "$CURRENT_FLATPAK_DIR"/repo ]; then
          echo "Recycling existing repo"
          cp -al --reflink=auto "$CURRENT_FLATPAK_DIR"/repo "$NEW_FLATPAK_INSTALL"/repo
        else
          ostree init --repo="$NEW_FLATPAK_INSTALL/repo" --mode=bare-user-only
        fi
        rm -rf \
          "$NEW_FLATPAK_INSTALL"/repo/refs \
          "$NEW_FLATPAK_INSTALL"/repo/extensions
        mkdir -p \
          "$NEW_FLATPAK_INSTALL"/repo/refs/{heads,mirrors,remotes} \
          "$NEW_FLATPAK_INSTALL"/repo/extensions
        ostree remote list --repo="$NEW_FLATPAK_INSTALL/repo" | while read r; do
          ostree remote delete --repo="$NEW_FLATPAK_INSTALL/repo" --if-exists "$r"
        done
        rm -f "$DATA_DIR"/repo-dirty
      fi
    '';
    add-remotes = toString (attrValues (mapAttrs (name: value: ''
      echo "Adding remote ${name} with URL ${value}"
      flatpak ${system-user-switch} remote-add --if-not-exists "${name}" "${value}" || exit 1
    '') cfg.remotes));
    prep-install = ''
      counter=0

      for i in ${toString (filter (x: match ".+${ffile}$" x == null) cfg.packages)}; do
        _remote="$(grep -Eo '^${fremote}' <<< $i)"
        _id="$(grep -Eo '${ftype}/${fref}/${farch}/${fbranch}(:${fcommit})?' <<< $i)"
        _commit="$(grep -Eo ':${fcommit}$' <<< $_id)" || true
        if [ -n "$_commit" ]; then
          _commit=$(tail -c-$(($(wc -c <<< $_commit) - 1)) <<< $_commit)
          _id=$(head -c-$(($(wc -c <<< $_commit) + 1)) <<< $_id)
        fi

        mkdir -p "$DATA_DIR"/install-data/"$_remote"/$counter
        echo -n "$_id" >>"$DATA_DIR"/install-data/"$_remote"/$counter/id
        [ -n "$_commit" ] && echo -n "$_commit" >>"$DATA_DIR"/install-data/"$_remote"/$counter/commit

        : $(( counter++ ))
      done

      unset counter
    '';
    install-remote = ''
      pushd "$DATA_DIR"/install-data
      for rem in *; do
        pushd "$DATA_DIR"/install-data/"$rem"

        ref_list=()
        for ref in *; do
          _id="$(<"$ref"/id)"

          ref_list+=("$_id")
        done
        echo "|$rem|''${ref_list[*]}|"

        for (( i = 0; i < ''${#ref_list[@]}; i += 10 )); do
          flatpak ${system-user-switch} install --noninteractive --no-auto-pin "$rem" "''${ref_list[@]:i:10}" || exit 1
        done

        unset ref_list

        for ref in *; do
          [ ! -e "$ref"/commit ] && continue

          _id="$(<"$ref"/id)"
          _commit="$(<"$ref"/commit)"

          if ! flatpak update --commit="$_commit" "$_id"; then
            echo "Failed to update ref $_id to commit $_commit. Verified if the commit is correct"
          fi
        done

        popd
      done
      popd
    '';
    install-local = ''
      echo "Installing out-of-tree refs"
      for i in ${toString (filter (x: match ":.+\.flatpak$" x != null) cfg.packages)}; do
        _id="$(grep -Eo ':.+\.flatpak$' <<< $i | tail -c+2)"

        flatpak ${system-user-switch} install --noninteractive --no-auto-pin "$_id" || exit 1
      done
      for i in ${toString (filter (x: match ":.+\.flatpakref$" x != null) cfg.packages)}; do
        _remote="$(grep -Eo '^${fremote}:' <<< $i | head -c-2)"
        _id="$(grep -Eo ':.+\.flatpakref$' <<< $i | tail -c+2)"

        flatpak ${system-user-switch} install --noninteractive --no-auto-pin "$_remote" "$_id" || exit 1
      done
    '';
    prune-ostree = ''
      #ostree fsck --repo="$NEW_FLATPAK_INSTALL"/repo
      ostree prune --repo="$NEW_FLATPAK_INSTALL"/repo --refs-only
      ostree prune --repo="$NEW_FLATPAK_INSTALL"/repo
    '';
    overrides = ''
      echo "Installing overrides"

      ${concatStringsSep "\n" (map (ref: ''
        cat ${cfg.overrides.${ref}.source} >"$NEW_FLATPAK_INSTALL"/overrides/"${ref}"
      '') (attrNames cfg.overrides))}
    '';
    exports = optionalString (cfg.flatpakDir != null) ''
      if [ -d "$NEW_FLATPAK_INSTALL"/exports ]; then
        # Dereference because exports are symlinks by default
        rsync -aL --remove-source-files "$NEW_FLATPAK_INSTALL"/exports "$NEW_FLATPAK_INSTALL"/processed-exports

        # Then begin "processing" the exports to make them point to the correct locations
        [ -d "$NEW_FLATPAK_INSTALL"/processed-exports/bin ] && \
          find "$NEW_FLATPAK_INSTALL"/processed-exports/bin \
            -type f -exec sed -i "s,exec flatpak run,FLATPAK_USER_DIR=\"$CURRENT_FLATPAK_DIR\" FLATPAK_SYSTEM_DIR=\"$CURRENT_FLATPAK_DIR\" exec flatpak run,gm" '{}' \;
        [ -d "$NEW_FLATPAK_INSTALL"/processed-exports/share/applications ] && \
          find "$NEW_FLATPAK_INSTALL"/processed-exports/share/applications \
            -type f -exec sed -i "s,Exec=flatpak run,Exec=env FLATPAK_USER_DIR=\"$CURRENT_FLATPAK_DIR\" FLATPAK_SYSTEM_DIR=\"$CURRENT_FLATPAK_DIR\" flatpak run,gm" '{}' \;

        mv "$NEW_FLATPAK_INSTALL"/processed-exports "$NEW_FLATPAK_INSTALL"/exports
      fi
    '';
      echo "Installing flatpak data"
    switch = ''
      echo "Moving old data for future deletion"
      mv "$CURRENT_FLATPAK_DIR"/!("$MODULE_DIR_INFIX"|db) "$TRASH_DIR"

      touch "$DATA_DIR"/repo-dirty
      pushd "$NEW_FLATPAK_INSTALL"
      for i in *; do
        rsync -a --remove-source-files --delete "$i"/ "$CURRENT_FLATPAK_DIR"/"$i"/ &
      done
      popd
      wait
      rm -f "$DATA_DIR"/repo-dirty
      ln -snfT ${filecfg} "$DATA_DIR"/config
      rm -rf "$NEW_FLATPAK_INSTALL"
      unset FLATPAK_USER_DIR FLATPAK_SYSTEM_DIR
    '';
  };
in {
  config.services.flatpak.internal.mainScript = {
    activation = writeShellScript "setup-flatpaks" (concatStringsSep "\n" [
      script.setup
      script.config-diff
      config.services.flatpak.internal.mainScript.auto
    ]);
    auto = writeShellScript "setup-flatpaks" (concatStringsSep "\n" [
      script.setup
      script.dirs
      script.recycle-repo
      cfg.preRemotesCommand
      script.add-remotes
      cfg.preInstallCommand
      script.prep-install
      script.install-remote
      script.install-local
      cfg.preSwitchCommand
      script.prune-ostree
      script.overrides
      script.exports
      script.switch
      cfg.UNCHECKEDpostEverythingCommand
    ]);
  };
}
