{
  description = "Среда сборки Android-клиента qWDTT";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
      androidSdk = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "35" ];
        buildToolsVersions = [ "36.0.0" ];
        includeNDK = true;
        ndkVersions = [ "28.0.13004108" ];
      };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          androidSdk.androidsdk
          pkgs.go
          pkgs.jdk17
        ];
        ANDROID_HOME = "${androidSdk.androidsdk}/libexec/android-sdk";
        ANDROID_SDK_ROOT = "${androidSdk.androidsdk}/libexec/android-sdk";
        ANDROID_NDK_HOME = "${androidSdk.androidsdk}/libexec/android-sdk/ndk-bundle";
        GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk.androidsdk}/libexec/android-sdk/build-tools/36.0.0/aapt2";
        JAVA_HOME = "${pkgs.jdk17}";
      };
    };
}
