pkg_name=omnibus
pkg_origin=kevinreedy
pkg_version=$(grep VERSION $PLAN_CONTEXT/../lib/omnibus/version.rb | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
pkg_deps=(
  core/ruby
  core/bundler
  core/libyajl2
  core/busybox-static
  core/make
  core/gcc
  core/git
  core/coreutils
)
pkg_bin_dirs=(bin)

do_prepare() {
  export GEM_HOME=${pkg_prefix}/vendor/bundle/ruby/2.4.0
  export GEM_PATH=${GEM_HOME}:$(pkg_path_for bundler)
}

do_build() {
  bundle install --path ${pkg_prefix}/vendor/bundle
}

do_install() {
  build_line "Copying bin and lib to '${pkg_prefix}/'"
  cp -R bin "${pkg_prefix}/"
  cp -R lib "${pkg_prefix}/"

  for binstub in ${pkg_prefix}/bin/*; do
    wrap_ruby_bin "$binstub"
  done
}

wrap_ruby_bin() {
  local bin="$1"
  build_line "Setting shebang for ${bin} to '$(pkg_path_for ruby)/bin/ruby'"
  [[ -f $binstub ]] && sed -e "s#/usr/bin/env ruby#$(pkg_path_for ruby)/bin/ruby#" -i "$binstub"

  build_line "Adding wrapper $bin to ${bin}.real"
  mv -v "$bin" "${bin}.real"
  cat <<EOF > "$bin"
#!$(pkg_path_for busybox-static)/bin/sh
set -e
if test -n "$DEBUG"; then set -x; fi
export GEM_HOME="$GEM_HOME"
export GEM_PATH="$GEM_PATH"
unset RUBYOPT GEMRC
exec $(pkg_path_for ruby)/bin/ruby ${bin}.real \$@
EOF
  chmod -v 755 "$bin"
}
