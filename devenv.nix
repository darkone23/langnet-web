{ pkgs, lib, config, inputs, ... }:

let
  # This is the 'worker'. It's a real file on disk.
  # Zellij needs this to be an executable binary it can point to.
  zshell = pkgs.writeShellScriptBin "zshell" ''
    set -e
    # Use 'exec' so this script replaces itself with devenv,
    # ensuring 'exit' closes the Zellij pane immediately.
    echo "[initializing zellij-devenv...]"
    exec ${pkgs.devenv}/bin/devenv shell --quiet
  '';
in
{
  # https://devenv.sh/basics/
  env.SESSION_NAME = "langnet-web";
  env.GIT_EXTERNAL_DIFF = "${pkgs.difftastic}/bin/difft";

  env.UV_PROJECT = "${config.devenv.root}/backend";
  env.UV_PROJECT_ENVIRONMENT = "${config.devenv.root}/.devenv/state/venv";

  # https://devenv.sh/packages/
  packages = [
    zshell
    # general dev tools
    pkgs.git 
    pkgs.difftastic
    pkgs.opencode
    pkgs.zellij
    pkgs.starship

    # data tools
    pkgs.nushell
    pkgs.duckdb

    # python dev tools
    # pkgs.python3Packages.python-lsp-server
    # pkgs.python3Packages.jedi-language-server
    # pkgs.python3Packages.ruff
    # pkgs.ty

  ];

  # https://devenv.sh/languages/
  # languages.python.enable = true;
  # languages.python.uv.enable = true;
  # languages.python.uv.sync.enable = true;
  # languages.python.directory = "backend";
  languages.zig.enable = true;
  # languages.python.venv.enable = true;
  # languages.python.lsp.enable = false; # manually installed via pkgs above
  languages.javascript.enable = true;
  languages.javascript.bun.enable = true;
  languages.javascript.bun.install.enable = true;
  languages.javascript.directory = "frontend";
  languages.javascript.lsp.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.zell.exec = ''
    #!/usr/bin/env bash

    # 1. CLEANUP: If the session exists but is "EXITED", delete it.
    # This clears the "memory" of the 2-pane layout and avoids the "session exists" error.
    if zellij list-sessions --no-formatting 2>/dev/null | grep "^$SESSION_NAME" | grep -q "EXITED"; then
        echo "Resurrecting $SESSION_NAME from a clean state..."
        zellij delete-session "$SESSION_NAME"
    fi

    # 2. PROMPT FIX: Neutralize the "Crazy Brackets" 
    # We unset the devenv-injected prompt commands so Starship/Zellij can take over cleanly.
    unset PROMPT_COMMAND
    export PS1="\$ " # Set a minimal prompt; your shell init (Starship) will override this correctly inside Zellij.

    # 3. LAUNCH: Create or Attach with the 'compact' layout
    # --layout compact: Removes the status bar pane at the bottom.
    zellij options \
      --show-startup-tips false \
      --show-release-notes false \
      --default-shell zshell \
      --attach-to-session true \
      --session-name "$SESSION_NAME"
  '';

  enterShell = ''
    # hello
    unset PS1
    eval $(starship init bash)
    source $DEVENV_STATE/venv/bin/activate
    export VIRTUAL_ENV_PROMPT="$SESSION_NAME"
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
    
    # Test Python dependencies
    python -c "import click, sh, rich, json; print('Python imports successful')"
    
    # git --version
    echo "Python path: $(which python)"
    echo "UV path: $(which uv)"
    echo "Bun path: $(which bun)"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
