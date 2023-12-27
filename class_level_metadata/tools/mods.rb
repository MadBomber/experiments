
# Example subclass
module AIA
  class Mods < Tools
    meta(
      role:     :backend,
      name:     'mods',
      url:      'http://example.com/mods',
      desc:     'creates and runs bash scripts',
      install:  'brew install mods',
      info:     'stuff about mods',
    )
  end
end
