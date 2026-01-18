{ config, ... }: {
  sops = {
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      discord_webhook_url = {
      };
    };
  };
}
