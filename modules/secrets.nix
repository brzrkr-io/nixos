# sops-nix groundwork. Secrets live encrypted in secrets/secrets.yaml
# (committed); decryption at activation uses the host SSH ed25519 key
# (sops-nix converts it with ssh-to-age). Editing uses the user age key at
# ~/.config/sops/age/keys.txt — see .sops.yaml for both recipients.
{ username, ... }:

{
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    # Matches the sops-nix default (ed25519 host key); explicit as documentation
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # Proves the pipeline end-to-end: surfaces at /run/secrets/placeholder,
    # user-readable so verification needs no sudo. Delete once a real secret exists.
    secrets.placeholder.owner = username;
  };
}
