{ config, lib, pkgs, ... }:

with lib;

let

  name = "mpdscribble";

  cfg = config.services.mpdscribble;

  toIni = generators.toINI {
    mkKeyValue = key: value:
      let
        value' =
          if isBool value then (if value then "True" else "False")
          else toString value;
      in
        "${key} = ${value'}";
  };

  mpdscribbleConf = {
    mpdscribble = {
      host = cfg.mpd.host;
      port = cfg.mpd.port;
      log = cfg.logs.path;
      verbose = cfg.logs.verbosity;
      proxy = cfg.proxy;
    };
  };

in

{
  meta.maintainers = [ maintainers.aheaume ];

  ###### interface

  options.services.mpdscribble = {
    enable = mkEnableOption "mpdscribble is a MPD client which submits information about tracks being played to online services.";

    package = mkOption {
      type = types.package;
      default = pkgs.mpdscribble;
      defaultText = "pkgs.mpdscribble";
      description = "The mpdscribble package to use.";
    };

    proxy = mkOption {
      type = types.nullOr types.str;
      default = null;
      defaultText = "TODO";
      description = "TODO";
    };

    logs = {
      path = mkOption {
        type = types.path;
        default = "${config.xdg.configHome}/mpdscribble/mpdscribble.log"; # TODO is config the right place?
        defaultText = "~/.config/mpdscribble/mpdscribble.log";
        description = "TODO";
      };
      verbosity = mkOption {
        type = types.ints.positive;
        default = 2;
        defaultText = "2";
        description = "TODO";
      };
    };

    mpd = {
      host = mkOption {
        type = types.str;
        default = config.services.mpd.network.listenAddress;
        defaultText = "config.services.mpd.network.listenAddress";
        example = "192.168.1.1";
        description = "The address where MPD is listening for connections.";
      };
      port = mkOption {
        type = types.ints.positive;
        default = config.services.mpd.network.port;
        defaultText = "config.services.mpd.network.port";
        description = "The port number where MPD is listening for connections.";
      };
    };

    services = mkOption {
      type = types.attrs; # TODO should it be a submodule?
      default = {};
      defaultText = "{}";
      description = "TODO";
    };
  };

  ###### implementation

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.services.mpd.enable;
        message = "The mpdscribble module requires 'services.mpd.enable = true'.";
      }
    ];

  xdg.configFile."mpdscribble/mpdscribble.conf".text = toIni (mpdscribbleConf // cfg.services);

    systemd.user.services.mpdscribble = {
      Unit = {
        Description = "Scrobbling support for MPD via MPDScribble";
        After = [ "graphical-session-pre.target" "mpd.service" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        # TODO don't hardcode path
        ExecStart = "${cfg.package}/bin/mpdscribble --conf=/home/aheaume/.config/mpdscribble/mpdscribble.conf";
      };
    };
  };
}
