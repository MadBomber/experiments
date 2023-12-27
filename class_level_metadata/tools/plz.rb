
# Example subclass
module AIA
  class Plz < Tools
    meta(
      role:     :backend,
      name:     'plz',
      url:      'http://example.com/plz',
      desc:     'creates and runs bash scripts',
      install:  'brew install plz',
      info:     'stuff about plz',
    )
  end
end
