#!/bin/bash
# Purge leftover KDE Plasma configuration from a home directory that no longer runs Plasma.
#
# Why: the Breeze Qt style, kde-gtk-config's GTK modules and the files Plasma's krdb writes
# (Trolltech.conf, xsettingsd, gtkrc) keep overriding the qt6ct/GTK settings this repo installs,
# so Qt apps end up with dark text on a dark background, light toolbars and the wrong fonts.
#
# Everything removed is archived first to ~/.local/state/kde-config-purge-<date>.tar.gz.
# KDE application settings (dolphinrc, konsolerc, ...) are removed only if that app is not installed.
#
# Usage: tools/purge-kde-config.sh [--dry-run]
set -u
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
DATA=${XDG_DATA_HOME:-$HOME/.local/share}
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}

if command -v plasmashell >/dev/null 2>&1; then
  echo "plasmashell is installed; this would wipe a live Plasma setup. Refusing." >&2; exit 1
fi

# Plasma session, shell, window manager and theming state. Nothing outside Plasma reads these,
# except the Breeze style / kde-gtk-config, which is exactly the problem.
PLASMA_CONFIG=(
  kdeglobals kdeglobals.bak-plasma kdedefaults Trolltech.conf xsettingsd gtkrc gtkrc-2.0
  kcmfonts kcminputrc kconf_updaterc kded5rc kded6rc kglobalshortcutsrc khotkeysrc kxkbrc kgammarc
  kscreenlockerrc ksmserverrc ksplashrc kwinrc kwinrulesrc kwinoutputconfig.json krunnerrc
  ktimezonedrc kactivitymanagerdrc kactivitymanagerd-statsrc kmenueditrc kfontinstuirc
  systemsettingsrc powerdevilrc baloofilerc baloofileinformationrc discoverrc PlasmaDiscoverUpdates
  PlasmaUserFeedback plasma-localerc plasma-nm plasmanotifyrc plasma-org.kde.plasma.desktop-appletsrc
  plasmaparc plasmarc plasmashellrc plasma-welcomerc plasma-workspace KDE kde.org
  xdg-desktop-portal-kderc drkonqirc drkonqi-coredump-launcher.notifyrc kiorc ktrashrc kmixrc
  kmousetool_strokes.txt
)
PLASMA_DATA=(
  plasma plasma_icons plasma_notes plasma-systemmonitor session_migration-plasma kded5 kded6
  kscreen kxmlgui5 kactivitymanagerd klipper krunnerstaterc drkonqi baloo
)
PLASMA_CACHE=(
  icon-cache.kcache kwinsession.kcache kwin KScreen kscreen_osd_service kscreenlocker_greet ksplash
  ksmserver-logout-greeter kded6 krunner kcmshell5 kcmshell6 kinfocenter kpackage-knshandler
  ksvg-elements xdg-desktop-portal-kde polkit-kde-authentication-agent-1 KDE kcrash-metadata
  plasma-keyboard plasmashell plasma.emojier plasma-systemmonitor bookmarksrunner
)
# "binary:config file" pairs, removed only when the binary is gone.
APP_CONFIG=(
  dolphin:dolphinrc gwenview:gwenviewrc spectacle:spectaclerc konsole:konsolerc konsole:konsolesshconfig
  kate:katerc kate:kateschemarc kate:katevirc kwrite:kwriterc kolourpaint:kolourpaintrc kamoso:kamosorc
  krdc:krdcrc krfb:krfbrc khelpcenter:khelpcenterrc kmail:kmail2rc kmail:kmailsearchindexingrc
  kdeconnectd:kdeconnect okular:okularrc kdialog:kdialogrc kwalletd6:kwalletrc kwalletd6:kwalletmanager5rc
)

targets=()
for f in "${PLASMA_CONFIG[@]}"; do [ -e "$CFG/$f" ] && targets+=("$CFG/$f"); done
for f in "${PLASMA_DATA[@]}";   do [ -e "$DATA/$f" ] && targets+=("$DATA/$f"); done
for f in "${PLASMA_CACHE[@]}";  do [ -e "$CACHE/$f" ] && targets+=("$CACHE/$f"); done
for f in "$CACHE"/ksycoca* "$CACHE"/plasma_theme_*.kcache "$HOME/.gtkrc-2.0"; do [ -e "$f" ] && targets+=("$f"); done
for pair in "${APP_CONFIG[@]}"; do
  bin=${pair%%:*}; f=${pair#*:}
  [ -e "$CFG/$f" ] && ! command -v "$bin" >/dev/null 2>&1 && targets+=("$CFG/$f")
done

if [ ${#targets[@]} -eq 0 ]; then echo "Nothing to purge."; else
  printf '%s\n' "${targets[@]}"
  if [ $DRY = 1 ]; then echo "(dry run: ${#targets[@]} entries, nothing removed)"; else
    mkdir -p "$HOME/.local/state"
    ar="$HOME/.local/state/kde-config-purge-$(date +%Y-%m-%d-%H%M).tar.gz"
    tar czf "$ar" --ignore-failed-read -C / "${targets[@]#/}" 2>/dev/null
    rm -rf "${targets[@]}"
    echo "Removed ${#targets[@]} entries, archived to $ar"
  fi
fi

# kde-gtk-config injects these GTK modules; they re-apply Plasma colours and decorations to GTK apps.
for ini in "$CFG/gtk-3.0/settings.ini" "$CFG/gtk-4.0/settings.ini"; do
  if [ -f "$ini" ] && grep -q '^gtk-modules=.*\(colorreload\|window-decorations\)' "$ini"; then
    echo "Dropping gtk-modules line from $ini"
    [ $DRY = 1 ] || sed -i '/^gtk-modules=.*\(colorreload\|window-decorations\)/d' "$ini"
  fi
done

[ $DRY = 1 ] || echo "Done. Restart Qt apps (pcmanfm-qt is single-instance: pkill pcmanfm-qt first)."
