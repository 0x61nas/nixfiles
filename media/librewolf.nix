{ pkgs, pkgs-unstable, ... }:

let
  bookmarks = [ ];
in
{
  programs.librewolf = {
    enable = true;
    package = pkgs-unstable.librewolf.override {
      nixExtensions = with pkgs.firefox-addons; [
        ublock-origin
        foxytab
        keepassxc-browser
        sponsorblock
        single-file
        auto-tab-discard
        control-panel-for-twitter
        material-icons-for-github
        crxviewer
        pixiv-toolkit
        privacy-extension-for-whatsapp
        readeck
        return-youtube-dislikes
        styl-us
        tab-session-manager
        besttimetracker # Track time, analyze your habits and block addictive sites
        traduzir-paginas-web # Translate your page in real time using Google, Bing or Yandex.
        youtube-recommended-videos # Hide YouTube related videos, comments, video suggestions wall, homepage recommendations, trending tab, and other distractions.
        wayback-machine_new # Wayback Machine
      ];

      # Extra prefs can be found at `about:config`.
      extraPrefs = /* javascript */ ''
        pref("accessibility.force_disabled", 1);
        pref("browser.aboutConfig.showWarning", false);
        pref("browser.bookmarks.addedImportButton", false);
        pref("browser.migrate.bookmarks-file.enabled", false);
        pref("browser.shell.checkDefaultBrowser", false);
        pref("browser.tabs.insertAfterCurrent", false);
        pref("browser.tabs.insertRelatedAfterCurrent", true);
        pref("browser.toolbars.bookmarks.visibility", "newtab");
        pref("browser.translations.neverTranslateLanguages", "fr");
        pref("dom.text_fragments.create_text_fragment.enabled", true);
        pref("extensions.autoDisableScopes", 0);
        pref("extensions.install_origins.enabled", true);
        pref("general.autoScroll", true);
        pref("gfx.canvas.accelerated", true);
        pref("gfx.webrender.enabled", true);
        pref("middlemouse.paste", false);
        pref("webgl.disabled", false);

        // Privacy relaxation.
        pref("privacy.clearOnShutdown_v2.cache", false);
        pref("privacy.clearOnShutdown_v2.cookiesAndStorage", false);
        pref("privacy.clearOnShutdown_v2.historyFormDataAndDownloads", false);
        pref("privacy.clearOnShutdown_v2.siteSettings", false);
        pref("privacy.resistFingerprinting", false);
        pref("privacy.fingerprintingProtection", true);
        pref("privacy.fingerprintingProtection.overrides", "+allTargets,-CSSPrefersColorScheme,-JSDateTimeUTC");
      '';

      # Documentation about policies options can be found at `about:policies#documentation`.
      # You can also have a look here: https://github.com/mozilla/policy-templates/.
      extraPolicies = {
        Bookmarks = bookmarks;
        Cookies = {
          Allow = [
            "https://discord.com"
            "https://web.whatsapp.com/"
          ];
        };

        EnableTrackingProtection = {
          Exceptions = [
          ];
        };
      };
    };
  };
}
