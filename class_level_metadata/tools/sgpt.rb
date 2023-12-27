
# Example subclass
module AIA
  class Sgpt < Tools
    meta(
      role:     :backend,
      name:     'sgpt',
      url:      'http://example.com/sgpt',
      desc:     'creates and runs bash scripts',
      install:  'brew install shell-gpt',
      info:     'stuff about sgpt',
    )
  end
end
