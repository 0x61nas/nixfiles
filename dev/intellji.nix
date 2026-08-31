{ nix-jetbrains-plugins, pkgs, ... }: {
  home.packages = [
    (nix-jetbrains-plugins.lib.buildIdeWithPlugins pkgs "idea" [
      "com.intellij.plugins.watcher" # File Watchers
      "com.github.lonre.gruvbox-intellij-theme"
      "zielu.gittoolbox" # Git Tool Box
      "io.github.salatmaster.direnv" # Direnv Everywhere
      "com.chuntung.plugin.hidetrial" # Hide Trial
      "com.intellij.spring.debugger" # Spring Debugger
      "com.jetbrains.kmm" # Kotlin Multiplatform
      "org.jetbrains.android" # Kotlin Multiplatform dependency
      "com.anas.intellij.plugins.ayah" # Ayah
      "org.jetbrains.completion.full.line" # Full Line Code Completion
      "com.haulmont.jpab" # JPA Buddy
      "Lombook Plugin"
      "Docker"
    ])
  ];
}
