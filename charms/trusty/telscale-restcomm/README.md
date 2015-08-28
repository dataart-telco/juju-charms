

    juju bootstrap
    juju deploy mobicents restcomm
    juju deploy mobicents mediaserver

    juju add-relation restcomm:restcomm mediaserver:mediaserver


# TODO

- config's not getting written correctly to bind to external address...

- rewrite these with helpers

- use templates across the board instead of sed

- move builds to config or even install
  optional or not?

- just do installs and config at relation-time so they finish faster



