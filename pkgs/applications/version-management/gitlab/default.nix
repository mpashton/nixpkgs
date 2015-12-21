{ stdenv, lib, bundler, fetchFromGitLab, bundlerEnv, defaultGemConfig, libiconv, ruby
, tzdata, git, nodejs, procps
}:

let
  env = bundlerEnv {
    name = "gitlab";
    inherit ruby;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
    meta = with lib; {
      homepage = http://www.gitlab.com/;
      platforms = platforms.linux;
      maintainers = [ ];
      license = licenses.mit;
    };
  };

in

stdenv.mkDerivation rec {
  name = "gitlab-${version}";
  version = "8.2.3";
  buildInputs = [ ruby bundler tzdata git nodejs procps ];
  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "gitlab-ce";
    rev = "v${version}";
    #url = "https://gitlab.com/gitlab-org/gitlab-ce/repository/archive.tar.gz?ref=${version}";
    sha256 = "04r3w8nz74wp3fzjviq35wb9cbii39f02l5g2pmk8l7gskzjhqcv";
  };

  patches = [
    ./remove-hardcoded-locations.patch
    ./disable-dump-schema-after-migration.patch
  ];
  postPatch = ''
    # For reasons I don't understand "bundle exec" ignores the
    # RAILS_ENV causing tests to be executed that fail because we're
    # not installing development and test gems above. Deleting the
    # tests works though.:
    rm lib/tasks/test.rake

    mv config/gitlab.yml.example config/gitlab.yml
    rm config/initializers/gitlab_shell_secret_token.rb

    substituteInPlace app/controllers/admin/background_jobs_controller.rb \
        --replace "ps -U" "${procps}/bin/ps -U"

    # required for some gems:
    cat > config/database.yml <<EOF
      production:
        adapter: postgresql
        database: gitlab
        host: <%= ENV["GITLAB_DATABASE_HOST"] || "127.0.0.1" %>
        password: <%= ENV["GITLAB_DATABASE_PASSWORD"] || "blerg" %>
        username: gitlab
        encoding: utf8
    EOF
  '';
  buildPhase = ''
    export GEM_HOME=${env}/${ruby.gemPath}
    bundle exec rake assets:precompile RAILS_ENV=production
  '';
  installPhase = ''
    mkdir -p $out/share
    cp -r . $out/share/gitlab
  '';
  passthru = {
    inherit env;
    inherit ruby;
  };
}
