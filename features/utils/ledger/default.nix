{
  pkgs,
  config,
  lib,
  ...
}:
{
  programs.ledger.enable = true;
  programs.ledger.package = pkgs.ledger;
  programs.ledger.settings = {
    date-format = "%Y-%m-%d";
    sort = "date";
  };
}
