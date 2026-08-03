let
  jbakcoleman = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBUtgnZpMxBlYXM4lCy7NO5VFzWKa7umzxuab1b+M0O jbakcoleman@gmail.com";
in
{
  "secrets/openalex.env.age".publicKeys = [ jbakcoleman ];
  "secrets/tie-verify.env.age".publicKeys = [ jbakcoleman ];
}
